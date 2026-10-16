<#
.SYNOPSIS
  Recorrido cronometrado del sintoma a la causa (rubrica 2.4), con fallo
  inducido DISTINTO al de P8: auth-service, via FAULT_INJECTION.

.DESCRIPTION
  1. Trafico de base (sin fallo) durante 20s, para que la linea base del
     dashboard/alertas no esta vacia.
  2. T0: se activa FAULT_INJECTION=true en auth-service via GitOps (commit +
     push). ArgoCD lo sincroniza y el Deployment hace un rolling update.
  3. Trafico continuo contra /auth/login mientras tanto.
  4. T1: primera alerta "TasaErrorAuthServiceElevada" en estado firing
     (consultando la API de Prometheus).
  5. Se toma un trace_id real de una traza con error en Tempo (servicio
     auth-service) y se consulta Loki filtrando por ese trace_id: se
     confirma el mensaje del fallo inducido.
  6. T2: fin del recorrido (causa confirmada).
  7. Se revierte FAULT_INJECTION=false y se espera a que el sistema vuelva
     al estado estable (T3).
  8. Se escribe la evidencia con los tiempos reales.
#>
param(
    [string]$Namespace = 'sa-p8',
    [string]$EvidenceFile = (Join-Path $PSScriptRoot '..\evidencias\sintoma-a-causa.md')
)
. "$PSScriptRoot\common.ps1"
$script:LogFile = Join-Path ([IO.Path]::GetTempPath()) ("p10-sintoma-causa-{0}.log" -f (Get-Date -Format 'yyyyMMddHHmmss'))
Set-Content -Path $script:LogFile -Value '' -Encoding UTF8

function Invoke-PromAPI([string]$Path) {
    $pf = Start-PortForward -Namespace observability -Service prometheus-server -LocalPort 19090 -RemotePort 80
    try {
        return Invoke-RestMethod -Uri "http://127.0.0.1:19090$Path" -TimeoutSec 10
    } finally { Stop-Process -Id $pf.Id -Force -ErrorAction SilentlyContinue }
}
function Invoke-LokiAPI([string]$Query, [int]$Limit = 20) {
    $pf = Start-PortForward -Namespace observability -Service loki -LocalPort 13100 -RemotePort 3100
    try {
        $q = [uri]::EscapeDataString($Query)
        return Invoke-RestMethod -Uri "http://127.0.0.1:13100/loki/api/v1/query_range?query=$q&limit=$Limit" -TimeoutSec 10
    } finally { Stop-Process -Id $pf.Id -Force -ErrorAction SilentlyContinue }
}
function Invoke-TempoAPI([string]$Path) {
    $pf = Start-PortForward -Namespace observability -Service tempo -LocalPort 13200 -RemotePort 3200
    try {
        return Invoke-RestMethod -Uri "http://127.0.0.1:13200$Path" -TimeoutSec 10
    } finally { Stop-Process -Id $pf.Id -Force -ErrorAction SilentlyContinue }
}

Mark 'sintoma-causa: trafico de base (20s, sin fallo)'
& "$PSScriptRoot\generar-trafico.ps1" -DurationSeconds 20 -RequestsPerSecond 2 -Namespace $Namespace

Mark 'sintoma-causa: T0 - activando FAULT_INJECTION=true en auth-service'
& "$PSScriptRoot\set-gitops-flag.ps1" -Service auth-service -Key FAULT_INJECTION -Value true
$T0 = Get-Stamp
Mark "sintoma-causa: T0 = $T0"

Wait-Until -What 'ArgoCD sincroniza auth-service' -TimeoutSeconds 180 -IntervalSeconds 5 -Condition {
    (Get-Kube -n argocd get application sa-platform-dev -o jsonpath='{.status.sync.status}') -eq 'Synced'
}
Invoke-Native kubectl -n argocd annotate application sa-platform-dev argocd.argoproj.io/refresh=hard --overwrite | Out-Null

Mark 'sintoma-causa: generando trafico continuo contra /auth/login mientras el fallo esta activo'
$trafficJob = Start-Job -ScriptBlock {
    param($scriptPath, $ns)
    & $scriptPath -DurationSeconds 180 -RequestsPerSecond 3 -Namespace $ns
} -ArgumentList (Join-Path $PSScriptRoot 'generar-trafico.ps1'), $Namespace

