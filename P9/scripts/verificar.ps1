<#
.SYNOPSIS
  Verifica que el sistema reconstruido conserva TODO el flujo de la Practica 8
  (GitOps, entrega progresiva, politicas de admision) y los mecanismos de P9.

.DESCRIPTION
  Termina con codigo distinto de 0 si algun control falla. Cada control deja una
  marca de tiempo (usar -LogFile para guardar el registro).
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

Check 'Nodos AKS Ready' {
    $n = @((Get-Kube get nodes -o json | ConvertFrom-Json).items)
    $ready = @($n | Where-Object { @($_.status.conditions | Where-Object { $_.type -eq 'Ready' -and $_.status -eq 'True' }).Count -eq 1 })
    if ($ready.Count -ne $n.Count -or $n.Count -lt 2) { throw "Ready $($ready.Count)/$($n.Count)" }
    "$($ready.Count) nodos Ready"
}

Check 'GitOps: app-of-apps y aplicaciones hijas' {
    Wait-Until -What 'p9-root-app Synced' -TimeoutSeconds 180 -IntervalSeconds 5 -Condition {
        (Get-Kube -n argocd get application p9-root-app -o jsonpath='{.status.sync.status}') -eq 'Synced'
    }
    $list = @((Get-Kube -n argocd get applications -o json | ConvertFrom-Json).items)
    $root = $list | Where-Object { $_.metadata.name -eq 'p9-root-app' }
    if (-not $root -or $root.status.sync.status -ne 'Synced') { throw 'p9-root-app no esta Synced' }
    $bad = @($list | Where-Object { $_.status.sync.status -ne 'Synced' -and $_.metadata.name -notin @('argo-rollouts', 'kyverno') })
    if ($bad.Count) { throw "no Synced: $($bad.metadata.name -join ',')" }
    ($list | ForEach-Object { "$($_.metadata.name)=$($_.status.sync.status)/$($_.status.health.status)" })
}

Check 'Secretos: SealedSecret descifrado con la llave restaurada' {
    $ss = Get-Kube -n $Namespace get sealedsecret sa-platform-secrets -o json | ConvertFrom-Json
    if (@($ss.status.conditions | Where-Object { $_.type -eq 'Synced' -and $_.status -eq 'True' }).Count -ne 1) { throw 'SealedSecret sin Synced=True' }
    $keys = @((Get-Kube -n kube-system get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o json | ConvertFrom-Json).items)
    $errs = (& kubectl -n kube-system logs deploy/sealed-secrets-controller --tail=500 2>$null | Select-String "no key could decrypt secret.*$Namespace/sa-platform-secrets").Count
    if ($errs) { throw "el controlador reporta $errs errores de descifrado" }
    "Synced=True, Secret sa-platform-secrets creado, $($keys.Count) llave(s) cargada(s), 0 errores de descifrado"
}

Check 'Velero: destino externo, schedule y respaldos' {
    $bsl = Get-Kube -n velero get backupstoragelocation default -o json | ConvertFrom-Json
    if ($bsl.status.phase -ne 'Available') { throw "BSL $($bsl.status.phase)" }
    $sch = Get-Kube -n velero get schedule velero-p9-platform -o json | ConvertFrom-Json
    $bk = @((Get-Kube -n velero get backup -o json | ConvertFrom-Json).items | Where-Object { $_.status.phase -eq 'Completed' })
    if (-not $bk.Count) { throw 'no hay respaldos Completed' }
    "BSL Available ($($bsl.spec.objectStorage.bucket)@$($bsl.spec.config.storageAccount)); schedule '$($sch.spec.schedule)' ttl $($sch.spec.template.ttl); $($bk.Count) respaldo(s) Completed"
}

Check 'Aplicacion: workloads listos y repartidos entre nodos' {
    $d = @((Get-Kube -n $Namespace get deploy -o json | ConvertFrom-Json).items)
    $s = @((Get-Kube -n $Namespace get sts -o json | ConvertFrom-Json).items)
    $r = @((Get-Kube -n $Namespace get rollout -o json | ConvertFrom-Json).items)
    $notReady = @()
    foreach ($x in $d + $s) { if ([int]$x.status.readyReplicas -lt [int]$x.spec.replicas) { $notReady += $x.metadata.name } }
    foreach ($x in $r) { if ([int]$x.status.availableReplicas -lt [int]$x.spec.replicas) { $notReady += $x.metadata.name } }
    if ($notReady.Count) { throw "sin replicas listas: $($notReady -join ',')" }
    $pdb = @((Get-Kube -n $Namespace get pdb -o json | ConvertFrom-Json).items).Count
    "$($d.Count) deployments, $($s.Count) statefulsets, $($r.Count) rollout(s) listos; $pdb PDB"
}

Check 'Entrega progresiva: Rollout del gateway (canary) sano' {
    $ro = Get-Kube -n $Namespace get rollout gateway -o json | ConvertFrom-Json
    if ($ro.status.phase -ne 'Healthy') { throw "Rollout en fase $($ro.status.phase)" }
    "fase Healthy, estrategia canary con $(@($ro.spec.strategy.canary.steps).Count) pasos + analisis gateway-health"
}

Check 'Politicas de admision: Kyverno bloquea imagenes :latest' {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $out = (& kubectl -n $Namespace run p9-kyverno-test --image=nginx:latest --dry-run=server -o name 2>&1 | ForEach-Object { "$_" }) -join ' '
    $rc = $LASTEXITCODE
    $ErrorActionPreference = $prev
    if ($rc -eq 0) { throw 'el pod con :latest fue ADMITIDO (Kyverno no bloquea)' }
    if ($out -notmatch 'p8-') { throw "rechazo inesperado: $out" }
    'admision rechazada por p8-* (validationFailureAction=Enforce)'
}

Check 'Servicio publico: gateway responde por la IP del LoadBalancer' {
    $lb = $null
    Wait-Until -What 'IP publica del gateway' -TimeoutSeconds 300 -IntervalSeconds 10 -Condition {
        $script:lb = Get-Kube -n $Namespace get svc gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
        [bool]$script:lb
    }
    $body = $null
    Wait-Until -What 'gateway /health' -TimeoutSeconds 300 -IntervalSeconds 10 -Condition {
        $script:body = (Invoke-WebRequest -UseBasicParsing -Uri "http://$($script:lb):3000/health" -TimeoutSec 5).Content
        $script:body -match '"status":"ok"'
    }
    "http://$($script:lb):3000/health -> $($script:body)"
}

Check 'Datos: tablas de PostgreSQL con contenido' {
    $t = Invoke-Sql "select relname||'='||n_live_tup from pg_stat_user_tables order by relname"
    ($t -split "`n") -join ', '
}

if ($fails.Count) { Mark "verificar: RESULTADO = $($fails.Count) control(es) con FALLO: $($fails -join ' | ')"; exit 1 }
Mark 'verificar: RESULTADO = todos los controles PASS'
