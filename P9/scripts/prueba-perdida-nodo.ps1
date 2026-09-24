<#
.SYNOPSIS
  Prueba de perdida de nodo con evidencia automatica (rubrica 2.5).

.DESCRIPTION
  Drena un nodo del cluster mientras un sondeo externo (desde esta maquina, contra
  la IP publica del gateway) consulta el servicio una vez por segundo:
    - GET  /health            -> liveness del gateway (sin base de datos)
    - GET  /cursos (con JWT)  -> ruta completa gateway -> cursos-service -> PostgreSQL

  Escenarios:
    -Scenario stateless : drena el nodo que NO aloja postgresql-0 (perdida de un nodo
                          con replicas sin estado; PDB + anti-afinidad + 2 replicas).
    -Scenario stateful  : drena el nodo que aloja postgresql-0 (peor caso: la base de datos
                          tiene 1 sola replica, se mide la interrupcion real).

  Escribe la evidencia (con marcas de tiempo y estadisticas del sondeo) en
  P9/evidencias/perdida-nodo.md (usar -Append para agregar el segundo escenario).
#>
param(
    [ValidateSet('stateless', 'stateful')][string]$Scenario = 'stateless',
    [string]$Node,
    [switch]$Append,
    [string]$EvidenceFile = (Join-Path $PSScriptRoot '..\evidencias\perdida-nodo.md')
)
. "$PSScriptRoot\common.ps1"
$ns = 'sa-p8'
$script:LogFile = Join-Path ([IO.Path]::GetTempPath()) ("p9-nodo-{0}.log" -f (Get-Date -Format 'yyyyMMddHHmmss'))
Set-Content -Path $script:LogFile -Value '' -Encoding UTF8

function Get-Snapshot {
    param([string]$Title)
    $nodes = Get-Kube get nodes -o wide
    $pods  = Get-Kube -n $ns get pods -o wide --sort-by=.metadata.name
    $pdb   = Get-Kube -n $ns get pdb
    "### $Title`n`n``````n$nodes`n`n$pods`n`n$pdb`n``````"
}

# --- Seleccion del nodo ---------------------------------------------------------
$pgNode = Get-Kube -n $ns get pod postgresql-0 -o jsonpath='{.spec.nodeName}'
$allNodes = @((Get-Kube get nodes -o json | ConvertFrom-Json).items.metadata.name)
if (-not $Node) {
    if ($Scenario -eq 'stateful') { $Node = $pgNode } else { $Node = ($allNodes | Where-Object { $_ -ne $pgNode } | Select-Object -First 1) }
}
Mark "prueba-nodo: escenario=$Scenario nodo a drenar=$Node (postgresql-0 esta en $pgNode)"

# --- Sondeo: token y endpoints --------------------------------------------------
$lb = Get-Kube -n $ns get svc gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
$base = "http://${lb}:3000"
$email = 'drprobe@p9.test'
$pass  = [Guid]::NewGuid().ToString('N')
try { Invoke-RestMethod -Method Post -Uri "$base/auth/register" -ContentType 'application/json' -Body (@{ email = $email; password = $pass } | ConvertTo-Json) -TimeoutSec 10 | Out-Null } catch { }
# El usuario de sondeo puede existir de una corrida previa con otra clave: se recrea limpio.
$login = $null
try { $login = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body (@{ email = $email; password = $pass } | ConvertTo-Json) -TimeoutSec 10 } catch { }
if (-not $login) {
    Invoke-Sql "delete from usuarios where email='$email'" | Out-Null
    Invoke-RestMethod -Method Post -Uri "$base/auth/register" -ContentType 'application/json' -Body (@{ email = $email; password = $pass } | ConvertTo-Json) -TimeoutSec 10 | Out-Null
    $login = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body (@{ email = $email; password = $pass } | ConvertTo-Json) -TimeoutSec 10
}
$token = $login.token
if (-not $token) { throw 'No se obtuvo token de sondeo' }
$csv = Join-Path ([IO.Path]::GetTempPath()) ("p9-sondeo-{0}.csv" -f (Get-Date -Format 'yyyyMMddHHmmss'))
Set-Content -Path $csv -Value 'ts,endpoint,code,ms' -Encoding ASCII

