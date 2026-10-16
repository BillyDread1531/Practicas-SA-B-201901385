# Utilidades compartidas por los scripts de P10 (se importan con: . "$PSScriptRoot\common.ps1")
$ErrorActionPreference = 'Stop'

function Get-Stamp { (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'Z'") }

function Mark {
    param([Parameter(Mandatory)][string]$Message)
    $line = "{0} | {1}" -f (Get-Stamp), $Message
    Write-Host $line
    if ($script:LogFile) { Add-Content -Path $script:LogFile -Value $line -Encoding UTF8 }
}

# Funcion simple con $args (no "advanced function"): evita que PowerShell
# interprete -n / -o como parametros comunes al pasarselos a kubectl.
function Invoke-Native {
    $exe = $args[0]; $rest = @($args | Select-Object -Skip 1)
    & $exe @rest
    if ($LASTEXITCODE -ne 0) { throw "Fallo: $exe $($rest -join ' ') (codigo $LASTEXITCODE)" }
}

function Get-Kube {
    $out = & kubectl @args
    if ($LASTEXITCODE -ne 0) { throw "kubectl $($args -join ' ') fallo (codigo $LASTEXITCODE)" }
    ($out -join "`n")
}

function Get-KubeOrNull {
    $out = & kubectl @args 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    ($out -join "`n")
}

function Set-KubePatch {
    param([string]$Namespace, [string]$Kind, [string]$Name, [string]$Json)
    $tmp = [IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllText($tmp, $Json, (New-Object Text.UTF8Encoding $false))
        Invoke-Native kubectl -n $Namespace patch $Kind $Name --type merge --patch-file $tmp | Out-Null
    } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
}

function Wait-Until {
    param([Parameter(Mandatory)][scriptblock]$Condition, [int]$TimeoutSeconds = 600, [int]$IntervalSeconds = 10, [string]$What = 'condicion')
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try { if (& $Condition) { return } } catch { }
        Start-Sleep -Seconds $IntervalSeconds
    }
    throw "Tiempo agotado esperando: $What ($TimeoutSeconds s)"
}

# Puerto local reenviado hacia el servicio (sin LoadBalancer: asi no se crea
# ninguna IP publica ni Load Balancer en Azure, que es lo que cuesta dinero).
function Start-PortForward {
    param([string]$Namespace, [string]$Service, [int]$LocalPort, [int]$RemotePort)
    $p = Start-Process -FilePath kubectl -ArgumentList @('-n', $Namespace, 'port-forward', "svc/$Service", "${LocalPort}:${RemotePort}") -PassThru -WindowStyle Hidden -RedirectStandardOutput ([IO.Path]::GetTempFileName()) -RedirectStandardError ([IO.Path]::GetTempFileName())
    Start-Sleep -Seconds 3
    if ($p.HasExited) { throw "port-forward a $Service no pudo iniciar" }
    return $p
}
