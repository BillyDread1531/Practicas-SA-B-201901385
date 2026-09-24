<#
.SYNOPSIS
  Prueba de restauracion de datos con evidencia automatica (rubrica 2.3 / 2.6).

.DESCRIPTION
  1. Inserta 5 estudiantes de control en PostgreSQL (tabla estudiantes).
  2. Lanza un respaldo de Velero (mismo template del schedule) y espera a que termine.
  3. Inserta 1 estudiante DESPUES del respaldo (dato que se espera perder: define el RPO).
  4. Simula el desastre: borra todos los estudiantes.
  5. Ejecuta restore-datos.ps1 (restauracion real desde Azure Blob).
  6. Verifica el CONTENIDO restaurado fila por fila y calcula el RPO real.
  7. Escribe la evidencia en P9/evidencias/restauracion-datos.md.

  Sale con codigo distinto de 0 si el contenido restaurado no coincide.
#>
param(
    [string]$Schedule = 'velero-p9-platform',
    [string]$EvidenceFile = (Join-Path $PSScriptRoot '..\evidencias\restauracion-datos.md')
)
. "$PSScriptRoot\common.ps1"
$script:LogFile = Join-Path ([IO.Path]::GetTempPath()) ("p9-restauracion-{0}.log" -f (Get-Date -Format 'yyyyMMddHHmmss'))
Set-Content -Path $script:LogFile -Value '' -Encoding UTF8

$ns = 'sa-p8'
$control = 1..5 | ForEach-Object { "DR-000$_" }

Mark 'prueba-datos: estado inicial'
$before = Invoke-Sql 'select count(*) from estudiantes'
Mark "prueba-datos: estudiantes antes de la prueba = $before"

# 1. Datos de control -------------------------------------------------------------
Invoke-Sql "delete from estudiantes where carnet like 'DR-%'" | Out-Null
$values = (1..5 | ForEach-Object { "('DR','Control$_','dr$_@p9.test','DR-000$_')" }) -join ','
Invoke-Sql "insert into estudiantes(nombre,apellido,email,carnet) values $values" | Out-Null
$seeded = Invoke-Sql "select carnet||' '||email from estudiantes where carnet like 'DR-%' order by carnet"
Mark 'prueba-datos: 5 estudiantes de control insertados'

