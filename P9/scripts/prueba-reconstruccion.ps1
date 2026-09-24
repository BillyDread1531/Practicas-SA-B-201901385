<#
.SYNOPSIS
  Prueba de recuperacion cronometrada (DESTRUYE y RECONSTRUYE el cluster completo).

.DESCRIPTION
  Escenario ejecutado, en este orden:
    A. Datos de control: se insertan 5 estudiantes (DR-0001..DR-0005) y se lanza un
       respaldo de Velero al Blob persistente; despues se inserta DR-POST (dato que se
       perdera: define el RPO).
    B. DESASTRE: terraform destroy del stack del cluster (AKS, ArgoCD, Velero, llaves
       en el cluster, resource group rg-sa-p9, discos y balanceador). La capa persistente
       (Blob de respaldos, Key Vault, estado de Terraform) NO se toca.
    C. RECUPERACION: scripts/bootstrap.ps1 (punto de entrada unico, sin pasos manuales).
    D. Verificacion de contenido y calculo del RTO/RPO reales.

  RTO real = desde que el desastre queda consumado (destroy terminado: el cluster ya
  no existe) hasta que el servicio responde CON los datos verificados.
  Escribe P9/evidencias/reconstruccion-cronometrada.md.
#>
param(
    [string]$Schedule = 'velero-p9-platform',
    [string]$EvidenceFile = (Join-Path $PSScriptRoot '..\evidencias\reconstruccion-cronometrada.md'),
    [int]$RtoObjetivoMin = 60,
    [int]$RpoObjetivoHoras = 6
)
. "$PSScriptRoot\common.ps1"
$p9 = Split-Path $PSScriptRoot -Parent
$tf = Join-Path $p9 'terraform'
$script:LogFile = Join-Path ([IO.Path]::GetTempPath()) ("p9-reconstruccion-{0}.log" -f (Get-Date -Format 'yyyyMMddHHmmss'))
Set-Content -Path $script:LogFile -Value '' -Encoding UTF8
function Ts([string]$pattern) {
    $l = Get-Content $script:LogFile | Where-Object { $_ -match $pattern } | Select-Object -First 1
    if ($l) { ($l -split ' \| ')[0] } else { 'n/d' }
}

Mark 'DR: INICIO de la prueba de recuperacion'

# --- A. Datos de control + respaldo --------------------------------------------------------------------
Invoke-Sql "delete from estudiantes where carnet like 'DR-%'" | Out-Null
$values = (1..5 | ForEach-Object { "('DR','Control$_','dr$_@p9.test','DR-000$_')" }) -join ','
Invoke-Sql "insert into estudiantes(nombre,apellido,email,carnet) values $values" | Out-Null
$seeded = Invoke-Sql "select carnet||' '||email from estudiantes where carnet like 'DR-%' order by carnet"
$tablesBefore = Invoke-Sql "select relname||'='||n_live_tup from pg_stat_user_tables order by relname"
Mark 'DR: 5 estudiantes de control insertados'

