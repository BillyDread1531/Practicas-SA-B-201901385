# Utilidades compartidas por los scripts de P9 (se importan con: . "$PSScriptRoot\common.ps1")
$ErrorActionPreference = 'Stop'

function Get-Stamp { (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'Z'") }

# Escribe una marca de tiempo en pantalla y, si $script:LogFile existe, en el registro.
function Mark {
    param([Parameter(Mandatory)][string]$Message)
    $line = "{0} | {1}" -f (Get-Stamp), $Message
    Write-Host $line
    if ($script:LogFile) { Add-Content -Path $script:LogFile -Value $line -Encoding UTF8 }
}

# Ejecuta un comando nativo y falla si el codigo de salida no es 0.
# (funcion simple con $args: una funcion "avanzada" interpretaria -n / -o como parametros comunes)
function Invoke-Native {
    $exe = $args[0]; $rest = @($args | Select-Object -Skip 1)
    & $exe @rest
    if ($LASTEXITCODE -ne 0) { throw "Fallo: $exe $($rest -join ' ') (codigo $LASTEXITCODE)" }
}

# kubectl que devuelve la salida como texto y falla si hay error.
function Get-Kube {
    $out = & kubectl @args
    if ($LASTEXITCODE -ne 0) { throw "kubectl $($args -join ' ') fallo (codigo $LASTEXITCODE)" }
    ($out -join "`n")
}

# kubectl tolerante: devuelve $null si el recurso no existe / hay error.
function Get-KubeOrNull {
    $out = & kubectl @args 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    ($out -join "`n")
}

# Aplica un patch merge a un recurso (via archivo: evita el problema de comillas de PowerShell 5.1).
function Set-KubePatch {
    param([string]$Namespace, [string]$Kind, [string]$Name, [string]$Json)
    $tmp = [IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllText($tmp, $Json, (New-Object Text.UTF8Encoding $false))
        Invoke-Native kubectl -n $Namespace patch $Kind $Name --type merge --patch-file $tmp | Out-Null
    } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
}

# Consulta SQL en PostgreSQL dentro del pod (la clave se lee del volumen de secretos del pod: nunca se imprime).
function Invoke-Sql {
    param([Parameter(Mandatory)][string]$Sql, [string]$Namespace = 'sa-p8', [string]$Pod = 'postgresql-0')
    # El SQL viaja por stdin: evita el mal manejo de comillas dobles de PowerShell 5.1 con ejecutables nativos.
    $cmd = 'export PGPASSWORD=$(cat /opt/bitnami/postgresql/secrets/postgres-password); psql -U postgres -d academia -v ON_ERROR_STOP=1 -At'
    $out = $Sql | & kubectl -n $Namespace exec -i $Pod -c postgresql -- bash -c $cmd
    if ($LASTEXITCODE -ne 0) { throw "psql fallo: $Sql" }
    ($out -join "`n")
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
