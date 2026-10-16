<#
.SYNOPSIS
  Genera trafico real (login + consulta de cursos) contra el gateway via
  port-forward, para que haya metricas/trazas/logs que medir. Se usa como
  "ruido de fondo" antes y durante las pruebas de fallo inducido.
#>
param(
    [int]$DurationSeconds = 60,
    [int]$RequestsPerSecond = 3,
    [string]$Namespace = 'sa-p8'
)
. "$PSScriptRoot\common.ps1"

$lb = Start-PortForward -Namespace $Namespace -Service gateway -LocalPort 18080 -RemotePort 3000
try {
    $base = 'http://127.0.0.1:18080'
    $email = "trafico-$([Guid]::NewGuid().ToString('N').Substring(0,8))@p10.test"
    $pass = 'p10-trafico-123'
    try { Invoke-RestMethod -Method Post -Uri "$base/auth/register" -ContentType 'application/json' -Body (@{ email = $email; password = $pass } | ConvertTo-Json) -TimeoutSec 5 | Out-Null } catch { }
    $token = $null
    try { $token = (Invoke-RestMethod -Method Post -Uri "$base/auth/login" -ContentType 'application/json' -Body (@{ email = $email; password = $pass } | ConvertTo-Json) -TimeoutSec 5).token } catch { }

    $deadline = (Get-Date).AddSeconds($DurationSeconds)
    $ok = 0; $err = 0
    while ((Get-Date) -lt $deadline) {
        foreach ($i in 1..$RequestsPerSecond) {
            try {
                Invoke-WebRequest -UseBasicParsing -Uri "$base/auth/login" -Method Post -ContentType 'application/json' -Body (@{ email = $email; password = $pass } | ConvertTo-Json) -TimeoutSec 5 | Out-Null
                $ok++
            } catch { $err++ }
            try {
                $h = if ($token) { @{ Authorization = "Bearer $token" } } else { @{} }
                Invoke-WebRequest -UseBasicParsing -Uri "$base/cursos" -Headers $h -TimeoutSec 5 | Out-Null
                $ok++
            } catch { $err++ }
        }
        Start-Sleep -Milliseconds 800
    }
    Mark "generar-trafico: $ok peticiones exitosas, $err con error, en ${DurationSeconds}s"
} finally { Stop-Process -Id $lb.Id -Force -ErrorAction SilentlyContinue }
