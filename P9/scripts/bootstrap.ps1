<#
.SYNOPSIS
  PUNTO DE ENTRADA UNICO del bootstrap de dia cero (Practica 9).

.DESCRIPTION
  Reconstruye el sistema completo desde cero con un solo comando, sin pasos manuales:

    1. terraform apply   (estado remoto en Azure Blob con bloqueo)
         AKS -> ArgoCD -> llaves de Sealed Secrets (desde Key Vault) -> Velero -> app raiz p9-root-app
    2. ArgoCD (app-of-apps, por olas):
         ola 0: sealed-secrets, argo-rollouts, kyverno
         ola 1: p8-kyverno-policies
         ola 2: sa-platform-dev (microservicios, PostgreSQL, RabbitMQ)
    3. Restauracion de datos desde el ultimo respaldo de Velero (si existe alguno)
    4. Verificacion del sistema y registro con marcas de tiempo

  Prerrequisitos: az login, terraform >= 1.6, kubectl. Ver runbook-recuperacion.md.

.PARAMETER SkipRestore
  No restaurar datos (util en la primera instalacion o para medir solo la infraestructura).

.PARAMETER LogFile
  Archivo donde se agregan las marcas de tiempo (para calcular el RTO).
#>
param(
    [switch]$SkipRestore,
    [string]$LogFile,
    [string]$VaultName = 'kv-p9-201901385',
    [int]$SyncTimeoutMinutes = 45
)
. "$PSScriptRoot\common.ps1"
$script:LogFile = $LogFile
$p9   = Split-Path $PSScriptRoot -Parent
$tf   = Join-Path $p9 'terraform'
$apps = @('sealed-secrets', 'argo-rollouts', 'kyverno', 'p8-kyverno-policies', 'sa-platform-dev')

Mark 'bootstrap: INICIO'

# --- 0. Prerrequisitos -----------------------------------------------------------------------
foreach ($t in 'az', 'terraform', 'kubectl') {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) { throw "Falta la herramienta '$t' en el PATH" }
}
Invoke-Native az account show --query id -o tsv | Out-Null
Mark 'bootstrap: prerrequisitos OK (az autenticado, terraform, kubectl)'

# --- 1. Terraform: cluster + ArgoCD + llaves + Velero + app raiz --------------------------------
Mark 'bootstrap: terraform init (backend remoto azurerm con bloqueo)'
Invoke-Native terraform "-chdir=$tf" init -input=false
Mark 'bootstrap: terraform apply (AKS, ArgoCD, llaves Sealed Secrets, Velero, p9-root-app)'
Invoke-Native terraform "-chdir=$tf" apply -auto-approve -input=false
Mark 'bootstrap: terraform apply COMPLETO'

$rg      = (& terraform "-chdir=$tf" output -raw resource_group)
$cluster = (& terraform "-chdir=$tf" output -raw cluster_name)
Invoke-Native az aks get-credentials --resource-group $rg --name $cluster --overwrite-existing | Out-Null
Wait-Until -What 'nodos Ready' -TimeoutSeconds 600 -Condition {
    $n = @((Get-Kube get nodes -o json | ConvertFrom-Json).items)
    ($n.Count -ge 2) -and (@($n | Where-Object { @($_.status.conditions | Where-Object { $_.type -eq 'Ready' -and $_.status -eq 'True' }).Count -eq 1 }).Count -eq $n.Count)
}
Mark 'bootstrap: AKS disponible (nodos Ready)'
Wait-Until -What 'argocd-server disponible' -TimeoutSeconds 600 -Condition {
    $d = Get-Kube -n argocd get deploy argocd-server -o json | ConvertFrom-Json
    [int]$d.status.readyReplicas -ge 1
}
Mark 'bootstrap: ArgoCD disponible (argocd-server Ready)'

