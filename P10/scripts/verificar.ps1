<#
.SYNOPSIS
  Verifica que el stack de observabilidad y el flujo de P8 estan sanos.
  Termina con codigo distinto de 0 si algun control falla.
#>
param([string]$LogFile, [string]$Namespace = 'sa-p8')
. "$PSScriptRoot\common.ps1"
$script:LogFile = $LogFile
$fails = New-Object System.Collections.Generic.List[string]

function Check {
    param([string]$Name, [scriptblock]$Test)
    try {
        $detail = & $Test
        if ($detail -is [array]) { $detail = $detail -join '; ' }
        Mark "verificar: PASS  $Name - $detail"
    } catch {
        Mark "verificar: FAIL  $Name - $($_.Exception.Message)"
        $fails.Add($Name)
    }
}

Mark 'verificar: INICIO'

Check 'Nodo AKS Ready' {
    $n = @((Get-Kube get nodes -o json | ConvertFrom-Json).items)
    $ready = @($n | Where-Object { @($_.status.conditions | Where-Object { $_.type -eq 'Ready' -and $_.status -eq 'True' }).Count -eq 1 })
    if ($ready.Count -ne $n.Count -or $n.Count -lt 1) { throw "Ready $($ready.Count)/$($n.Count)" }
    "$($ready.Count) nodo(s) Ready"
}

Check 'GitOps: app-of-apps y aplicaciones hijas' {
    $list = @((Get-Kube -n argocd get applications -o json | ConvertFrom-Json).items)
    $root = $list | Where-Object { $_.metadata.name -eq 'p10-root-app' }
    if (-not $root -or $root.status.sync.status -ne 'Synced') { throw 'p10-root-app no esta Synced' }
    $bad = @($list | Where-Object { $_.status.sync.status -ne 'Synced' })
    if ($bad.Count) { throw "no Synced: $($bad.metadata.name -join ',')" }
    ($list | ForEach-Object { "$($_.metadata.name)=$($_.status.sync.status)" })
}

Check 'Instrumentacion: Prometheus esta recolectando metricas de los 3 servicios' {
    $targets = Get-Kube -n observability exec deploy/prometheus-server -c prometheus-server -- wget -qO- http://localhost:9090/api/v1/targets
    $j = $targets | ConvertFrom-Json
    $up = @($j.data.activeTargets | Where-Object { $_.labels.service -in @('gateway', 'auth-service', 'cursos-service') -and $_.health -eq 'up' })
    if ($up.Count -lt 3) { throw "solo $($up.Count)/3 servicios con targets 'up' en Prometheus" }
    "$($up.Count) targets up: $(($up.labels.service | Select-Object -Unique) -join ', ')"
}

Check 'Canary por metricas: AnalysisTemplate consulta Prometheus (no un Job sintetico)' {
    $at = Get-Kube -n $Namespace get analysistemplate gateway-metrics -o json | ConvertFrom-Json
    $providers = @($at.spec.metrics | ForEach-Object { $_.provider.PSObject.Properties.Name })
    if ($providers -notcontains 'prometheus') { throw "provider(s) encontrados: $($providers -join ',')" }
    "metrics: $($at.spec.metrics.name -join ', ') (provider=prometheus)"
}

Check 'SLO: reglas de registro calculando indicador y presupuesto' {
    $rules = Get-Kube -n observability exec deploy/prometheus-server -c prometheus-server -- wget -qO- http://localhost:9090/api/v1/rules
    $j = $rules | ConvertFrom-Json
    $names = @($j.data.groups | ForEach-Object { $_.rules } | ForEach-Object { $_.name })
    $need = @('sli:gateway_availability:ratio_rate1h', 'slo:gateway_availability:error_budget_burn1h', 'sli:gateway_latency:p95_5m', 'slo:gateway_latency:error_budget_burn1h')
    $missing = @($need | Where-Object { $_ -notin $names })
    if ($missing.Count) { throw "faltan: $($missing -join ', ')" }
    "4 reglas SLO presentes"
}

Check 'Alertas: reglas cargadas y enlazadas a un runbook' {
    $rules = Get-Kube -n observability exec deploy/prometheus-server -c prometheus-server -- wget -qO- http://localhost:9090/api/v1/rules
    $j = $rules | ConvertFrom-Json
    $alerts = @($j.data.groups | ForEach-Object { $_.rules } | Where-Object { $_.type -eq 'alerting' })
    if ($alerts.Count -eq 0) { throw 'sin reglas de alerta cargadas' }
    $sinRunbook = @($alerts | Where-Object { -not $_.annotations.runbook_url })
    if ($sinRunbook.Count) { throw "sin runbook_url: $($sinRunbook.name -join ', ')" }
    "$($alerts.Count) alertas, todas con runbook_url"
}

Check 'Registros estructurados: Loki tiene logs JSON con trace_id' {
    $q = [uri]::EscapeDataString('{namespace="sa-p8"} | json | trace_id != ""')
    $resp = Get-Kube -n observability exec deploy/loki -- wget -qO- "http://localhost:3100/loki/api/v1/query_range?query=$q&limit=1"
    $j = $resp | ConvertFrom-Json
    $count = @($j.data.result).Count
    if ($count -eq 0) { throw 'sin resultados con trace_id en Loki (puede que aun no haya trafico; generar trafico y reintentar)' }
    "$count stream(s) con trace_id encontrados"
}

Check 'Trazas: Tempo tiene spans recientes' {
    $resp = Get-Kube -n observability exec deploy/tempo -- wget -qO- "http://localhost:3100/api/search?tags=&limit=1"
    $j = $resp | ConvertFrom-Json
    if (@($j.traces).Count -eq 0) { throw 'sin trazas en Tempo todavia (generar trafico y reintentar)' }
    "al menos 1 traza encontrada"
}

Check 'Entrega progresiva: Rollout del gateway sano' {
    $ro = Get-Kube -n $Namespace get rollout gateway -o json | ConvertFrom-Json
    if ($ro.status.phase -ne 'Healthy') { throw "fase $($ro.status.phase)" }
    "fase Healthy"
}

Check 'Politicas de admision: Kyverno sigue bloqueando imagenes :latest' {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $out = (& kubectl -n $Namespace run p10-kyverno-test --image=nginx:latest --dry-run=server -o name 2>&1 | ForEach-Object { "$_" }) -join ' '
    $rc = $LASTEXITCODE
    $ErrorActionPreference = $prev
    if ($rc -eq 0) { throw 'el pod con :latest fue ADMITIDO' }
    if ($out -notmatch 'p8-') { throw "rechazo inesperado: $out" }
    'admision rechazada por p8-*'
}

Check 'Servicio: gateway responde (via port-forward, sin LoadBalancer)' {
    $p = Start-PortForward -Namespace $Namespace -Service gateway -LocalPort 18080 -RemotePort 3000
    try {
        $body = $null
        Wait-Until -What 'gateway /health' -TimeoutSeconds 60 -IntervalSeconds 3 -Condition {
            $script:body = (Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:18080/health' -TimeoutSec 5).Content
            $script:body -match '"status":"ok"'
        }
        "http://127.0.0.1:18080/health -> $body"
    } finally { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
}

if ($fails.Count) { Mark "verificar: RESULTADO = $($fails.Count) control(es) con FALLO: $($fails -join ' | ')"; exit 1 }
Mark 'verificar: RESULTADO = todos los controles PASS'
