<#
.SYNOPSIS
  Genera trafico real (login + consulta de cursos) contra el gateway, para
  que haya metricas/trazas/logs que medir. Se usa como "ruido de fondo"
  antes y durante las pruebas de fallo inducido.

.DESCRIPTION
  Por defecto via port-forward (localhost -> svc/gateway). OJO: un solo
  "kubectl port-forward svc/X" fija la conexion a UN pod concreto durante
  toda su vida (no reequilibra si el Service gana/pierde endpoints), asi
  que para medir el canary del gateway (donde el trafico debe repartirse
  de verdad entre pods estables y canary) se usa -InCluster: un Pod
  efimero que pega contra "http://gateway.<ns>.svc.cluster.local:3000"
  desde DENTRO del cluster, donde kube-proxy si balancea por conexion
  entre todos los endpoints reales del Service.
#>
param(
    [int]$DurationSeconds = 60,
    [int]$RequestsPerSecond = 3,
    [string]$Namespace = 'sa-p8',
    [switch]$InCluster
)
. "$PSScriptRoot\common.ps1"

if ($InCluster) {
    $podName = "p10-trafico-{0}" -f ([Guid]::NewGuid().ToString('N').Substring(0, 8))
    $url = "http://gateway.$Namespace.svc.cluster.local:3000"
    # JSON con comillas simples alrededor y la variable intercalada entre
    # comillas dobles (truco clasico de shell: cierra simples, interpola,
    # reabre simples) para no necesitar NINGUNA comilla escapada con \ en
    # este script: eso simplifica mucho el escape posterior hacia YAML.
    $script = @"
set -e
EMAIL=trafico-`$(head -c4 /dev/urandom | od -An -tx1 | tr -d ' \n')@p10.test
BODY='{"email":"'"`$EMAIL"'","password":"p10-trafico-123"}'
curl -s -o /dev/null -X POST $url/auth/register -H 'Content-Type: application/json' -d "`$BODY" || true
TOKEN=`$(curl -s -X POST $url/auth/login -H 'Content-Type: application/json' -d "`$BODY" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
END=`$(( `$(date +%s) + $DurationSeconds ))
: > /tmp/codes.txt
while [ `$(date +%s) -lt `$END ]; do
  i=0
  while [ `$i -lt $RequestsPerSecond ]; do
    curl -s -o /dev/null -w '%{http_code}\n' -X POST $url/auth/login -H 'Content-Type: application/json' -d "`$BODY" >> /tmp/codes.txt || true
    curl -s -o /dev/null -w '%{http_code}\n' $url/cursos -H "Authorization: Bearer `$TOKEN" >> /tmp/codes.txt || true
    i=`$((i+1))
  done
  sleep 0.8
done
OK=`$(grep -c '^2' /tmp/codes.txt || true)
ERR=`$(grep -vc '^2' /tmp/codes.txt || true)
echo "generar-trafico(in-cluster): `$OK peticiones exitosas, `$ERR con error, en ${DurationSeconds}s"
"@
    # Orden critico: primero normalizar saltos de linea, luego escapar las
    # barras invertidas YA presentes en el script (sed usa \(, \), \1), y
    # SOLO DESPUES escapar las comillas dobles y convertir los saltos de
    # linea restantes a la secuencia literal \n. Si se escaparan las
    # comillas antes que las barras invertidas, las barras que la propia
    # escapada de comillas introduce se duplicarian por error.
    $escaped = $script -replace "`r`n", "`n"
    $escaped = $escaped -replace '\\', '\\'
    $escaped = $escaped -replace '"', '\"'
    $escaped = $escaped -replace "`n", '\n'
    $manifest = @"
apiVersion: v1
kind: Pod
metadata:
  name: $podName
  namespace: $Namespace
  labels:
    app: p10-trafico
spec:
  restartPolicy: Never
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: trafico
      image: curlimages/curl:8.10.1
      command: ["/bin/sh", "-c", "$escaped"]
      securityContext:
        runAsNonRoot: true
        # curlimages/curl declara su USER como "curl_user" (no numerico):
        # sin un UID explicito, el kubelet no puede verificar runAsNonRoot
        # y el Pod queda en CreateContainerConfigError. UID 100 es el que
        # trae esa imagen (curl_user:curl_group, 100:100).
        runAsUser: 100
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: false
        capabilities:
          drop: ["ALL"]
      resources:
        requests: { cpu: 20m, memory: 32Mi }
        limits: { cpu: 200m, memory: 64Mi }
"@
    $tmp = [IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllText($tmp, $manifest, (New-Object Text.UTF8Encoding $false))
        Invoke-Native kubectl apply -f $tmp | Out-Null
        Wait-Until -What "pod $podName termina" -TimeoutSeconds ($DurationSeconds + 60) -IntervalSeconds 5 -Condition {
            $phase = Get-KubeOrNull -n $Namespace get pod $podName -o jsonpath='{.status.phase}'
            $phase -in @('Succeeded', 'Failed')
        }
        $logs = Get-Kube -n $Namespace logs $podName
        Mark ($logs -split "`n" | Where-Object { $_ -match 'generar-trafico' } | Select-Object -Last 1)
    } finally {
        Invoke-Native kubectl -n $Namespace delete pod $podName --ignore-not-found --wait=false | Out-Null
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
    return
}

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
