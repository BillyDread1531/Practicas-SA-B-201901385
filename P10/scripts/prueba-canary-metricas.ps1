<#
.SYNOPSIS
  Demuestra que el canary del gateway se revierte SOLO, por metricas reales
  de Prometheus, sin intervencion humana (rubrica 2.2 - 16 pts).

.DESCRIPTION
  1. Trafico de base.
  2. Se activa CANARY_FAULT_INJECTION=true en el gateway via GitOps. Argo
     Rollouts despliega esa revision como canary (setWeight 20%).
  3. Trafico continuo contra el gateway mientras el canary esta activo (el
     Service nativo de Kubernetes reparte el trafico entre pods estables y
     canary segun su proporcion de replicas: "canary basico" sin malla de
     servicio, documentado por Argo Rollouts).
  4. Se observa el AnalysisRun: debe fallar por tasa-de-error y/o
     latencia-p95 del CANARY (filtrado por rollouts_pod_template_hash).
  5. El Rollout aborta solo: pesos vuelven a 0% canary / 100% estable.
  6. Se revierte CANARY_FAULT_INJECTION=false para dejar todo limpio.
#>
param(
    [string]$Namespace = 'sa-p8',
    [string]$EvidenceFile = (Join-Path $PSScriptRoot '..\evidencias\canary-metricas.md'),
    [int]$TimeoutMinutes = 10
)
. "$PSScriptRoot\common.ps1"
$script:LogFile = Join-Path ([IO.Path]::GetTempPath()) ("p10-canary-{0}.log" -f (Get-Date -Format 'yyyyMMddHHmmss'))
Set-Content -Path $script:LogFile -Value '' -Encoding UTF8

Mark 'canary-metricas: trafico de base (20s)'
& "$PSScriptRoot\generar-trafico.ps1" -DurationSeconds 20 -RequestsPerSecond 2 -Namespace $Namespace -InCluster

$rolloutBefore = Get-Kube -n $Namespace get rollout gateway -o json | ConvertFrom-Json
$revisionBefore = $rolloutBefore.status.currentPodHash
Mark "canary-metricas: revision estable actual = $revisionBefore"

Mark 'canary-metricas: activando CANARY_FAULT_INJECTION=true en el gateway'
# Nonce unico por corrida: si el ConfigMap quedara con el mismo contenido de
# una corrida anterior, el pod-template-hash del canary seria IDENTICO y
# Argo Rollouts reutilizaria la revision y el AnalysisRun ya concluido del
# historial en vez de medir trafico real otra vez (asi se descubrio este
# bug: un AnalysisRun "Inconclusive" con startedAt de minutos antes).
& "$PSScriptRoot\set-gitops-flag.ps1" -Service gateway -Key CANARY_TEST_NONCE -Value ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
& "$PSScriptRoot\set-gitops-flag.ps1" -Service gateway -Key CANARY_FAULT_INJECTION -Value true
$tStart = Get-Stamp
Invoke-Native kubectl -n argocd annotate application sa-platform-dev argocd.argoproj.io/refresh=hard --overwrite | Out-Null

# El trafico se lanza YA, en paralelo con la espera de la revision canary
# (no despues): el AnalysisRun arranca su primera medicion de 15s en cuanto
# Argo Rollouts entra al paso "analysis", que ocurre casi al mismo tiempo
# que currentPodHash cambia. Si se espera a detectar la revision ANTES de
# lanzar el trafico, el arranque del Pod de trafico (scheduling + pull +
# register/login) se come 1-2 de las 5 mediciones y el AnalysisRun termina
# Inconclusive en vez de Failed.
Mark 'canary-metricas: generando trafico continuo (arranca ya, en paralelo con la deteccion de la revision)'
$trafficJob = Start-Job -ScriptBlock {
    param($scriptPath, $ns)
    & $scriptPath -DurationSeconds 300 -RequestsPerSecond 5 -Namespace $ns -InCluster
} -ArgumentList (Join-Path $PSScriptRoot 'generar-trafico.ps1'), $Namespace

Mark 'canary-metricas: esperando que Argo Rollouts cree la revision canary'
$canaryHash = $null
Wait-Until -What 'nueva revision canary' -TimeoutSeconds 180 -IntervalSeconds 5 -Condition {
    $ro = Get-Kube -n $Namespace get rollout gateway -o json | ConvertFrom-Json
    if ($ro.status.currentPodHash -and $ro.status.currentPodHash -ne $revisionBefore) {
        $script:canaryHash = $ro.status.currentPodHash; $true
    } else { $false }
}
Mark "canary-metricas: revision canary = $canaryHash"

