# Prueba de perdida de nodo - evidencia automatica

## Escenario A - perdida de un nodo con replicas sin estado

Generado por `P9/scripts/prueba-perdida-nodo.ps1 -Scenario stateless` (todas las horas UTC).

| Campo | Valor |
|---|---|
| Nodo drenado | `aks-system-35358252-vmss000001` (postgresql-0 estaba en `aks-system-35358252-vmss000000`) |
| Hora de inicio del drenaje | 2026-09-24T07:35:40Z |
| Hora de fin del drenaje | 2026-09-24T07:37:13Z (codigo de salida de kubectl drain: 0) |
| Workloads Ready sin el nodo |  |
| Uncordon | 2026-09-24T07:47:29Z |
| Replicas configuradas | 2 por microservicio (gateway = Rollout), 1 PostgreSQL, 1 RabbitMQ |
| PDB observado | `minAvailable: 1` en los 5 servicios; `maxUnavailable: 1` en PostgreSQL y RabbitMQ |
| Anti-afinidad | `podAntiAffinity preferred` por `kubernetes.io/hostname` (una replica por nodo) |
| Sondeo | desde esta maquina, IP publica del gateway, 2 endpoints cada ~1 s |

### Resultado del sondeo durante toda la prueba

```

Endpoint Total Errores Disponibilidad MaxErroresSeguidos InicioRacha P95ms
-------- ----- ------- -------------- ------------------ ----------- -----
/health    882       0 100.00%                         0                63
/cursos    882       0 100.00%                         0                65
```

Respuestas no exitosas (si las hubo):

```
(ninguna: todas las respuestas fueron HTTP 200)
```