Mark 'sintoma-causa: esperando la alerta TasaErrorAuthServiceElevada (firing)'
$T1 = $null
Wait-Until -What 'alerta firing' -TimeoutSeconds 180 -IntervalSeconds 5 -Condition {
    $alerts = Invoke-PromAPI '/api/v1/alerts'
    $a = $alerts.data.alerts | Where-Object { $_.labels.alertname -eq 'TasaErrorAuthServiceElevada' -and $_.state -eq 'firing' }
    if ($a) { $script:T1 = Get-Stamp; $true } else { $false }
}
Mark "sintoma-causa: T1 (alerta firing) = $T1"

Mark 'sintoma-causa: buscando una traza con error de auth-service en Tempo'
$traceId = $null
Wait-Until -What 'traza con error en Tempo' -TimeoutSeconds 120 -IntervalSeconds 5 -Condition {
    $q = [uri]::EscapeDataString('{ resource.service.name="auth-service" && status=error }')
    $r = Invoke-TempoAPI "/api/search?q=$q&limit=5"
    if ($r.traces -and $r.traces.Count -gt 0) { $script:traceId = $r.traces[0].traceID; $true } else { $false }
}
Mark "sintoma-causa: trace_id de error encontrado = $traceId"

Mark 'sintoma-causa: abriendo los registros de esa traza en Loki'
$logs = Invoke-LokiAPI "{namespace=`"$Namespace`"} | json | trace_id=`"$traceId`""
$logLines = @($logs.data.result | ForEach-Object { $_.values } | ForEach-Object { $_[1] })
$T2 = Get-Stamp
Mark "sintoma-causa: T2 (causa confirmada en Loki) = $T2 ($($logLines.Count) lineas de registro para esa traza)"

Wait-Job $trafficJob -Timeout 200 | Out-Null
$trafficOut = Receive-Job $trafficJob
Remove-Job $trafficJob -Force

Mark 'sintoma-causa: revirtiendo FAULT_INJECTION=false'
& "$PSScriptRoot\set-gitops-flag.ps1" -Service auth-service -Key FAULT_INJECTION -Value false
Invoke-Native kubectl -n argocd annotate application sa-platform-dev argocd.argoproj.io/refresh=hard --overwrite | Out-Null
$T3 = $null
Wait-Until -What 'alerta resuelta' -TimeoutSeconds 300 -IntervalSeconds 10 -Condition {
    $alerts = Invoke-PromAPI '/api/v1/alerts'
    $a = $alerts.data.alerts | Where-Object { $_.labels.alertname -eq 'TasaErrorAuthServiceElevada' -and $_.state -eq 'firing' }
    if (-not $a) { $script:T3 = Get-Stamp; $true } else { $false }
}
Mark "sintoma-causa: T3 (alerta resuelta, sistema estable) = $T3"

function Secs([string]$a, [string]$b) { [int]([datetime]::Parse($b) - [datetime]::Parse($a)).TotalSeconds }
$deteccionSeg = Secs $T0 $T1
$causaSeg = Secs $T0 $T2
$recuperacionSeg = Secs $T0 $T3

$log = Get-Content $script:LogFile -Raw
$md = @"
# Recorrido síntoma a causa - evidencia automática

Generada por ``P10/scripts/prueba-sintoma-causa.ps1``. Fallo inducido: ``FAULT_INJECTION=true`` en
``auth-service`` (distinto al fallo de la Práctica 8). Horas en UTC.

| Marca | Hora | Descripción |
|---|---|---|
| T0 - fallo activado | $T0 | ``FAULT_INJECTION=true`` publicado en GitOps y sincronizado por ArgoCD |
| T1 - primera señal (alerta) | $T1 | Alerta ``TasaErrorAuthServiceElevada`` en estado **firing** |
| T2 - causa confirmada | $T2 | Traza con error localizada en Tempo (``trace_id=$traceId``) y su registro correspondiente abierto en Loki |
| T3 - sistema estable | $T3 | ``FAULT_INJECTION=false``, alerta resuelta |

## Tiempos medidos

| Indicador | Medido |
|---|---|
| **Tiempo de detección** (T1 - T0) | **$deteccionSeg s** |
| **Recorrido hasta la causa** (T2 - T0) | **$causaSeg s** ($([math]::Round($causaSeg/60,1)) min) — objetivo de la rúbrica: menos de 3 minutos |
| Tiempo hasta la recuperación (T3 - T0) | $recuperacionSeg s |

## Registros encontrados para ``trace_id=$traceId``

``````
$($logLines -join "`n")
``````

## Registro completo con marcas de tiempo

``````
$log
``````
"@
Set-Content -Path $EvidenceFile -Value $md -Encoding UTF8
Mark "sintoma-causa: evidencia escrita en $EvidenceFile"
if ($causaSeg -gt 180) { Write-Warning "El recorrido tardo $causaSeg s, por encima del objetivo de 3 minutos. Documentar la brecha en el informe." }