# --- 2. ArgoCD sincroniza el resto (app-of-apps) -----------------------------------------------------
Wait-Until -What 'p9-root-app creada' -TimeoutSeconds 300 -Condition { Get-KubeOrNull -n argocd get application p9-root-app }
Mark 'bootstrap: p9-root-app presente en ArgoCD (namespace argocd)'
$reported = @{}
Wait-Until -What 'aplicaciones ArgoCD Synced/Healthy' -TimeoutSeconds ($SyncTimeoutMinutes * 60) -IntervalSeconds 15 -Condition {
    $list = (Get-Kube -n argocd get applications -o json | ConvertFrom-Json).items
    $ok = $true
    foreach ($a in $apps) {
        $x = $list | Where-Object { $_.metadata.name -eq $a }
        $good = $x -and ($x.status.sync.status -eq 'Synced') -and ($x.status.health.status -in @('Healthy'))
        if ($a -eq 'sa-platform-dev') { $good = $x -and ($x.status.sync.status -eq 'Synced') }
        if ($good -and -not $reported[$a]) { $reported[$a] = $true; Mark "bootstrap: app $a Synced" }
        if (-not $good) { $ok = $false }
    }
    $ok
}
Mark 'bootstrap: todas las aplicaciones del app-of-apps sincronizadas'
Wait-Until -What 'p9-root-app Healthy' -TimeoutSeconds 300 -Condition {
    (Get-Kube -n argocd get application p9-root-app -o jsonpath='{.status.health.status}') -eq 'Healthy'
}
Mark 'bootstrap: p9-root-app Healthy'

# Secretos: el SealedSecret debe descifrarse con la llave restaurada desde Key Vault
Wait-Until -What 'SealedSecret descifrado' -TimeoutSeconds 300 -Condition {
    $ss = Get-Kube -n sa-p8 get sealedsecret sa-platform-secrets -o json | ConvertFrom-Json
    (@($ss.status.conditions | Where-Object { $_.type -eq 'Synced' -and $_.status -eq 'True' }).Count -eq 1) -and (Get-KubeOrNull -n sa-p8 get secret sa-platform-secrets)
}
Mark 'bootstrap: SealedSecret sa-platform-secrets DESCIFRADO (Secret creado por el controlador)'

# Primera instalacion: si el Key Vault aun no tiene llaves, respaldar las que genero el controlador
$kvVal = az keyvault secret show --vault-name $VaultName --name sealed-secrets-keys --query value -o tsv
if ($kvVal -eq '[]') {
    Mark 'bootstrap: Key Vault sin llaves (primera instalacion) -> respaldando la llave del controlador'
    & "$PSScriptRoot\backup-sealed-key.ps1" -VaultName $VaultName
}

# Workloads de aplicacion listos (con volumenes vacios si es instalacion nueva)
Wait-Until -What 'PostgreSQL y RabbitMQ Ready' -TimeoutSeconds 900 -Condition {
    foreach ($p in 'postgresql-0', 'rabbitmq-0') {
        $pod = Get-Kube -n sa-p8 get pod $p -o json | ConvertFrom-Json
        if (@($pod.status.conditions | Where-Object { $_.type -eq 'Ready' -and $_.status -eq 'True' }).Count -ne 1) { return $false }
    }
    $true
}
Mark 'bootstrap: PostgreSQL y RabbitMQ Ready (volumenes nuevos)'

# --- 3. Restauracion de datos ---------------------------------------------------------------------------
if ($SkipRestore) {
    Mark 'bootstrap: restauracion de datos OMITIDA (-SkipRestore)'
} else {
    Mark 'bootstrap: buscando respaldos de Velero en el Blob persistente'
    $has = $false
    try {
        Wait-Until -What 'respaldos visibles' -TimeoutSeconds 240 -IntervalSeconds 10 -Condition {
            (Get-Kube -n velero get backup -l 'velero.io/schedule-name=velero-p9-platform' -o name) -match 'backup'
        }
        $has = $true
    } catch { }
    if ($has) {
        & "$PSScriptRoot\restore-datos.ps1" -LogFile $LogFile
        Mark 'bootstrap: datos restaurados desde Velero'
    } else {
        Mark 'bootstrap: no hay respaldos previos (primera instalacion): se conservan los volumenes nuevos'
    }
}

# --- 4. Verificacion --------------------------------------------------------------------------------------
& "$PSScriptRoot\verificar.ps1" -LogFile $LogFile
Mark 'bootstrap: FIN'
