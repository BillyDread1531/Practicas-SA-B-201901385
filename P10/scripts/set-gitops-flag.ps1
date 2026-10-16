<#
.SYNOPSIS
  Cambia un flag (ej. FAULT_INJECTION) en environments/dev/values.yaml del
  repositorio GitOps (rama p10), hace commit y push. ArgoCD sincroniza solo.

.DESCRIPTION
  Cambiar el ConfigMap de un servicio cambia su checksum/config -> Argo
  Rollouts (gateway) lo trata como una revision nueva (canary); en los
  Deployments planos (auth-service, cursos-service) dispara un rolling
  update normal. Asi es como se "despliega" el fallo inducido sin tocar el
  cluster a mano.
#>
param(
    [Parameter(Mandatory)][string]$Service,     # p.ej. "auth-service" o "gateway"
    [Parameter(Mandatory)][string]$Key,         # p.ej. "FAULT_INJECTION"
    [Parameter(Mandatory)][string]$Value,       # p.ej. "true" / "false"
    [string]$GitOpsDir,
    [string]$Branch = 'p10'
)
# PowerShell 5.1: $PSScriptRoot no esta disponible al evaluar los valores por
# defecto de los parametros cuando el script tiene parametros Mandatory, asi
# que ese calculo se hace aqui en el cuerpo en vez de en el param() block.
if (-not $GitOpsDir) { $GitOpsDir = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'P8-GitOps' }
. "$PSScriptRoot\common.ps1"

Push-Location $GitOpsDir
try {
    Invoke-Native git checkout $Branch | Out-Null
    Invoke-Native git pull --ff-only origin $Branch | Out-Null

    $path = 'environments/dev/values.yaml'
    $lines = Get-Content $path
    $out = New-Object System.Collections.Generic.List[string]
    $inService = $false
    $inConfig = $false
    $serviceIndent = $null
    $done = $false
    foreach ($line in $lines) {
        if ($line -match "^(?<svc>$([regex]::Escape($Service))):\s*$") {
            $inService = $true; $inConfig = $false; $out.Add($line); continue
        }
        if ($inService -and $line -match '^\s{2}config:\s*$') {
            $inConfig = $true; $out.Add($line); continue
        }
        if ($inService -and $inConfig -and ($line -match "^\s{4}$([regex]::Escape($Key)):")) {
            $out.Add("    ${Key}: `"$Value`"")
            $done = $true
            continue
        }
        if ($inService -and $line -match '^\S') { $inService = $false; $inConfig = $false }
        $out.Add($line)
    }
    if (-not $done) { throw "No se encontro ${Service}.config.${Key} en $path" }

    Set-Content -Path $path -Value $out -Encoding UTF8
    Invoke-Native git add $path
    git diff --cached --quiet
    $hasDiff = ($LASTEXITCODE -ne 0)
    if (-not $hasDiff) { Mark "set-gitops-flag: ${Service}.${Key} ya era $Value, sin cambios"; return }
    Invoke-Native git commit -m "chore(p10): ${Service}.${Key}=${Value} (prueba automatizada)" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
    Invoke-Native git push origin $Branch
    Mark "set-gitops-flag: ${Service}.${Key}=${Value} publicado en GitOps (rama $Branch)"
} finally { Pop-Location }