$backupName = 'p9-dr-' + (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
$tpl = (Get-Kube -n velero get schedule $Schedule -o json | ConvertFrom-Json).spec.template
$backup = [ordered]@{
    apiVersion = 'velero.io/v1'; kind = 'Backup'
    metadata   = [ordered]@{ name = $backupName; namespace = 'velero'; labels = @{ 'velero.io/schedule-name' = $Schedule } }
    spec       = $tpl
}
(ConvertTo-Json -InputObject $backup -Depth 20) | & kubectl apply -f - | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el Backup' }
Wait-Until -What "backup $backupName" -TimeoutSeconds 900 -IntervalSeconds 5 -Condition {
    (Get-Kube -n velero get backup $backupName -o jsonpath='{.status.phase}') -in @('Completed', 'PartiallyFailed', 'Failed')
}
$bk = Get-Kube -n velero get backup $backupName -o json | ConvertFrom-Json
if ($bk.status.phase -ne 'Completed') { throw "Backup termino en $($bk.status.phase)" }
Mark "DR: respaldo $backupName Completed (inicio $($bk.status.startTimestamp), fin $($bk.status.completionTimestamp), items $($bk.status.progress.itemsBackedUp))"

# Verificar que el respaldo realmente esta en el Blob persistente (fuera del cluster)
$sa  = 'stp9velero201901385'
$key = az storage account keys list --account-name $sa --resource-group rg-sa-p9-backend --query '[0].value' -o tsv
$blobs = az storage blob list --account-name $sa --account-key $key --container-name velero --prefix "backups/$backupName/" --query '[].name' -o tsv
$kopiaCount = @(az storage blob list --account-name $sa --account-key $key --container-name velero --prefix 'kopia/' --query '[].name' -o tsv).Count
Mark "DR: respaldo verificado en Azure Blob $sa/velero (backups/$backupName/: $(@($blobs).Count) objetos; repositorio kopia: $kopiaCount objetos)"

Invoke-Sql "insert into estudiantes(nombre,apellido,email,carnet) values ('DR','PostRespaldo','dr-post@p9.test','DR-POST')" | Out-Null
$tPost = Get-Stamp
Mark 'DR: DR-POST insertado DESPUES del respaldo (se espera perderlo)'

# --- B. Desastre -----------------------------------------------------------------------------------------------
Mark 'DR: DESTRUCCION iniciada (terraform destroy del stack del cluster)'
Invoke-Native terraform "-chdir=$tf" destroy -auto-approve -input=false
$exists = az group exists --name rg-sa-p9
$persist = az group exists --name rg-sa-p9-backend
Mark "DR: DESTRUCCION terminada - rg-sa-p9 existe=$exists (cluster perdido); rg-sa-p9-backend existe=$persist (capa persistente intacta)"
if ($exists -ne 'false') { throw 'El resource group del cluster sigue existiendo' }

# --- C. Recuperacion (punto de entrada unico) ---------------------------------------------------------------
Mark 'DR: RECUPERACION iniciada -> scripts/bootstrap.ps1'
$bootError = $null
try { & "$PSScriptRoot\bootstrap.ps1" -LogFile $script:LogFile } catch { $bootError = $_; Mark "DR: bootstrap.ps1 FALLO - $($_.Exception.Message)" }
Mark 'DR: bootstrap.ps1 terminado'

# --- D. Verificacion de datos y calculo de RTO/RPO ---------------------------------------------------------------
$restored = Invoke-Sql "select carnet||' '||email from estudiantes order by carnet"
$postExists = Invoke-Sql "select count(*) from estudiantes where carnet='DR-POST'"
$tablesAfter = Invoke-Sql "select relname||'='||n_live_tup from pg_stat_user_tables order by relname"
$ok = ($restored -eq $seeded) -and ($postExists -eq '0')
Mark ("DR: DATOS VERIFICADOS - contenido {0} los 5 registros de control; DR-POST {1}" -f ($(if ($restored -eq $seeded) { 'COINCIDE con' } else { 'NO coincide con' })), ($(if ($postExists -eq '0') { 'no recuperado (esperado)' } else { 'recuperado' })))

function P([string]$s) { [datetime]::Parse($s).ToUniversalTime() }
$tDestroyStart = Ts 'DESTRUCCION iniciada'
$tDestroyEnd   = Ts 'DESTRUCCION terminada'
$tBoot         = Ts 'RECUPERACION iniciada'
$tApplyStart   = Ts 'terraform apply \(AKS'
$tApplyEnd     = Ts 'terraform apply COMPLETO'
$tAks          = Ts 'AKS disponible'
$tArgo         = Ts 'ArgoCD disponible'
$tSealed       = Ts 'SealedSecret sa-platform-secrets DESCIFRADO'
$tApps         = Ts 'todas las aplicaciones del app-of-apps'
$tRoot         = Ts 'p9-root-app Healthy'
$tRestoreS     = Ts 'restore-datos: buscando respaldo'
$tRestoreE     = Ts 'restore-datos: FIN'
$tSvc          = Ts 'verificar: PASS  Servicio publico'
$tVerified     = Ts 'DATOS VERIFICADOS'
$rtoSec  = [int]((P $tVerified) - (P $tDestroyEnd)).TotalSeconds
$rtoBoot = [int]((P $tVerified) - (P $tBoot)).TotalSeconds
$rpoSec  = [int]((P $tDestroyStart) - (P $bk.status.startTimestamp)).TotalSeconds
$fmt = { param($s) "{0} min {1:00} s" -f [math]::Floor($s / 60), ($s % 60) }
$cumple = if ($rtoSec -le ($RtoObjetivoMin * 60)) { 'CUMPLE' } else { 'NO CUMPLE' }
Mark "DR: RTO real = $(& $fmt $rtoSec) (objetivo $RtoObjetivoMin min -> $cumple); RPO real = $(& $fmt $rpoSec) (objetivo $RpoObjetivoHoras h)"

$log = Get-Content $script:LogFile -Raw
$md = @"
# Reconstruccion cronometrada (destruccion total + bootstrap desde cero)

Generada por ``P9/scripts/prueba-reconstruccion.ps1``. Horas en UTC (ISO 8601). Las marcas se copian
literalmente del registro que produjeron los scripts (seccion final), no se estiman.

## Marcas de tiempo

| Marca | Hora (UTC) | Comando o evidencia |
|---|---|---|
| Respaldo previo completado | $($bk.status.completionTimestamp) | ``Backup $backupName`` -> Azure Blob ``stp9velero201901385/velero`` |
| Destruccion iniciada | $tDestroyStart | ``terraform destroy -auto-approve`` (stack P9/terraform) |
| Destruccion terminada (desastre consumado, **T0**) | $tDestroyEnd | ``az group exists rg-sa-p9`` = false |
| Bootstrap lanzado | $tBoot | ``P9/scripts/bootstrap.ps1`` |
| Terraform apply iniciado | $tApplyStart | estado remoto azurerm + bloqueo |
| Terraform apply completo (AKS + ArgoCD + llaves + Velero + app raiz) | $tApplyEnd | |
| AKS disponible | $tAks | nodos Ready |
| ArgoCD disponible | $tArgo | ``argocd-server`` Ready |
| SealedSecret descifrado (continuidad de secretos) | $tSealed | llave restaurada desde Key Vault |
| Aplicaciones del app-of-apps sincronizadas | $tApps | sealed-secrets, argo-rollouts, kyverno, p8-kyverno-policies, sa-platform-dev |
| ``p9-root-app`` Healthy | $tRoot | |
| Restauracion de datos: inicio -> fin | $tRestoreS -> $tRestoreE | Restore de Velero + PodVolumeRestore |
| Servicio responde | $tSvc | ``GET /health`` por la IP publica del gateway |
| Datos verificados (**T1**) | $tVerified | SELECT sobre el PVC restaurado |

## Resultado

| Indicador | Objetivo declarado | Medido | Veredicto |
|---|---|---|---|
| **RTO** (T1 - T0) | $RtoObjetivoMin min | **$(& $fmt $rtoSec)** ($rtoSec s) | $cumple |
| Duracion del bootstrap (T1 - bootstrap lanzado) | - | $(& $fmt $rtoBoot) | - |
| **RPO** (inicio de la destruccion - inicio del respaldo) | $RpoObjetivoHoras h | **$(& $fmt $rpoSec)** en esta prueba | ver nota |
| Datos no recuperados | - | 1 estudiante (``DR-POST``, insertado a las $tPost, despues del respaldo) | esperado |

Nota sobre el RPO: aqui el respaldo se lanzo minutos antes del desastre, por lo que el valor medido es pequeno.
El RPO **garantizado** por el diseno es el intervalo del schedule (cada 6 h) mas la duracion del respaldo: el
peor caso real es ~6 h. Lo medido demuestra el mecanismo (el dato posterior al respaldo se pierde, el anterior
se recupera); no reemplaza al objetivo.

## Contenido verificado tras la reconstruccion

Antes del desastre (estudiantes de control):

``````
$seeded
``````

Despues de reconstruir y restaurar (SELECT real):

``````
$restored
``````

Filas vivas por tabla ANTES del desastre / DESPUES de la recuperacion:

``````
$tablesBefore
--- despues ---
$tablesAfter
``````

## Registro completo con marcas de tiempo

``````
$log
``````
"@
Set-Content -Path $EvidenceFile -Value $md -Encoding UTF8
Mark "DR: evidencia escrita en $EvidenceFile"
if ($bootError) { throw $bootError }
if (-not $ok) { throw 'La verificacion de contenido tras la reconstruccion fallo' }