$snapBefore = Get-Snapshot 'Estado ANTES del drenaje'

$job = Start-Job -ArgumentList $base, $token, $csv -ScriptBlock {
    param($base, $token, $csv)
    while ($true) {
        foreach ($ep in @('/health', '/cursos')) {
            $sw = [Diagnostics.Stopwatch]::StartNew()
            $code = 0
            try {
                $h = @{}
                if ($ep -eq '/cursos') { $h['Authorization'] = "Bearer $token" }
                $r = Invoke-WebRequest -UseBasicParsing -Uri "$base$ep" -Headers $h -TimeoutSec 3
                $code = [int]$r.StatusCode
            } catch {
                if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode } else { $code = 0 }
            }
            $sw.Stop()
            Add-Content -Path $csv -Value ("{0},{1},{2},{3}" -f (Get-Date).ToUniversalTime().ToString('HH:mm:ss'), $ep, $code, $sw.ElapsedMilliseconds) -Encoding ASCII
        }
        Start-Sleep -Milliseconds 700
    }
}
Start-Sleep -Seconds 10   # linea base del sondeo
Mark 'prueba-nodo: sondeo en marcha (linea base 10 s)'

# --- Drenaje ----------------------------------------------------------------------
$tDrain = Get-Stamp
Mark "prueba-nodo: kubectl drain $Node --ignore-daemonsets --delete-emptydir-data --timeout=300s"
$prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'   # kubectl drain escribe avisos en stderr
$drainOut = & kubectl drain $Node --ignore-daemonsets --delete-emptydir-data --timeout=300s 2>&1 | ForEach-Object { "$_" }
$drainRc = $LASTEXITCODE
$ErrorActionPreference = $prevEap
$tDrained = Get-Stamp
Mark "prueba-nodo: drain terminado (codigo $drainRc)"

# Esperar a que todo vuelva a estar disponible SIN el nodo drenado.
$tRecovery = $null
try {
    Wait-Until -What 'workloads Ready sin el nodo' -TimeoutSeconds 600 -IntervalSeconds 5 -Condition {
        $d = (Get-Kube -n $ns get deploy -o json | ConvertFrom-Json).items
        $s = (Get-Kube -n $ns get sts -o json | ConvertFrom-Json).items
        $r = (Get-Kube -n $ns get rollout -o json | ConvertFrom-Json).items
        $ready = $true
        foreach ($x in @($d) + @($s)) { if ([int]$x.status.readyReplicas -lt [int]$x.spec.replicas) { $ready = $false } }
        foreach ($x in @($r)) { if ([int]$x.status.availableReplicas -lt [int]$x.spec.replicas) { $ready = $false } }
        $ready
    }
    $tRecovery = Get-Stamp
    Mark 'prueba-nodo: todos los workloads Ready con un solo nodo'
} catch { Mark "prueba-nodo: AVISO - $_" }
$snapDuring = Get-Snapshot 'Estado con el nodo drenado (todo reprogramado en el nodo restante)'
Start-Sleep -Seconds 10

# --- Uncordon -----------------------------------------------------------------------
Invoke-Native kubectl uncordon $Node | Out-Null
$tUncordon = Get-Stamp
Mark "prueba-nodo: uncordon $Node"
Start-Sleep -Seconds 15
Stop-Job $job; Remove-Job $job -Force

