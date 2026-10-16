<#
.SYNOPSIS
  Punto de entrada unico para levantar el clúster de Practica 10.

.DESCRIPTION
  1. terraform apply (AKS de 1 nodo, ArgoCD, app raiz p10-root-app)
  2. Espera nodos, ArgoCD y que las aplicaciones del app-of-apps queden Synced
  3. Verifica el sistema (verificar.ps1)

  No usa LoadBalancer ni ACR: el objetivo es el costo mas bajo posible. Para
  apagarlo cuando se termine de usar: .\teardown.ps1
#>
param(
    [string]$LogFile,
    [int]$SyncTimeoutMinutes = 20
)
. "$PSScriptRoot\common.ps1"
$script:LogFile = $LogFile
$p10 = Split-Path $PSScriptRoot -Parent
$tf = Join-Path $p10 'terraform'
$apps = @('sealed-secrets', 'argo-rollouts', 'kyverno', 'prometheus', 'otel-collector', 'tempo', 'loki', 'promtail', 'grafana', 'p8-kyverno-policies', 'sa-platform-dev')

Mark 'bootstrap: INICIO'

foreach ($t in 'az', 'terraform', 'kubectl') {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) { throw "Falta la herramienta '$t' en el PATH" }
}
Invoke-Native az account show --query id -o tsv | Out-Null
Mark 'bootstrap: prerrequisitos OK'

Mark 'bootstrap: terraform init'
Invoke-Native terraform "-chdir=$tf" init -input=false
Mark 'bootstrap: terraform apply (AKS 1 nodo + ArgoCD + app raiz)'
Invoke-Native terraform "-chdir=$tf" apply -auto-approve -input=false
Mark 'bootstrap: terraform apply COMPLETO'

$rg = (& terraform "-chdir=$tf" output -raw resource_group)
$cluster = (& terraform "-chdir=$tf" output -raw cluster_name)
Invoke-Native az aks get-credentials --resource-group $rg --name $cluster --overwrite-existing | Out-Null
Wait-Until -What 'nodo AKS Ready' -TimeoutSeconds 600 -Condition {
    $n = @((Get-Kube get nodes -o json | ConvertFrom-Json).items)
    ($n.Count -ge 1) -and (@($n | Where-Object { @($_.status.conditions | Where-Object { $_.type -eq 'Ready' -and $_.status -eq 'True' }).Count -eq 1 }).Count -eq $n.Count)
}
Mark 'bootstrap: AKS disponible'

Wait-Until -What 'argocd-server disponible' -TimeoutSeconds 600 -Condition {
    $d = Get-Kube -n argocd get deploy argocd-server -o json | ConvertFrom-Json
    [int]$d.status.readyReplicas -ge 1
}
Mark 'bootstrap: ArgoCD disponible'

Wait-Until -What 'p10-root-app creada' -TimeoutSeconds 300 -Condition { Get-KubeOrNull -n argocd get application p10-root-app }
Mark 'bootstrap: p10-root-app presente'

$reported = @{}
Wait-Until -What 'aplicaciones Synced' -TimeoutSeconds ($SyncTimeoutMinutes * 60) -IntervalSeconds 15 -Condition {
    $list = (Get-Kube -n argocd get applications -o json | ConvertFrom-Json).items
    $ok = $true
    foreach ($a in $apps) {
        $x = $list | Where-Object { $_.metadata.name -eq $a }
        $good = $x -and ($x.status.sync.status -eq 'Synced')
        if ($good -and -not $reported[$a]) { $reported[$a] = $true; Mark "bootstrap: app $a Synced" }
        if (-not $good) { $ok = $false }
    }
    $ok
}
Mark 'bootstrap: todas las aplicaciones Synced'

Wait-Until -What 'p10-root-app Healthy' -TimeoutSeconds 300 -Condition {
    (Get-Kube -n argocd get application p10-root-app -o jsonpath='{.status.health.status}') -eq 'Healthy'
}
Mark 'bootstrap: p10-root-app Healthy'

& "$PSScriptRoot\verificar.ps1" -LogFile $LogFile
$verifyRc = $LASTEXITCODE
Mark 'bootstrap: FIN'
if ($verifyRc -ne 0) { throw 'verificar.ps1 reporto controles con FALLO (ver el registro)' }