# 2. Respaldo --------------------------------------------------------------------
$backupName = 'p9-datos-prueba-' + (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
$tpl = (Get-Kube -n velero get schedule $Schedule -o json | ConvertFrom-Json).spec.template
$backup = [ordered]@{
    apiVersion = 'velero.io/v1'; kind = 'Backup'
    metadata   = [ordered]@{ name = $backupName; namespace = 'velero'; labels = @{ 'velero.io/schedule-name' = $Schedule } }
    spec       = $tpl
}
$json = ConvertTo-Json -InputObject $backup -Depth 20
$json | & kubectl apply -f - | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el Backup' }
Mark "prueba-datos: respaldo $backupName lanzado (template del schedule $Schedule)"
Wait-Until -What "backup $backupName" -TimeoutSeconds 900 -IntervalSeconds 5 -Condition {
    (Get-Kube -n velero get backup $backupName -o jsonpath='{.status.phase}') -in @('Completed', 'PartiallyFailed', 'Failed')
}
$bk = Get-Kube -n velero get backup $backupName -o json | ConvertFrom-Json
if ($bk.status.phase -ne 'Completed') { throw "Backup termino en $($bk.status.phase)" }
$pvb = @((Get-Kube -n velero get podvolumebackup -l "velero.io/backup-name=$backupName" -o json | ConvertFrom-Json).items |
    Where-Object { $_.spec.pod.name -in @('postgresql-0', 'rabbitmq-0') -and $_.spec.volume -eq 'data' })
Mark ("prueba-datos: respaldo Completed | inicio {0} | fin {1} | items {2}/{3} | PVB de datos: {4}" -f `
    $bk.status.startTimestamp, $bk.status.completionTimestamp, $bk.status.progress.itemsBackedUp, $bk.status.progress.totalItems,
    (($pvb | ForEach-Object { "$($_.spec.pod.name)=$($_.status.phase)($([math]::Round($_.status.progress.totalBytes/1MB,1)) MiB)" }) -join ', '))

# 3. Dato posterior al respaldo -------------------------------------------------
Invoke-Sql "insert into estudiantes(nombre,apellido,email,carnet) values ('DR','PostRespaldo','dr-post@p9.test','DR-POST')" | Out-Null
$tPost = Get-Stamp
Mark 'prueba-datos: estudiante DR-POST insertado DESPUES del respaldo'

# 4. Desastre ----------------------------------------------------------------------
Invoke-Sql 'delete from estudiantes' | Out-Null
$tDisaster = Get-Stamp
$afterDelete = Invoke-Sql 'select count(*) from estudiantes'
Mark "prueba-datos: DESASTRE - estudiantes borrados (count = $afterDelete)"

# 5. Restauracion --------------------------------------------------------------------
$tRestoreStart = Get-Stamp
& "$PSScriptRoot\restore-datos.ps1" -BackupName $backupName -Schedule $Schedule -LogFile $script:LogFile
$tRestoreEnd = Get-Stamp

# 6. Verificacion de contenido -------------------------------------------------------
Wait-Until -What 'PostgreSQL acepta consultas' -TimeoutSeconds 120 -IntervalSeconds 5 -Condition { (Invoke-Sql 'select 1') -eq '1' }
$restored = Invoke-Sql "select carnet||' '||email from estudiantes order by carnet"
$postExists = Invoke-Sql "select count(*) from estudiantes where carnet='DR-POST'"
$tables = Invoke-Sql "select relname||'='||n_live_tup from pg_stat_user_tables order by relname"
$ok = ($restored -eq $seeded) -and ($postExists -eq '0')
Mark ("prueba-datos: contenido restaurado {0} los 5 registros de control; DR-POST {1}" -f ($(if ($restored -eq $seeded) { 'COINCIDE con' } else { 'NO coincide con' })), ($(if ($postExists -eq '0') { 'no recuperado (esperado)' } else { 'recuperado (inesperado)' })))

# 7. RPO real ------------------------------------------------------------------------
$tStart = [datetime]::Parse($bk.status.startTimestamp).ToUniversalTime()
$tDis   = [datetime]::Parse($tDisaster).ToUniversalTime()
$rpoSec = [int]($tDis - $tStart).TotalSeconds
$rtoSec = [int](([datetime]::Parse($tRestoreEnd)) - ([datetime]::Parse($tRestoreStart))).TotalSeconds
Mark "prueba-datos: RPO real (desastre - inicio del respaldo) = $rpoSec s | duracion de la restauracion = $rtoSec s"

$log = Get-Content $script:LogFile -Raw
$md = @"
# Restauracion de datos - evidencia automatica

Generada por ``P9/scripts/prueba-restauracion-datos.ps1`` (cluster ``aks-sa-p9``, namespace ``$ns``).
Todas las horas son UTC. El script termina con error si el contenido restaurado no coincide.

| Campo | Valor |
|---|---|
| Backup usado | ``$backupName`` (template del schedule ``$Schedule``) |
| Destino del respaldo | Azure Blob ``stp9velero201901385/velero`` (fuera del cluster) |
| Inicio / fin del respaldo | $($bk.status.startTimestamp) / $($bk.status.completionTimestamp) |
| Volumenes respaldados (Kopia) | $(($pvb | ForEach-Object { "$($_.spec.pod.name)/data = $($_.status.phase)" }) -join '; ') |
| Dato de control creado | 5 estudiantes ``DR-0001``..``DR-0005`` (antes del respaldo) |
| Dato posterior al respaldo | ``DR-POST`` insertado a las $tPost |
| Hora de eliminacion (desastre) | $tDisaster (``DELETE FROM estudiantes`` -> count = $afterDelete) |
| Restore ejecutado | $tRestoreStart -> $tRestoreEnd ($rtoSec s) |
| Contenido verificado | $(if ($restored -eq $seeded) { 'SI: las 5 filas (carnet + email) coinciden exactamente' } else { 'NO' }) |
| Dato posterior al respaldo | $(if ($postExists -eq '0') { 'NO recuperado (esperado, es el RPO)' } else { 'recuperado' }) |
| **RPO real** | **$rpoSec s** entre el inicio del respaldo y el desastre; se perdio 1 registro (``DR-POST``) |

## Contenido antes del desastre (tabla estudiantes, filas de control)

``````
$seeded
``````

## Contenido tras la restauracion (SELECT real sobre el PVC restaurado)

``````
$restored
``````

Filas vivas por tabla tras restaurar (pg_stat_user_tables):

``````
$tables
``````

## Registro con marcas de tiempo

``````
$log
``````

## Nota tecnica sobre el fallo de la primera version de la prueba

El primer intento de esta prueba (2026-09-23) dejaba los PVC restaurados vacios y se
documento como "limitacion de Velero". La causa real era otra: la politica Kyverno
``p8-require-non-root`` rechazaba el pod restaurado porque Velero inyecta el initContainer
``restore-wait`` sin ``runAsNonRoot``; sin pod restaurado no se crea ningun PodVolumeRestore.
Se corrigio eximiendo unicamente ese initContainer (``P8/security/kyverno/03-require-non-root.yaml``)
y restaurando statefulsets + pods + PVC (no solo PVC).
"@
Set-Content -Path $EvidenceFile -Value $md -Encoding UTF8
Mark "prueba-datos: evidencia escrita en $EvidenceFile"
if (-not $ok) { throw 'La verificacion de contenido fallo' }