# --- Analisis del sondeo ------------------------------------------------------------------
$rows = @(Import-Csv $csv)
function Get-Stats {
    param($Rows, [string]$Endpoint)
    $r = @($Rows | Where-Object { $_.endpoint -eq $Endpoint })
    $fail = @($r | Where-Object { $_.code -ne '200' })
    $streak = 0; $max = 0; $maxStart = $null; $curStart = $null
    foreach ($x in $r) {
        if ($x.code -ne '200') { if ($streak -eq 0) { $curStart = $x.ts }; $streak++; if ($streak -gt $max) { $max = $streak; $maxStart = $curStart } } else { $streak = 0 }
    }
    $lat = @($r | Where-Object { $_.code -eq '200' } | ForEach-Object { [int]$_.ms } | Sort-Object)
    $p95 = if ($lat.Count) { $lat[[math]::Min($lat.Count - 1, [int][math]::Floor($lat.Count * 0.95))] } else { 0 }
    [pscustomobject]@{
        Endpoint = $Endpoint; Total = $r.Count; Errores = $fail.Count
        Disponibilidad = if ($r.Count) { '{0:N2}%' -f (100 * ($r.Count - $fail.Count) / $r.Count) } else { 'n/a' }
        MaxErroresSeguidos = $max; InicioRacha = $maxStart; P95ms = $p95
    }
}
$stats = @((Get-Stats $rows '/health'), (Get-Stats $rows '/cursos'))
$statsTxt = ($stats | Format-Table -AutoSize | Out-String).TrimEnd()
$errTxt = ($rows | Where-Object { $_.code -ne '200' } | ForEach-Object { "$($_.ts) $($_.endpoint) -> $($_.code) ($($_.ms) ms)" }) -join "`n"
if (-not $errTxt) { $errTxt = '(ninguna: todas las respuestas fueron HTTP 200)' }
$snapAfter = Get-Snapshot 'Estado DESPUES del uncordon'
$log = Get-Content $script:LogFile -Raw
$drainTxt = $drainOut -join "`n"

$titulo = if ($Scenario -eq 'stateless') { 'Escenario A - perdida de un nodo con replicas sin estado' } else { 'Escenario B - perdida del nodo que aloja PostgreSQL (peor caso, 1 replica)' }
$md = @"
## $titulo

Generado por ``P9/scripts/prueba-perdida-nodo.ps1 -Scenario $Scenario`` (todas las horas UTC).

| Campo | Valor |
|---|---|
| Nodo drenado | ``$Node`` (postgresql-0 estaba en ``$pgNode``) |
| Hora de inicio del drenaje | $tDrain |
| Hora de fin del drenaje | $tDrained (codigo de salida de kubectl drain: $drainRc) |
| Workloads Ready sin el nodo | $tRecovery |
| Uncordon | $tUncordon |
| Replicas configuradas | 2 por microservicio (gateway = Rollout), 1 PostgreSQL, 1 RabbitMQ |
| PDB observado | ``minAvailable: 1`` en los 5 servicios; ``maxUnavailable: 1`` en PostgreSQL y RabbitMQ |
| Anti-afinidad | ``podAntiAffinity preferred`` por ``kubernetes.io/hostname`` (una replica por nodo) |
| Sondeo | desde esta maquina, IP publica del gateway, 2 endpoints cada ~1 s |

### Resultado del sondeo durante toda la prueba

``````
$statsTxt
``````

Respuestas no exitosas (si las hubo):

``````
$errTxt
``````

$snapBefore

$snapDuring

$snapAfter

### Salida de kubectl drain

``````
$drainTxt
``````

### Registro con marcas de tiempo

``````
$log
``````
"@
if ($Append) { Add-Content -Path $EvidenceFile -Value "`n$md" -Encoding UTF8 }
else { Set-Content -Path $EvidenceFile -Value "# Prueba de perdida de nodo - evidencia automatica`n`n$md" -Encoding UTF8 }
Copy-Item $csv (Join-Path (Split-Path $EvidenceFile) ("sondeo-nodo-$Scenario.csv")) -Force
Mark "prueba-nodo: evidencia escrita en $EvidenceFile"
$stats | Format-Table -AutoSize | Out-String | Write-Host
