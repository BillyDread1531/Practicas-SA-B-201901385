<#
.SYNOPSIS
  Restaura los datos (PostgreSQL y RabbitMQ) desde un respaldo de Velero, EN el
  namespace de produccion, y verifica que los volumenes se hayan repuesto.

.DESCRIPTION
  Funciona tanto para "se borraron datos" como para "se reconstruyo el cluster".
  Pasos (todos automaticos):
    1. Pausa GitOps (app raiz + sa-platform-dev) para que ArgoCD no recree
       StatefulSet/PVC vacios mientras se restaura.
    2. Elimina el StatefulSet y el PVC (datos danados o vacios).
    3. Crea un Restore de Velero (respaldo indicado o el ultimo del schedule)
       limitado a statefulsets, pods, PVC y PV de PostgreSQL/RabbitMQ (sin los PV
       el PVC restaurado queda Pending apuntando a un disco que ya no existe). Velero inyecta
       el initContainer restore-wait y el node-agent repone los datos (Kopia).
    4. Espera los PodVolumeRestore y que el pod quede Ready.
    5. Reactiva GitOps.

  IMPORTANTE: la politica Kyverno p8-require-non-root exime el initContainer
  "restore-wait" (ver P8/security/kyverno/03-require-non-root.yaml); sin esa
  excepcion el pod restaurado es rechazado y el volumen queda vacio.
#>
param(
    [string]$BackupName,
    [string]$Schedule  = 'velero-p9-platform',
    [string]$Namespace = 'sa-p8',
    [string[]]$Apps    = @('postgresql', 'rabbitmq'),
    [int]$TimeoutMinutes = 25,
    [string]$LogFile
)
. "$PSScriptRoot\common.ps1"
$script:LogFile = $LogFile

# --- 0. Localizar el respaldo -------------------------------------------------
Mark "restore-datos: buscando respaldo (schedule=$Schedule)"
Wait-Until -What 'respaldos sincronizados desde el Blob' -TimeoutSeconds 600 -Condition {
    (Get-Kube -n velero get backup -l "velero.io/schedule-name=$Schedule" -o name) -match 'backup'
}
Wait-Until -What 'BackupStorageLocation Available' -TimeoutSeconds 300 -Condition {
    (Get-Kube -n velero get backupstoragelocation default -o jsonpath='{.status.phase}') -eq 'Available'
}

if (-not $BackupName) {
    $items = @((Get-Kube -n velero get backup -l "velero.io/schedule-name=$Schedule" -o json | ConvertFrom-Json).items |
        Where-Object { $_.status.phase -eq 'Completed' } | Sort-Object { $_.status.startTimestamp })
    if ($items.Count -gt 0) { $BackupName = $items[-1].metadata.name }
}
if (-not $BackupName) { throw 'No hay respaldos Completed para restaurar' }
$backupTime = Get-Kube -n velero get backup $BackupName -o jsonpath='{.status.completionTimestamp}'
Mark "restore-datos: respaldo elegido = $BackupName (completado $backupTime)"

# --- 1. Pausar GitOps ----------------------------------------------------------
Mark 'restore-datos: pausando GitOps (root app + sa-platform-dev)'
Set-KubePatch argocd application p9-root-app '{"spec":{"syncPolicy":{"automated":null}}}'
if (Get-KubeOrNull -n argocd get application sa-platform-dev) {
    Set-KubePatch argocd application sa-platform-dev '{"spec":{"syncPolicy":{"automated":null}}}'
}

try {
    # --- 2. Eliminar StatefulSet + PVC ------------------------------------------
    foreach ($app in $Apps) {
        Mark "restore-datos: eliminando statefulset/$app y sus PVC"
        Invoke-Native kubectl -n $Namespace delete statefulset $app --ignore-not-found --wait=true | Out-Null
        Invoke-Native kubectl -n $Namespace delete pvc -l "app.kubernetes.io/name=$app" --ignore-not-found --wait=true | Out-Null
    }

    # --- 3. Restore de Velero ---------------------------------------------------
    $restoreName = 'p9-datos-' + (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
    $selectors = ($Apps | ForEach-Object { "    - matchLabels:`n        app.kubernetes.io/name: $_" }) -join "`n"
    $yaml = @"
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: $restoreName
  namespace: velero
spec:
  backupName: $BackupName
  includedNamespaces:
    - $Namespace
  includedResources:
    - statefulsets
    - pods
    - persistentvolumeclaims
    - persistentvolumes
  orLabelSelectors:
$selectors
  restorePVs: true
"@
    Mark "restore-datos: creando Restore $restoreName"
    $yaml | & kubectl apply -f - | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el Restore' }

    Wait-Until -What "restore $restoreName" -TimeoutSeconds ($TimeoutMinutes * 60) -IntervalSeconds 5 -Condition {
        (Get-Kube -n velero get restore $restoreName -o jsonpath='{.status.phase}') -in @('Completed', 'PartiallyFailed', 'Failed')
    }
    $phase = Get-Kube -n velero get restore $restoreName -o jsonpath='{.status.phase}'
    Mark "restore-datos: Restore $restoreName -> $phase"
    if ($phase -ne 'Completed') {
        & kubectl -n velero describe restore $restoreName
        throw "El Restore termino en $phase"
    }

    # --- 4. Verificar PodVolumeRestore y pods -----------------------------------
    $pvr = @((Get-Kube -n velero get podvolumerestore -l "velero.io/restore-name=$restoreName" -o json | ConvertFrom-Json).items)
    $bad = @($pvr | Where-Object { $_.status.phase -ne 'Completed' })
    Mark ("restore-datos: PodVolumeRestore completados = {0}/{1}" -f ($pvr.Count - $bad.Count), $pvr.Count)
    if ($pvr.Count -eq 0) { throw 'Velero no creo PodVolumeRestore: los volumenes quedarian vacios' }
    if ($bad.Count -gt 0) { throw "PodVolumeRestore sin completar: $($bad.metadata.name -join ', ')" }

    foreach ($app in $Apps) {
        Wait-Until -What "pod $app-0 Ready" -TimeoutSeconds 600 -Condition {
            $pod = Get-Kube -n $Namespace get pod "$app-0" -o json | ConvertFrom-Json
            @($pod.status.conditions | Where-Object { $_.type -eq 'Ready' -and $_.status -eq 'True' }).Count -eq 1
        }
        Mark "restore-datos: $app-0 Ready con el volumen restaurado"
    }
}
finally {
    # --- 5. Reactivar GitOps -------------------------------------------------------
    Mark 'restore-datos: reactivando GitOps'
    Set-KubePatch argocd application p9-root-app '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
}
# GitOps vuelve a reconciliar: esperar a que la app raiz y sus hijas queden Synced.
Wait-Until -What 'p9-root-app Synced tras reactivar GitOps' -TimeoutSeconds 300 -IntervalSeconds 5 -Condition {
    $apps = @((Get-Kube -n argocd get applications -o json | ConvertFrom-Json).items)
    (@($apps | Where-Object { $_.status.sync.status -ne 'Synced' }).Count -eq 0)
}
Mark 'restore-datos: GitOps reactivado y aplicaciones Synced'
Mark 'restore-datos: FIN'
