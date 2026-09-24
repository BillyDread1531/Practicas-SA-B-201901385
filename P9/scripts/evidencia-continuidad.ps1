<#
.SYNOPSIS
  Genera la evidencia de Velero (rubrica 2.3) y de continuidad de secretos (rubrica 2.4)
  a partir del estado REAL del cluster reconstruido. No imprime llaves ni contrasenas.

  Escribe:
    P9/evidencias/respaldo-velero.md
    P9/evidencias/continuidad-secretos.md
#>
param(
    [string]$VaultName = 'kv-p9-201901385',
    [string]$SecretName = 'sealed-secrets-keys',
    [string]$OutDir = (Join-Path $PSScriptRoot '..\evidencias')
)
. "$PSScriptRoot\common.ps1"

function Get-Sha256Hex([byte[]]$bytes) {
    $h = [Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    (($h | ForEach-Object { $_.ToString('x2') }) -join '')
}

# ============================ Velero ============================================================
$sch = Get-Kube -n velero get schedule velero-p9-platform -o json | ConvertFrom-Json
$bsl = Get-Kube -n velero get backupstoragelocation default -o json | ConvertFrom-Json
$bks = @((Get-Kube -n velero get backup -o json | ConvertFrom-Json).items | Sort-Object { $_.status.startTimestamp })
$rows = ($bks | ForEach-Object {
    "| ``$($_.metadata.name)`` | $($_.status.phase) | $($_.status.startTimestamp) | $($_.status.completionTimestamp) | $($_.status.expiration) | $($_.status.progress.itemsBackedUp) |"
}) -join "`n"
$last = ($bks | Where-Object { $_.status.phase -eq 'Completed' } | Select-Object -Last 1)
$pvb = @((Get-Kube -n velero get podvolumebackup -l "velero.io/backup-name=$($last.metadata.name)" -o json | ConvertFrom-Json).items |
    Where-Object { $_.spec.volume -eq 'data' })
$pvbRows = ($pvb | ForEach-Object { "| ``$($_.spec.pod.namespace)/$($_.spec.pod.name)`` | ``$($_.spec.volume)`` | $($_.status.phase) | $([math]::Round($_.status.progress.totalBytes/1MB,1)) MiB | $($_.spec.uploaderType) |" }) -join "`n"

$acct = $bsl.spec.config.storageAccount
$rg = 'rg-sa-p9-backend'
$key = az storage account keys list --account-name $acct --resource-group $rg --query '[0].value' -o tsv
$blobTop = az storage blob list --account-name $acct --account-key $key --container-name $bsl.spec.objectStorage.bucket --prefix 'backups/' --query "[?ends_with(name, '-logs.gz')].name" -o tsv
$blobKopia = @(az storage blob list --account-name $acct --account-key $key --container-name $bsl.spec.objectStorage.bucket --prefix 'kopia/' --query '[].name' -o tsv).Count
$acctInfo = az storage account show --name $acct --resource-group $rg --query '{rg:resourceGroup,sku:sku.name,region:location,publicAccess:allowBlobPublicAccess}' -o json | ConvertFrom-Json
$clusterRg = az aks show --name aks-sa-p9 --resource-group rg-sa-p9 --query resourceGroup -o tsv

$vel = @"
# Respaldos con Velero - evidencia (generada por scripts/evidencia-continuidad.ps1)

Estado real del cluster ``aks-sa-p9`` (reconstruido desde cero) consultado el $(Get-Stamp) UTC.

## 1. Respaldos programados con retencion (schedule)

| Campo | Valor |
|---|---|
| Schedule | ``$($sch.metadata.name)`` (namespace ``velero``) |
| Calendario | ``$($sch.spec.schedule)`` (cada 6 horas, UTC) |
| **Retencion** | ``ttl: $($sch.spec.template.ttl)`` (30 dias) |
| Alcance | namespaces ``$($sch.spec.template.includedNamespaces -join ',')``, ``includeClusterResources: $($sch.spec.template.includeClusterResources)`` |
| **Volumenes persistentes incluidos** | ``defaultVolumesToFsBackup: $($sch.spec.template.defaultVolumesToFsBackup)`` (Kopia por node-agent); ``snapshotVolumes: $($sch.spec.template.snapshotVolumes)`` |
| Estado | $(if ($sch.spec.paused) { 'PAUSADO' } else { 'Enabled' }) |
| Ultimo respaldo programado | ``$($sch.status.lastBackup)`` |

## 2. Destino EXTERNO al cluster

| Campo | Valor |
|---|---|
| BackupStorageLocation | ``$($bsl.metadata.name)`` - fase **$($bsl.status.phase)** (ultima validacion $($bsl.status.lastValidationTime)) |
| Proveedor / contenedor | ``$($bsl.spec.provider)`` / ``$($bsl.spec.objectStorage.bucket)`` |
| Cuenta de almacenamiento | ``$acct`` en el resource group ``$($acctInfo.rg)`` ($($acctInfo.region), $($acctInfo.sku), acceso publico a blobs: $($acctInfo.publicAccess)) |
| Ubicacion respecto al cluster | El cluster vive en ``$clusterRg`` (se destruye en el DR); el almacenamiento esta en ``$($acctInfo.rg)`` (capa persistente, otro resource group y otro estado de Terraform) |
| Repositorio Kopia en el Blob | $blobKopia objetos bajo ``kopia/`` |

Respaldos visibles en el Blob (``backups/<nombre>/...-logs.gz``):

``````
$($blobTop -join "`n")
``````

## 3. Respaldos existentes

Incluye los creados **antes** de destruir el cluster: Velero los sincronizo desde el Blob al cluster nuevo.

| Respaldo | Fase | Inicio | Fin | Expira | Items |
|---|---|---|---|---|---|
$rows

## 4. Volumenes persistentes dentro del ultimo respaldo (``$($last.metadata.name)``)

| Pod | Volumen | Fase | Tamano | Uploader |
|---|---|---|---|---|
$pvbRows

## 5. La restauracion se demuestra funcionando

Ver [restauracion-datos.md](restauracion-datos.md) (restauracion en el mismo cluster, con verificacion de filas) y
[reconstruccion-cronometrada.md](reconstruccion-cronometrada.md) (restauracion en un cluster reconstruido desde cero).
"@
Set-Content -Path (Join-Path $OutDir 'respaldo-velero.md') -Value $vel -Encoding UTF8
Mark 'evidencia: respaldo-velero.md escrito'

# ============================ Secretos ==========================================================
$kv = az keyvault secret show --vault-name $VaultName --name $SecretName --query value -o tsv | ConvertFrom-Json
$kvMeta = az keyvault secret show --vault-name $VaultName --name $SecretName --query '{updated:attributes.updated,id:name}' -o json | ConvertFrom-Json
$clusterKeys = @((Get-Kube -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o json | ConvertFrom-Json).items)
$cmp = foreach ($k in $kv) {
    $kvFp = Get-Sha256Hex ([Convert]::FromBase64String($k.crt))
    $cs = $clusterKeys | Where-Object { $_.metadata.name -eq $k.name }
    $clFp = if ($cs) { Get-Sha256Hex ([Convert]::FromBase64String($cs.data.'tls.crt')) } else { '(no existe en el cluster)' }
    $subj = (New-Object Security.Cryptography.X509Certificates.X509Certificate2 (,[Convert]::FromBase64String($k.crt))).NotBefore.ToString('yyyy-MM-dd')
    "| ``$($k.name)`` | $subj | ``$($kvFp.Substring(0,16))...`` | ``$($clFp.Substring(0,[math]::Min(16,$clFp.Length)))...`` | $(if ($kvFp -eq $clFp) { 'COINCIDE' } else { 'DIFIERE' }) |"
}
$ss = Get-Kube -n sa-p8 get sealedsecret sa-platform-secrets -o json | ConvertFrom-Json
$sec = Get-Kube -n sa-p8 get secret sa-platform-secrets -o json | ConvertFrom-Json
$secKeys = ($sec.data.PSObject.Properties.Name | Sort-Object) -join ', '
$ctlLog = (& kubectl -n kube-system logs deploy/sealed-secrets-controller --tail=400 2>$null | Select-String -Pattern 'key|Unsealed|unseal' -SimpleMatch:$false | Select-Object -First 12 | ForEach-Object { ($_.Line -replace '(tls\.key|private).*','$1 [...]') }) -join "`n"
$decryptErrors = @(& kubectl -n kube-system logs deploy/sealed-secrets-controller --tail=1000 2>$null | Select-String 'no key could decrypt').Count
$ctl = Get-Kube -n kube-system get deploy sealed-secrets-controller -o json | ConvertFrom-Json
$renew = ($ctl.spec.template.spec.containers[0].args -join ' ')

$sm = @"
# Continuidad de los secretos - evidencia (generada por scripts/evidencia-continuidad.ps1)

Mecanismo: **Sealed Secrets con respaldo de la llave en Azure Key Vault** (externo al cluster) y restauracion
automatica por Terraform. Consulta hecha el $(Get-Stamp) UTC sobre el cluster reconstruido. No se imprime ninguna llave.

## Como funciona

1. Las llaves privadas del controlador se respaldan con ``scripts/backup-sealed-key.ps1`` en el Key Vault
   ``$VaultName`` (secreto ``$SecretName``, actualizado $($kvMeta.updated)). El Key Vault esta en la capa persistente
   (``rg-sa-p9-backend``), fuera del cluster y fuera del estado de Terraform que se destruye.
2. En el bootstrap, ``P9/terraform/sealed-secrets-key.tf`` lee el secreto y crea los ``Secret`` de llave en ``kube-system``
   **antes** de que ArgoCD cree la aplicacion raiz (dependencia explicita en ``bootstrap.tf``), de modo que el controlador
   las carga al arrancar.
3. El controlador se despliega con ``--key-renew-period 0`` (argumentos reales: ``$renew``), asi la copia del Key Vault no
   se queda obsoleta por rotacion automatica.

## Prueba: las llaves del cluster reconstruido son las del Key Vault

Se compara la huella SHA-256 del certificado publico (``tls.crt``) de cada llave entre el Key Vault y el cluster.

| Llave | Certificado emitido | SHA-256 (Key Vault) | SHA-256 (cluster) | Resultado |
|---|---|---|---|---|
$($cmp -join "`n")

## Prueba: el SealedSecret del repositorio se descifra

| Comprobacion | Resultado |
|---|---|
| ``SealedSecret/sa-platform-secrets`` (namespace ``sa-p8``) | condicion ``$($ss.status.conditions[0].type)`` = **$($ss.status.conditions[0].status)** desde $($ss.status.conditions[0].lastTransitionTime) |
| ``Secret/sa-platform-secrets`` generado por el controlador | existe; claves: $secKeys |
| Propietario del Secret | ``$($sec.metadata.ownerReferences[0].kind)/$($sec.metadata.ownerReferences[0].name)`` |
| Errores ``no key could decrypt`` en el log del controlador (ultimas 1000 lineas) | **$decryptErrors** |
| Cifrado con la llave restaurada | El ``SealedSecret`` del repositorio se cifro antes de destruir el cluster; el cluster nuevo nunca vio esa llave salvo por el Key Vault. Que se descifre prueba la continuidad. |

Fragmento del log del controlador (sin valores secretos):

``````
$ctlLog
``````
"@
Set-Content -Path (Join-Path $OutDir 'continuidad-secretos.md') -Value $sm -Encoding UTF8
Mark 'evidencia: continuidad-secretos.md escrito'