### Estado ANTES del drenaje

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-35358252-vmss000000   Ready    <none>   23h   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-35358252-vmss000001   Ready    <none>   23h   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS      AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-65f7d68b6c-4bvcj            1/1     Running     0             23h     10.244.1.237   aks-system-35358252-vmss000000   <none>           <none>
auth-service-65f7d68b6c-xqjlf            1/1     Running     0             23h     10.244.0.87    aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837250-47bmm               0/1     Error       0             5m17s   10.244.0.184   aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837250-4hw2x               0/1     Error       0             5m29s   10.244.0.172   aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837250-8gsdl               0/1     Completed   0             4m56s   10.244.0.63    aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837252-4tng4               0/1     Completed   0             3m29s   10.244.0.165   aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837254-4t4sg               0/1     Completed   0             89s     10.244.0.124   aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-29837220-gzrl9              0/1     Completed   0             27m     10.244.1.17    aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837230-hqrwt              0/1     Completed   0             25m     10.244.1.106   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837240-jr7f9              0/1     Completed   0             15m     10.244.1.169   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837250-89s2q              0/1     Error       0             5m16s   10.244.1.224   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837250-m2s74              0/1     Error       0             4m53s   10.244.1.142   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837250-swqr8              0/1     Error       0             5m29s   10.244.0.0     aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-consumer-867478f48f-m95z7   1/1     Running     0             14m     10.244.1.101   aks-system-35358252-vmss000000   <none>           <none>
cursos-service-5c5549d45f-rkmhc          1/1     Running     0             23h     10.244.1.220   aks-system-35358252-vmss000000   <none>           <none>
cursos-service-5c5549d45f-wsdpf          1/1     Running     0             23h     10.244.0.241   aks-system-35358252-vmss000001   <none>           <none>
estudiantes-service-84b9cb69bc-2nzd6     1/1     Running     0             23h     10.244.0.168   aks-system-35358252-vmss000001   <none>           <none>
estudiantes-service-84b9cb69bc-p6rng     1/1     Running     0             23h     10.244.1.227   aks-system-35358252-vmss000000   <none>           <none>
gateway-8955dc9-5msx9                    1/1     Running     0             23h     10.244.1.64    aks-system-35358252-vmss000000   <none>           <none>
gateway-8955dc9-b4jbk                    1/1     Running     0             23h     10.244.0.112   aks-system-35358252-vmss000001   <none>           <none>
inscripciones-consumer-8b9c9bb65-r27xt   1/1     Running     1 (23h ago)   23h     10.244.0.188   aks-system-35358252-vmss000001   <none>           <none>
inscripciones-service-7f4b8b4899-f9qb2   1/1     Running     0             23h     10.244.1.200   aks-system-35358252-vmss000000   <none>           <none>
inscripciones-service-7f4b8b4899-gg8ng   1/1     Running     0             23h     10.244.0.218   aks-system-35358252-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0             2m59s   10.244.1.3     aks-system-35358252-vmss000000   <none>           <none>
rabbitmq-0                               1/1     Running     0             2m58s   10.244.1.1     aks-system-35358252-vmss000000   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     23h
cursos-service          1               N/A               1                     23h
estudiantes-service     1               N/A               1                     23h
gateway                 1               N/A               1                     23h
inscripciones-service   1               N/A               1                     23h
postgresql              N/A             1                 1                     23h
rabbitmq                N/A             1                 1                     23h
```

### Estado con el nodo drenado (todo reprogramado en el nodo restante)

```nNAME                             STATUS                     ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-35358252-vmss000000   Ready                      <none>   23h   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-35358252-vmss000001   Ready,SchedulingDisabled   <none>   23h   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS   AGE   IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-65f7d68b6c-4bvcj            1/1     Running     0          23h   10.244.1.237   aks-system-35358252-vmss000000   <none>           <none>
auth-service-65f7d68b6c-4frx6            0/1     Pending     0          10m   <none>         <none>                           <none>           <none>
cron-insert-29837256-cb5z2               0/1     Completed   0          10m   10.244.1.139   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837220-gzrl9              0/1     Completed   0          39m   10.244.1.17    aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837230-hqrwt              0/1     Completed   0          37m   10.244.1.106   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837240-jr7f9              0/1     Completed   0          27m   10.244.1.169   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837250-89s2q              0/1     Error       0          17m   10.244.1.224   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837250-m2s74              0/1     Error       0          16m   10.244.1.142   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-consumer-867478f48f-m95z7   1/1     Running     0          26m   10.244.1.101   aks-system-35358252-vmss000000   <none>           <none>
cursos-service-5c5549d45f-4tk54          0/1     Pending     0          10m   <none>         <none>                           <none>           <none>
cursos-service-5c5549d45f-rkmhc          1/1     Running     0          23h   10.244.1.220   aks-system-35358252-vmss000000   <none>           <none>
estudiantes-service-84b9cb69bc-p6rng     1/1     Running     0          23h   10.244.1.227   aks-system-35358252-vmss000000   <none>           <none>
estudiantes-service-84b9cb69bc-qlz86     0/1     Pending     0          10m   <none>         <none>                           <none>           <none>
gateway-8955dc9-5msx9                    1/1     Running     0          23h   10.244.1.64    aks-system-35358252-vmss000000   <none>           <none>
gateway-8955dc9-rntnj                    0/1     Pending     0          10m   <none>         <none>                           <none>           <none>
inscripciones-consumer-8b9c9bb65-wsdhz   0/1     Pending     0          10m   <none>         <none>                           <none>           <none>
inscripciones-service-7f4b8b4899-f9qb2   1/1     Running     0          23h   10.244.1.200   aks-system-35358252-vmss000000   <none>           <none>
inscripciones-service-7f4b8b4899-wm985   0/1     Pending     0          10m   <none>         <none>                           <none>           <none>
postgresql-0                             1/1     Running     0          14m   10.244.1.3     aks-system-35358252-vmss000000   <none>           <none>
rabbitmq-0                               1/1     Running     0          14m   10.244.1.1     aks-system-35358252-vmss000000   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               0                     23h
cursos-service          1               N/A               0                     23h
estudiantes-service     1               N/A               0                     23h
gateway                 1               N/A               0                     23h
inscripciones-service   1               N/A               0                     23h
postgresql              N/A             1                 1                     23h
rabbitmq                N/A             1                 1                     23h
```

### Estado DESPUES del uncordon

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-35358252-vmss000000   Ready    <none>   23h   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-35358252-vmss000001   Ready    <none>   23h   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS   AGE   IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-65f7d68b6c-4bvcj            1/1     Running     0          23h   10.244.1.237   aks-system-35358252-vmss000000   <none>           <none>
auth-service-65f7d68b6c-4frx6            1/1     Running     0          11m   10.244.0.142   aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837256-cb5z2               0/1     Completed   0          11m   10.244.1.139   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837220-gzrl9              0/1     Completed   0          39m   10.244.1.17    aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837230-hqrwt              0/1     Completed   0          37m   10.244.1.106   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837240-jr7f9              0/1     Completed   0          27m   10.244.1.169   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837250-89s2q              0/1     Error       0          17m   10.244.1.224   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837250-m2s74              0/1     Error       0          17m   10.244.1.142   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-consumer-867478f48f-m95z7   1/1     Running     0          26m   10.244.1.101   aks-system-35358252-vmss000000   <none>           <none>
cursos-service-5c5549d45f-4tk54          1/1     Running     0          11m   10.244.0.183   aks-system-35358252-vmss000001   <none>           <none>
cursos-service-5c5549d45f-rkmhc          1/1     Running     0          23h   10.244.1.220   aks-system-35358252-vmss000000   <none>           <none>
estudiantes-service-84b9cb69bc-p6rng     1/1     Running     0          23h   10.244.1.227   aks-system-35358252-vmss000000   <none>           <none>
estudiantes-service-84b9cb69bc-qlz86     1/1     Running     0          11m   10.244.0.246   aks-system-35358252-vmss000001   <none>           <none>
gateway-8955dc9-5msx9                    1/1     Running     0          23h   10.244.1.64    aks-system-35358252-vmss000000   <none>           <none>
gateway-8955dc9-rntnj                    1/1     Running     0          11m   10.244.0.154   aks-system-35358252-vmss000001   <none>           <none>
inscripciones-consumer-8b9c9bb65-wsdhz   1/1     Running     0          11m   10.244.0.69    aks-system-35358252-vmss000001   <none>           <none>
inscripciones-service-7f4b8b4899-f9qb2   1/1     Running     0          23h   10.244.1.200   aks-system-35358252-vmss000000   <none>           <none>
inscripciones-service-7f4b8b4899-wm985   1/1     Running     0          11m   10.244.0.119   aks-system-35358252-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0          15m   10.244.1.3     aks-system-35358252-vmss000000   <none>           <none>
rabbitmq-0                               1/1     Running     0          15m   10.244.1.1     aks-system-35358252-vmss000000   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     23h
cursos-service          1               N/A               1                     23h
estudiantes-service     1               N/A               1                     23h
gateway                 1               N/A               1                     23h
inscripciones-service   1               N/A               1                     23h
postgresql              N/A             1                 1                     23h
rabbitmq                N/A             1                 1                     23h
```