Mark 'canary-metricas: esperando el resultado del AnalysisRun (debe fallar por metricas del canary)'
$analysisRun = $null
$outcome = $null
Wait-Until -What 'AnalysisRun concluido' -TimeoutSeconds ($TimeoutMinutes * 60) -IntervalSeconds 5 -Condition {
    # OJO: la etiqueta real que pone Argo Rollouts es "rollouts-pod-template-hash"
    # (con "s"), no "rollout-pod-template-hash". Con el typo, este filtro nunca
    # matcheaba nada y el script terminaba aceptando CUALQUIER AnalysisRun del
    # Rollout "gateway" (incluyendo corridas viejas ya concluidas de pasos
    # anteriores), dando por bueno un resultado que no era el de esta corrida.
    $runs = @((Get-Kube -n $Namespace get analysisrun -o json | ConvertFrom-Json).items |
        Where-Object { $_.metadata.labels.'rollouts-pod-template-hash' -eq $canaryHash } |
        Sort-Object { $_.metadata.creationTimestamp })
    $latest = $runs | Select-Object -Last 1
    if ($latest -and $latest.status.phase -in @('Successful', 'Failed', 'Error', 'Inconclusive')) {
        $script:analysisRun = $latest.metadata.name
        $script:outcome = $latest.status.phase
        $true
    } else { $false }
}
$tAnalysis = Get-Stamp
Mark "canary-metricas: AnalysisRun $analysisRun -> $outcome (a las $tAnalysis)"

Mark 'canary-metricas: esperando que el Rollout quede Degraded/abortado con 0 replicas canary'
Wait-Until -What 'rollout abortado' -TimeoutSeconds 180 -IntervalSeconds 5 -Condition {
    $ro = Get-Kube -n $Namespace get rollout gateway -o json | ConvertFrom-Json
    ($ro.status.abort -eq $true) -or ($ro.status.phase -in @('Degraded')) -or ([int]($ro.status.canary.weights.canary) -eq 0)
}
$tAborted = Get-Stamp
$rolloutAfter = Get-Kube -n $Namespace get rollout gateway -o json | ConvertFrom-Json
Mark "canary-metricas: Rollout abortado a las $tAborted (phase=$($rolloutAfter.status.phase), abort=$($rolloutAfter.status.abort))"

Wait-Job $trafficJob -Timeout 320 | Out-Null
$trafficOut = Receive-Job $trafficJob
Remove-Job $trafficJob -Force

$analysisRunYaml = Get-Kube -n $Namespace get analysisrun $analysisRun -o yaml
$rolloutDescribe = & kubectl -n $Namespace describe rollout gateway 2>&1 | Out-String
$events = Get-Kube -n $Namespace get events --field-selector "involvedObject.name=gateway" --sort-by=.lastTimestamp

Mark 'canary-metricas: revirtiendo CANARY_FAULT_INJECTION=false'
& "$PSScriptRoot\set-gitops-flag.ps1" -Service gateway -Key CANARY_FAULT_INJECTION -Value false
Invoke-Native kubectl -n argocd annotate application sa-platform-dev argocd.argoproj.io/refresh=hard --overwrite | Out-Null
Wait-Until -What 'rollout Healthy de nuevo' -TimeoutSeconds 1200 -IntervalSeconds 10 -Condition {
    (Get-Kube -n $Namespace get rollout gateway -o jsonpath='{.status.phase}') -eq 'Healthy'
}
Mark 'canary-metricas: Rollout Healthy de nuevo (100% estable)'

function Secs([string]$a, [string]$b) { [int]([datetime]::Parse($b) - [datetime]::Parse($a)).TotalSeconds }
$log = Get-Content $script:LogFile -Raw
$md = @"
# Reversión del canary por métricas - evidencia automática

Generada por ``P10/scripts/prueba-canary-metricas.ps1``. Fallo inducido: ``CANARY_FAULT_INJECTION=true`` en el
**gateway** (distinto al fallo de la Práctica 8 y al de ``auth-service`` usado en el recorrido síntoma-causa).
Horas en UTC.

| Campo | Valor |
|---|---|
| Rollout | ``gateway`` (namespace ``$Namespace``) |
| Revisión estable (antes) | ``$revisionBefore`` |
| Revisión canary (con el fallo) | ``$canaryHash`` |
| **AnalysisRun** | ``$analysisRun`` -> **$outcome** |
| Fallo activado | $tStart |
| AnalysisRun concluido | $tAnalysis ($(Secs $tStart $tAnalysis) s después) |
| Rollout abortado (0% canario) | $tAborted ($(Secs $tStart $tAborted) s después) |
| Intervención humana durante la reversión | **Ninguna**: Argo Rollouts abortó solo al ver el AnalysisRun fallido |

## AnalysisRun completo (las consultas PromQL que decidieron la reversión están aquí)

``````yaml
$analysisRunYaml
``````

## kubectl describe rollout gateway

``````
$rolloutDescribe
``````

## Eventos del Rollout

``````
$events
``````

## Registro con marcas de tiempo

``````
$log
``````
"@
Set-Content -Path $EvidenceFile -Value $md -Encoding UTF8
Mark "canary-metricas: evidencia escrita en $EvidenceFile"
if ($outcome -ne 'Failed' -and $outcome -ne 'Error') { throw "El AnalysisRun no fallo por las metricas esperadas (outcome=$outcome): revisar el fallo inducido, los umbrales o el trafico" }