### Salida de kubectl drain

```
node/aks-system-35358252-vmss000001 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/azure-cns-l5bn2, kube-system/azure-ip-masq-agent-64gd4, kube-system/cloud-node-manager-j5m7d, kube-system/csi-azuredisk-node-jktmz, kube-system/csi-azurefile-node-gxh2l, kube-system/kube-proxy-rs6tm, velero/node-agent-j7h49
evicting pod argo-rollouts/argo-rollouts-67cbbf7967-rnww4
evicting pod sa-p8/estudiantes-service-84b9cb69bc-2nzd6
evicting pod argo-rollouts/argo-rollouts-67cbbf7967-qjbqh
evicting pod kube-system/coredns-5d474ff6db-xm2bw
evicting pod kube-system/coredns-autoscaler-6769f8f9b-hbfp4
evicting pod kube-system/konnectivity-agent-autoscaler-57c596c6fd-xh92b
evicting pod kube-system/metrics-server-85768b658b-mdvwd
evicting pod sa-p8/gateway-8955dc9-b4jbk
evicting pod sa-p8/inscripciones-consumer-8b9c9bb65-r27xt
evicting pod velero/sa-p8-default-kopia-zgcdr-maintain-job-1790231604580-f6fg2
evicting pod velero/sa-p8-default-kopia-zgcdr-maintain-job-1790224404563-ckb6p
evicting pod velero/sa-p8-default-kopia-zgcdr-maintain-job-1790228004573-t87zb
evicting pod sa-p8/auth-service-65f7d68b6c-xqjlf
evicting pod sa-p8/cron-insert-29837250-47bmm
evicting pod sa-p8/cron-insert-29837250-4hw2x
evicting pod sa-p8/cron-insert-29837250-8gsdl
evicting pod sa-p8/cron-insert-29837252-4tng4
evicting pod sa-p8/cron-insert-29837254-4t4sg
evicting pod sa-p8/cron-resumen-29837250-swqr8
evicting pod sa-p8/cursos-service-5c5549d45f-wsdpf
evicting pod sa-p8/inscripciones-service-7f4b8b4899-gg8ng
evicting pod kube-system/coredns-5d474ff6db-7w6gb
evicting pod kube-system/sealed-secrets-controller-5d847f4b47-qmg87
evicting pod kyverno/kyverno-admission-controller-86cbbb5545-hvxdf
evicting pod kyverno/kyverno-cleanup-controller-f947f9769-cnbf4
evicting pod kyverno/kyverno-migrate-resources-9m9l8
evicting pod kube-system/metrics-server-85768b658b-zcbg9
pod/sa-p8-default-kopia-zgcdr-maintain-job-1790231604580-f6fg2 evicted
pod/sa-p8-default-kopia-zgcdr-maintain-job-1790224404563-ckb6p evicted
pod/kyverno-migrate-resources-9m9l8 evicted
pod/sa-p8-default-kopia-zgcdr-maintain-job-1790228004573-t87zb evicted
pod/cron-insert-29837250-47bmm evicted
I0924 01:35:42.838223   19764 request.go:729] Waited for 1.1996972s due to client-side throttling, not priority and fairness, request: POST:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/cron-insert-29837250-8gsdl/eviction
pod/cron-insert-29837250-4hw2x evicted
pod/sealed-secrets-controller-5d847f4b47-qmg87 evicted
pod/kyverno-admission-controller-86cbbb5545-hvxdf evicted
pod/metrics-server-85768b658b-mdvwd evicted
pod/kyverno-cleanup-controller-f947f9769-cnbf4 evicted
error when evicting pods/"coredns-5d474ff6db-xm2bw" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-insert-29837250-8gsdl evicted
pod/cron-insert-29837252-4tng4 evicted
pod/cron-insert-29837254-4t4sg evicted
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-resumen-29837250-swqr8 evicted
pod/coredns-autoscaler-6769f8f9b-hbfp4 evicted
pod/konnectivity-agent-autoscaler-57c596c6fd-xh92b evicted
evicting pod kube-system/coredns-5d474ff6db-xm2bw
error when evicting pods/"coredns-5d474ff6db-xm2bw" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/coredns-5d474ff6db-7w6gb evicted
I0924 01:35:52.924301   19764 request.go:729] Waited for 1.5363907s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/argo-rollouts/pods/argo-rollouts-67cbbf7967-rnww4
evicting pod kube-system/coredns-5d474ff6db-xm2bw
error when evicting pods/"coredns-5d474ff6db-xm2bw" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/coredns-5d474ff6db-xm2bw
error when evicting pods/"coredns-5d474ff6db-xm2bw" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 01:36:03.123406   19764 request.go:729] Waited for 1.5349357s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/inscripciones-consumer-8b9c9bb65-r27xt
evicting pod kube-system/coredns-5d474ff6db-xm2bw
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/coredns-5d474ff6db-xm2bw evicted
I0924 01:36:13.124511   19764 request.go:729] Waited for 1.7362396s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/estudiantes-service-84b9cb69bc-2nzd6
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 01:36:23.323886   19764 request.go:729] Waited for 1.5357679s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/inscripciones-service-7f4b8b4899-gg8ng
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 01:36:33.324106   19764 request.go:729] Waited for 1.5344986s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/argo-rollouts/pods/argo-rollouts-67cbbf7967-qjbqh
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 01:36:43.523492   19764 request.go:729] Waited for 1.536074s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/estudiantes-service-84b9cb69bc-2nzd6
pod/inscripciones-consumer-8b9c9bb65-r27xt evicted
pod/inscripciones-service-7f4b8b4899-gg8ng evicted
pod/gateway-8955dc9-b4jbk evicted
pod/argo-rollouts-67cbbf7967-qjbqh evicted
pod/auth-service-65f7d68b6c-xqjlf evicted
pod/argo-rollouts-67cbbf7967-rnww4 evicted
pod/estudiantes-service-84b9cb69bc-2nzd6 evicted
pod/cursos-service-5c5549d45f-wsdpf evicted
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
error when evicting pods/"metrics-server-85768b658b-zcbg9" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-zcbg9
pod/metrics-server-85768b658b-zcbg9 evicted
node/aks-system-35358252-vmss000001 drained
```

### Registro con marcas de tiempo

```

2026-09-24T07:35:27Z | prueba-nodo: escenario=stateless nodo a drenar=aks-system-35358252-vmss000001 (postgresql-0 esta en aks-system-35358252-vmss000000)
2026-09-24T07:35:40Z | prueba-nodo: sondeo en marcha (linea base 10 s)
2026-09-24T07:35:40Z | prueba-nodo: kubectl drain aks-system-35358252-vmss000001 --ignore-daemonsets --delete-emptydir-data --timeout=300s
2026-09-24T07:37:13Z | prueba-nodo: drain terminado (codigo 0)
2026-09-24T07:47:18Z | prueba-nodo: AVISO - Tiempo agotado esperando: workloads Ready sin el nodo (600 s)
2026-09-24T07:47:29Z | prueba-nodo: uncordon aks-system-35358252-vmss000001

```
