# Prueba de perdida de nodo - evidencia automatica

## Escenario A - perdida de un nodo con replicas sin estado

Generado por `P9/scripts/prueba-perdida-nodo.ps1 -Scenario stateless` (todas las horas UTC).

| Campo | Valor |
|---|---|
| Nodo drenado | `aks-system-11192511-vmss000000` (postgresql-0 estaba en `aks-system-11192511-vmss000001`) |
| Hora de inicio del drenaje | 2026-10-16T08:43:40Z |
| Hora de fin del drenaje | 2026-10-16T08:45:10Z (codigo de salida de kubectl drain: 0) |
| Workloads Ready sin el nodo | 2026-10-16T08:45:12Z |
| Uncordon | 2026-10-16T08:45:23Z |
| Replicas configuradas | 2 por microservicio (gateway = Rollout), 1 PostgreSQL, 1 RabbitMQ |
| PDB observado | `minAvailable: 1` en los 5 servicios; `maxUnavailable: 1` en PostgreSQL y RabbitMQ |
| Anti-afinidad | `podAntiAffinity preferred` por `kubernetes.io/hostname` (una replica por nodo) |
| Sondeo | desde esta maquina, IP publica del gateway, 2 endpoints cada ~1 s |

### Resultado del sondeo durante toda la prueba

```

Endpoint Total Errores Disponibilidad MaxErroresSeguidos InicioRacha P95ms
-------- ----- ------- -------------- ------------------ ----------- -----
/health    143       0 100.00%                         0                87
/cursos    143       0 100.00%                         0               113
```

Respuestas no exitosas (si las hubo):

```
(ninguna: todas las respuestas fueron HTTP 200)
```

### Estado ANTES del drenaje

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION             CONTAINER-RUNTIME
aks-system-11192511-vmss000000   Ready    <none>   13m   v1.36.4   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1
aks-system-11192511-vmss000001   Ready    <none>   13m   v1.36.4   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1

NAME                                     READY   STATUS      RESTARTS        AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-6f674f48d-snk7z             1/1     Running     0               9m24s   10.244.1.19    aks-system-11192511-vmss000001   <none>           <none>
auth-service-6f674f48d-tk7mz             1/1     Running     0               9m24s   10.244.0.127   aks-system-11192511-vmss000000   <none>           <none>
cron-insert-29868996-gtqgb               0/1     Completed   0               7m30s   10.244.0.128   aks-system-11192511-vmss000000   <none>           <none>
cron-insert-29868998-52kjt               0/1     Error       0               4m57s   10.244.0.111   aks-system-11192511-vmss000000   <none>           <none>
cron-insert-29868998-dtv5z               0/1     Error       0               5m18s   10.244.0.210   aks-system-11192511-vmss000000   <none>           <none>
cron-insert-29868998-xbgns               0/1     Error       0               5m30s   10.244.0.96    aks-system-11192511-vmss000000   <none>           <none>
cron-insert-29869000-xgm9t               0/1     Completed   0               3m30s   10.244.0.24    aks-system-11192511-vmss000000   <none>           <none>
cron-insert-29869002-hrn6s               0/1     Error       0               90s     10.244.0.175   aks-system-11192511-vmss000000   <none>           <none>
cron-insert-29869002-pwklw               0/1     Completed   0               78s     10.244.0.125   aks-system-11192511-vmss000000   <none>           <none>
cron-resumen-29869000-wsbxr              0/1     Completed   0               3m30s   10.244.0.232   aks-system-11192511-vmss000000   <none>           <none>
cron-resumen-consumer-64846656d7-xrpjz   1/1     Running     1 (7m37s ago)   9m24s   10.244.0.95    aks-system-11192511-vmss000000   <none>           <none>
cursos-service-5b64f7cfb5-r9w94          1/1     Running     0               9m24s   10.244.0.108   aks-system-11192511-vmss000000   <none>           <none>
cursos-service-5b64f7cfb5-z9xfl          1/1     Running     0               9m24s   10.244.1.91    aks-system-11192511-vmss000001   <none>           <none>
estudiantes-service-7966b844b5-v4jqh     1/1     Running     0               9m24s   10.244.1.224   aks-system-11192511-vmss000001   <none>           <none>
estudiantes-service-7966b844b5-z4pd4     1/1     Running     0               9m24s   10.244.0.225   aks-system-11192511-vmss000000   <none>           <none>
gateway-6bc9cd9c-dvf4b                   1/1     Running     0               9m3s    10.244.0.149   aks-system-11192511-vmss000000   <none>           <none>
gateway-6bc9cd9c-s74q7                   1/1     Running     0               9m3s    10.244.1.41    aks-system-11192511-vmss000001   <none>           <none>
inscripciones-consumer-d455b4bc9-k4j9r   1/1     Running     1 (7m38s ago)   9m23s   10.244.0.247   aks-system-11192511-vmss000000   <none>           <none>
inscripciones-service-6667d56755-fpvcd   1/1     Running     0               9m23s   10.244.0.202   aks-system-11192511-vmss000000   <none>           <none>
inscripciones-service-6667d56755-mxrqn   1/1     Running     0               9m24s   10.244.1.236   aks-system-11192511-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0               2m5s    10.244.1.242   aks-system-11192511-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0               2m5s    10.244.1.71    aks-system-11192511-vmss000001   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     9m30s
cursos-service          1               N/A               1                     9m30s
estudiantes-service     1               N/A               1                     9m30s
gateway                 1               N/A               1                     9m30s
inscripciones-service   1               N/A               1                     9m30s
postgresql              N/A             1                 1                     9m30s
rabbitmq                N/A             1                 1                     9m30s
```

### Estado con el nodo drenado (todo reprogramado en el nodo restante)

```nNAME                             STATUS                     ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION             CONTAINER-RUNTIME
aks-system-11192511-vmss000000   Ready,SchedulingDisabled   <none>   14m   v1.36.4   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1
aks-system-11192511-vmss000001   Ready                      <none>   14m   v1.36.4   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1

NAME                                     READY   STATUS      RESTARTS   AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-6f674f48d-lpjgs             1/1     Running     0          88s     10.244.1.180   aks-system-11192511-vmss000001   <none>           <none>
auth-service-6f674f48d-snk7z             1/1     Running     0          11m     10.244.1.19    aks-system-11192511-vmss000001   <none>           <none>
cron-insert-29869004-mhz9n               0/1     Completed   0          73s     10.244.1.48    aks-system-11192511-vmss000001   <none>           <none>
cron-resumen-consumer-64846656d7-gx9nk   1/1     Running     0          90s     10.244.1.221   aks-system-11192511-vmss000001   <none>           <none>
cursos-service-5b64f7cfb5-mhdn4          1/1     Running     0          88s     10.244.1.227   aks-system-11192511-vmss000001   <none>           <none>
cursos-service-5b64f7cfb5-z9xfl          1/1     Running     0          11m     10.244.1.91    aks-system-11192511-vmss000001   <none>           <none>
estudiantes-service-7966b844b5-rhgp4     1/1     Running     0          90s     10.244.1.160   aks-system-11192511-vmss000001   <none>           <none>
estudiantes-service-7966b844b5-v4jqh     1/1     Running     0          11m     10.244.1.224   aks-system-11192511-vmss000001   <none>           <none>
gateway-6bc9cd9c-mqxr4                   1/1     Running     0          87s     10.244.1.177   aks-system-11192511-vmss000001   <none>           <none>
gateway-6bc9cd9c-s74q7                   1/1     Running     0          10m     10.244.1.41    aks-system-11192511-vmss000001   <none>           <none>
inscripciones-consumer-d455b4bc9-786sr   1/1     Running     0          88s     10.244.1.233   aks-system-11192511-vmss000001   <none>           <none>
inscripciones-service-6667d56755-mxrqn   1/1     Running     0          11m     10.244.1.236   aks-system-11192511-vmss000001   <none>           <none>
inscripciones-service-6667d56755-s5xv6   1/1     Running     0          88s     10.244.1.184   aks-system-11192511-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0          3m48s   10.244.1.242   aks-system-11192511-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0          3m48s   10.244.1.71    aks-system-11192511-vmss000001   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     11m
cursos-service          1               N/A               1                     11m
estudiantes-service     1               N/A               1                     11m
gateway                 1               N/A               1                     11m
inscripciones-service   1               N/A               1                     11m
postgresql              N/A             1                 1                     11m
rabbitmq                N/A             1                 1                     11m
```

### Estado DESPUES del uncordon

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION             CONTAINER-RUNTIME
aks-system-11192511-vmss000000   Ready    <none>   15m   v1.36.4   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1
aks-system-11192511-vmss000001   Ready    <none>   15m   v1.36.4   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1

NAME                                     READY   STATUS      RESTARTS   AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-6f674f48d-lpjgs             1/1     Running     0          115s    10.244.1.180   aks-system-11192511-vmss000001   <none>           <none>
auth-service-6f674f48d-snk7z             1/1     Running     0          11m     10.244.1.19    aks-system-11192511-vmss000001   <none>           <none>
cron-insert-29869004-mhz9n               0/1     Completed   0          100s    10.244.1.48    aks-system-11192511-vmss000001   <none>           <none>
cron-resumen-consumer-64846656d7-gx9nk   1/1     Running     0          117s    10.244.1.221   aks-system-11192511-vmss000001   <none>           <none>
cursos-service-5b64f7cfb5-mhdn4          1/1     Running     0          115s    10.244.1.227   aks-system-11192511-vmss000001   <none>           <none>
cursos-service-5b64f7cfb5-z9xfl          1/1     Running     0          11m     10.244.1.91    aks-system-11192511-vmss000001   <none>           <none>
estudiantes-service-7966b844b5-rhgp4     1/1     Running     0          117s    10.244.1.160   aks-system-11192511-vmss000001   <none>           <none>
estudiantes-service-7966b844b5-v4jqh     1/1     Running     0          11m     10.244.1.224   aks-system-11192511-vmss000001   <none>           <none>
gateway-6bc9cd9c-mqxr4                   1/1     Running     0          114s    10.244.1.177   aks-system-11192511-vmss000001   <none>           <none>
gateway-6bc9cd9c-s74q7                   1/1     Running     0          11m     10.244.1.41    aks-system-11192511-vmss000001   <none>           <none>
inscripciones-consumer-d455b4bc9-786sr   1/1     Running     0          115s    10.244.1.233   aks-system-11192511-vmss000001   <none>           <none>
inscripciones-service-6667d56755-mxrqn   1/1     Running     0          11m     10.244.1.236   aks-system-11192511-vmss000001   <none>           <none>
inscripciones-service-6667d56755-s5xv6   1/1     Running     0          115s    10.244.1.184   aks-system-11192511-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0          4m15s   10.244.1.242   aks-system-11192511-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0          4m15s   10.244.1.71    aks-system-11192511-vmss000001   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     11m
cursos-service          1               N/A               1                     11m
estudiantes-service     1               N/A               1                     11m
gateway                 1               N/A               1                     11m
inscripciones-service   1               N/A               1                     11m
postgresql              N/A             1                 1                     11m
rabbitmq                N/A             1                 1                     11m
```

### Salida de kubectl drain

```
node/aks-system-11192511-vmss000000 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/azure-cns-h878l, kube-system/azure-ip-masq-agent-97fz4, kube-system/cloud-node-manager-wkn5r, kube-system/csi-azuredisk-node-ngrj5, kube-system/csi-azurefile-node-8555l, kube-system/kube-proxy-czg9z, velero/node-agent-4vmcq
evicting pod velero/velero-7c7dfcb5bd-72hvd
evicting pod sa-p8/cron-insert-29868996-gtqgb
evicting pod kube-system/konnectivity-agent-74bcffdbbc-bdthr
evicting pod argo-rollouts/argo-rollouts-755879f7fb-2sbz7
evicting pod kube-system/konnectivity-agent-74bcffdbbc-rxmb7
evicting pod argo-rollouts/argo-rollouts-755879f7fb-fpd2c
evicting pod kube-system/konnectivity-agent-autoscaler-747595f466-wnhj8
evicting pod argocd/argocd-server-66f5f8c7c-9qfj7
evicting pod kube-system/metrics-server-5d77586894-hvf4h
evicting pod kube-system/coredns-76df789c68-4fdj6
evicting pod kube-system/metrics-server-5d77586894-jxd79
evicting pod kube-system/coredns-76df789c68-9vxsm
evicting pod sa-p8/auth-service-6f674f48d-tk7mz
evicting pod kyverno/kyverno-reports-controller-d659f94fc-fm65g
evicting pod kube-system/coredns-autoscaler-548c6d85c6-s65q5
evicting pod sa-p8/cron-resumen-29869000-wsbxr
evicting pod sa-p8/estudiantes-service-7966b844b5-z4pd4
evicting pod sa-p8/cron-insert-29868998-52kjt
evicting pod sa-p8/cron-resumen-consumer-64846656d7-xrpjz
evicting pod sa-p8/cron-insert-29868998-xbgns
evicting pod sa-p8/cron-insert-29868998-dtv5z
evicting pod sa-p8/cron-insert-29869000-xgm9t
evicting pod sa-p8/cursos-service-5b64f7cfb5-r9w94
evicting pod sa-p8/cron-insert-29869002-hrn6s
evicting pod sa-p8/cron-insert-29869002-pwklw
evicting pod sa-p8/inscripciones-consumer-d455b4bc9-k4j9r
evicting pod sa-p8/gateway-6bc9cd9c-dvf4b
evicting pod sa-p8/inscripciones-service-6667d56755-fpvcd
pod/cron-resumen-29869000-wsbxr evicted
pod/cron-insert-29868996-gtqgb evicted
pod/cron-insert-29869000-xgm9t evicted
pod/cron-insert-29868998-52kjt evicted
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I1016 02:43:43.185517    9908 request.go:729] Waited for 1.2000127s due to client-side throttling, not priority and fairness, request: POST:https://aks-sa-p9-dc6j2u9e.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/cron-insert-29868998-xbgns/eviction
error when evicting pods/"coredns-76df789c68-9vxsm" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/velero-7c7dfcb5bd-72hvd evicted
pod/konnectivity-agent-autoscaler-747595f466-wnhj8 evicted
pod/argocd-server-66f5f8c7c-9qfj7 evicted
pod/cron-insert-29868998-xbgns evicted
pod/cron-insert-29868998-dtv5z evicted
error when evicting pods/"konnectivity-agent-74bcffdbbc-bdthr" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/argo-rollouts-755879f7fb-2sbz7 evicted
pod/coredns-autoscaler-548c6d85c6-s65q5 evicted
pod/metrics-server-5d77586894-hvf4h evicted
pod/estudiantes-service-7966b844b5-z4pd4 evicted
pod/inscripciones-service-6667d56755-fpvcd evicted
pod/cursos-service-5b64f7cfb5-r9w94 evicted
pod/gateway-6bc9cd9c-dvf4b evicted
evicting pod kube-system/metrics-server-5d77586894-jxd79
pod/cron-insert-29869002-hrn6s evicted
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/argo-rollouts-755879f7fb-fpd2c evicted
evicting pod kube-system/coredns-76df789c68-9vxsm
error when evicting pods/"coredns-76df789c68-9vxsm" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-insert-29869002-pwklw evicted
pod/auth-service-6f674f48d-tk7mz evicted
pod/kyverno-reports-controller-d659f94fc-fm65g evicted
pod/coredns-76df789c68-4fdj6 evicted
evicting pod kube-system/konnectivity-agent-74bcffdbbc-bdthr
error when evicting pods/"konnectivity-agent-74bcffdbbc-bdthr" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/coredns-76df789c68-9vxsm
error when evicting pods/"coredns-76df789c68-9vxsm" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/konnectivity-agent-74bcffdbbc-bdthr
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/coredns-76df789c68-9vxsm
error when evicting pods/"coredns-76df789c68-9vxsm" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/coredns-76df789c68-9vxsm
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/coredns-76df789c68-9vxsm evicted
pod/konnectivity-agent-74bcffdbbc-rxmb7 evicted
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-resumen-consumer-64846656d7-xrpjz evicted
pod/inscripciones-consumer-d455b4bc9-k4j9r evicted
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/konnectivity-agent-74bcffdbbc-bdthr evicted
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-jxd79
error when evicting pods/"metrics-server-5d77586894-jxd79" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-jxd79
pod/metrics-server-5d77586894-jxd79 evicted
node/aks-system-11192511-vmss000000 drained
```

### Registro con marcas de tiempo

```

2026-10-16T08:43:27Z | prueba-nodo: escenario=stateless nodo a drenar=aks-system-11192511-vmss000000 (postgresql-0 esta en aks-system-11192511-vmss000001)
2026-10-16T08:43:40Z | prueba-nodo: sondeo en marcha (linea base 10 s)
2026-10-16T08:43:40Z | prueba-nodo: kubectl drain aks-system-11192511-vmss000000 --ignore-daemonsets --delete-emptydir-data --timeout=300s
2026-10-16T08:45:10Z | prueba-nodo: drain terminado (codigo 0)
2026-10-16T08:45:12Z | prueba-nodo: todos los workloads Ready con un solo nodo
2026-10-16T08:45:23Z | prueba-nodo: uncordon aks-system-11192511-vmss000000

```

## Escenario B - perdida del nodo que aloja PostgreSQL (peor caso, 1 replica)

Generado por `P9/scripts/prueba-perdida-nodo.ps1 -Scenario stateful` (todas las horas UTC).

| Campo | Valor |
|---|---|
| Nodo drenado | `aks-system-11192511-vmss000001` (postgresql-0 estaba en `aks-system-11192511-vmss000001`) |
| Hora de inicio del drenaje | 2026-10-16T08:46:08Z |
| Hora de fin del drenaje | 2026-10-16T08:47:28Z (codigo de salida de kubectl drain: 0) |
| Workloads Ready sin el nodo | 2026-10-16T08:48:35Z |
| Uncordon | 2026-10-16T08:48:47Z |
| Replicas configuradas | 2 por microservicio (gateway = Rollout), 1 PostgreSQL, 1 RabbitMQ |
| PDB observado | `minAvailable: 1` en los 5 servicios; `maxUnavailable: 1` en PostgreSQL y RabbitMQ |
| Anti-afinidad | `podAntiAffinity preferred` por `kubernetes.io/hostname` (una replica por nodo) |
| Sondeo | desde esta maquina, IP publica del gateway, 2 endpoints cada ~1 s |

### Resultado del sondeo durante toda la prueba

```

Endpoint Total Errores Disponibilidad MaxErroresSeguidos InicioRacha P95ms
-------- ----- ------- -------------- ------------------ ----------- -----
/health    199       1 99.50%                          1 08:46:31       87
/cursos    198      75 62.12%                         75 08:46:12       94
```

Respuestas no exitosas (si las hubo):

```
08:46:12 /cursos -> 500 (201 ms)
08:46:16 /cursos -> 0 (2998 ms)
08:46:17 /cursos -> 500 (90 ms)
08:46:18 /cursos -> 500 (86 ms)
08:46:19 /cursos -> 500 (83 ms)
08:46:19 /cursos -> 500 (84 ms)
08:46:20 /cursos -> 500 (88 ms)
08:46:21 /cursos -> 500 (85 ms)
08:46:22 /cursos -> 500 (84 ms)
08:46:23 /cursos -> 500 (86 ms)
08:46:24 /cursos -> 500 (86 ms)
08:46:25 /cursos -> 500 (84 ms)
08:46:26 /cursos -> 504 (81 ms)
08:46:27 /cursos -> 500 (104 ms)
08:46:27 /cursos -> 500 (82 ms)
08:46:31 /health -> 0 (3002 ms)
08:46:31 /cursos -> 500 (172 ms)
08:46:32 /cursos -> 500 (82 ms)
08:46:33 /cursos -> 500 (82 ms)
08:46:34 /cursos -> 500 (84 ms)
08:46:35 /cursos -> 500 (83 ms)
08:46:36 /cursos -> 500 (85 ms)
08:46:37 /cursos -> 500 (83 ms)
08:46:37 /cursos -> 500 (83 ms)
08:46:38 /cursos -> 500 (82 ms)
08:46:39 /cursos -> 500 (82 ms)
08:46:40 /cursos -> 500 (86 ms)
08:46:41 /cursos -> 500 (84 ms)
08:46:42 /cursos -> 500 (85 ms)
08:46:43 /cursos -> 500 (84 ms)
08:46:44 /cursos -> 500 (82 ms)
08:46:44 /cursos -> 500 (86 ms)
08:46:45 /cursos -> 500 (82 ms)
08:46:46 /cursos -> 500 (82 ms)
08:46:47 /cursos -> 500 (83 ms)
08:46:48 /cursos -> 500 (83 ms)
08:46:49 /cursos -> 500 (82 ms)
08:46:50 /cursos -> 500 (84 ms)
08:46:51 /cursos -> 500 (82 ms)
08:46:51 /cursos -> 500 (83 ms)
08:46:52 /cursos -> 500 (90 ms)
08:46:53 /cursos -> 500 (90 ms)
08:46:54 /cursos -> 500 (90 ms)
08:46:55 /cursos -> 500 (84 ms)
08:46:56 /cursos -> 500 (102 ms)
08:46:57 /cursos -> 500 (82 ms)
08:46:58 /cursos -> 500 (83 ms)
08:46:59 /cursos -> 500 (82 ms)
08:46:59 /cursos -> 500 (87 ms)
08:47:00 /cursos -> 500 (93 ms)
08:47:01 /cursos -> 500 (82 ms)
08:47:02 /cursos -> 500 (85 ms)
08:47:03 /cursos -> 500 (90 ms)
08:47:04 /cursos -> 500 (82 ms)
08:47:05 /cursos -> 500 (85 ms)
08:47:06 /cursos -> 500 (85 ms)
08:47:06 /cursos -> 500 (93 ms)
08:47:07 /cursos -> 500 (85 ms)
08:47:09 /cursos -> 500 (1120 ms)
08:47:10 /cursos -> 500 (85 ms)
08:47:11 /cursos -> 500 (91 ms)
08:47:12 /cursos -> 500 (86 ms)
08:47:13 /cursos -> 500 (86 ms)
08:47:14 /cursos -> 500 (93 ms)
08:47:15 /cursos -> 500 (85 ms)
08:47:15 /cursos -> 500 (83 ms)
08:47:16 /cursos -> 500 (81 ms)
08:47:18 /cursos -> 500 (1087 ms)
08:47:19 /cursos -> 500 (82 ms)
08:47:20 /cursos -> 500 (88 ms)
08:47:21 /cursos -> 500 (83 ms)
08:47:22 /cursos -> 500 (83 ms)
08:47:23 /cursos -> 500 (82 ms)
08:47:23 /cursos -> 500 (85 ms)
08:47:24 /cursos -> 500 (81 ms)
08:47:26 /cursos -> 500 (1132 ms)
```

### Estado ANTES del drenaje

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION             CONTAINER-RUNTIME
aks-system-11192511-vmss000000   Ready    <none>   15m   v1.36.4   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1
aks-system-11192511-vmss000001   Ready    <none>   15m   v1.36.4   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1

NAME                                     READY   STATUS      RESTARTS   AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-6f674f48d-lpjgs             1/1     Running     0          2m13s   10.244.1.180   aks-system-11192511-vmss000001   <none>           <none>
auth-service-6f674f48d-snk7z             1/1     Running     0          11m     10.244.1.19    aks-system-11192511-vmss000001   <none>           <none>
cron-insert-29869004-mhz9n               0/1     Completed   0          118s    10.244.1.48    aks-system-11192511-vmss000001   <none>           <none>
cron-resumen-consumer-64846656d7-gx9nk   1/1     Running     0          2m15s   10.244.1.221   aks-system-11192511-vmss000001   <none>           <none>
cursos-service-5b64f7cfb5-mhdn4          1/1     Running     0          2m13s   10.244.1.227   aks-system-11192511-vmss000001   <none>           <none>
cursos-service-5b64f7cfb5-z9xfl          1/1     Running     0          11m     10.244.1.91    aks-system-11192511-vmss000001   <none>           <none>
estudiantes-service-7966b844b5-rhgp4     1/1     Running     0          2m15s   10.244.1.160   aks-system-11192511-vmss000001   <none>           <none>
estudiantes-service-7966b844b5-v4jqh     1/1     Running     0          11m     10.244.1.224   aks-system-11192511-vmss000001   <none>           <none>
gateway-6bc9cd9c-mqxr4                   1/1     Running     0          2m12s   10.244.1.177   aks-system-11192511-vmss000001   <none>           <none>
gateway-6bc9cd9c-s74q7                   1/1     Running     0          11m     10.244.1.41    aks-system-11192511-vmss000001   <none>           <none>
inscripciones-consumer-d455b4bc9-786sr   1/1     Running     0          2m13s   10.244.1.233   aks-system-11192511-vmss000001   <none>           <none>
inscripciones-service-6667d56755-mxrqn   1/1     Running     0          11m     10.244.1.236   aks-system-11192511-vmss000001   <none>           <none>
inscripciones-service-6667d56755-s5xv6   1/1     Running     0          2m13s   10.244.1.184   aks-system-11192511-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0          4m33s   10.244.1.242   aks-system-11192511-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0          4m33s   10.244.1.71    aks-system-11192511-vmss000001   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     11m
cursos-service          1               N/A               1                     11m
estudiantes-service     1               N/A               1                     11m
gateway                 1               N/A               1                     11m
inscripciones-service   1               N/A               1                     11m
postgresql              N/A             1                 1                     11m
rabbitmq                N/A             1                 1                     11m
```

### Estado con el nodo drenado (todo reprogramado en el nodo restante)

```nNAME                             STATUS                     ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION             CONTAINER-RUNTIME
aks-system-11192511-vmss000000   Ready                      <none>   18m   v1.36.4   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1
aks-system-11192511-vmss000001   Ready,SchedulingDisabled   <none>   18m   v1.36.4   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1

NAME                                     READY   STATUS      RESTARTS      AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-6f674f48d-7jzz2             1/1     Running     0             104s    10.244.0.243   aks-system-11192511-vmss000000   <none>           <none>
auth-service-6f674f48d-t52z4             1/1     Running     0             91s     10.244.0.108   aks-system-11192511-vmss000000   <none>           <none>
cron-insert-29869006-f4dr7               0/1     Completed   0             2m37s   10.244.0.116   aks-system-11192511-vmss000000   <none>           <none>
cron-insert-29869008-wggxc               0/1     Completed   0             37s     10.244.0.109   aks-system-11192511-vmss000000   <none>           <none>
cron-resumen-consumer-64846656d7-dcm9c   1/1     Running     1 (13s ago)   104s    10.244.0.214   aks-system-11192511-vmss000000   <none>           <none>
cursos-service-5b64f7cfb5-gzm5n          1/1     Running     0             104s    10.244.0.237   aks-system-11192511-vmss000000   <none>           <none>
cursos-service-5b64f7cfb5-mwww7          1/1     Running     0             2m25s   10.244.0.83    aks-system-11192511-vmss000000   <none>           <none>
estudiantes-service-7966b844b5-kblhd     1/1     Running     0             104s    10.244.0.74    aks-system-11192511-vmss000000   <none>           <none>
estudiantes-service-7966b844b5-xdl24     1/1     Running     0             2m25s   10.244.0.17    aks-system-11192511-vmss000000   <none>           <none>
gateway-6bc9cd9c-7h99l                   1/1     Running     0             2m24s   10.244.0.116   aks-system-11192511-vmss000000   <none>           <none>
gateway-6bc9cd9c-mz9l5                   1/1     Running     0             104s    10.244.0.188   aks-system-11192511-vmss000000   <none>           <none>
inscripciones-consumer-d455b4bc9-vgwch   1/1     Running     0             2m24s   10.244.0.111   aks-system-11192511-vmss000000   <none>           <none>
inscripciones-service-6667d56755-c2vv9   1/1     Running     0             104s    10.244.0.64    aks-system-11192511-vmss000000   <none>           <none>
inscripciones-service-6667d56755-wjw2f   1/1     Running     0             2m26s   10.244.0.107   aks-system-11192511-vmss000000   <none>           <none>
postgresql-0                             1/1     Running     0             104s    10.244.0.149   aks-system-11192511-vmss000000   <none>           <none>
rabbitmq-0                               1/1     Running     0             104s    10.244.0.105   aks-system-11192511-vmss000000   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     14m
cursos-service          1               N/A               1                     14m
estudiantes-service     1               N/A               1                     14m
gateway                 1               N/A               1                     14m
inscripciones-service   1               N/A               1                     14m
postgresql              N/A             1                 1                     14m
rabbitmq                N/A             1                 1                     14m
```

### Estado DESPUES del uncordon

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION             CONTAINER-RUNTIME
aks-system-11192511-vmss000000   Ready    <none>   18m   v1.36.4   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1
aks-system-11192511-vmss000001   Ready    <none>   18m   v1.36.4   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1070-azure (amd64)   containerd://2.3.6-1

NAME                                     READY   STATUS      RESTARTS      AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-6f674f48d-7jzz2             1/1     Running     0             2m11s   10.244.0.243   aks-system-11192511-vmss000000   <none>           <none>
auth-service-6f674f48d-t52z4             1/1     Running     0             118s    10.244.0.108   aks-system-11192511-vmss000000   <none>           <none>
cron-insert-29869006-f4dr7               0/1     Completed   0             3m4s    10.244.0.116   aks-system-11192511-vmss000000   <none>           <none>
cron-insert-29869008-wggxc               0/1     Completed   0             64s     10.244.0.109   aks-system-11192511-vmss000000   <none>           <none>
cron-resumen-consumer-64846656d7-dcm9c   1/1     Running     1 (40s ago)   2m11s   10.244.0.214   aks-system-11192511-vmss000000   <none>           <none>
cursos-service-5b64f7cfb5-gzm5n          1/1     Running     0             2m11s   10.244.0.237   aks-system-11192511-vmss000000   <none>           <none>
cursos-service-5b64f7cfb5-mwww7          1/1     Running     0             2m52s   10.244.0.83    aks-system-11192511-vmss000000   <none>           <none>
estudiantes-service-7966b844b5-kblhd     1/1     Running     0             2m11s   10.244.0.74    aks-system-11192511-vmss000000   <none>           <none>
estudiantes-service-7966b844b5-xdl24     1/1     Running     0             2m52s   10.244.0.17    aks-system-11192511-vmss000000   <none>           <none>
gateway-6bc9cd9c-7h99l                   1/1     Running     0             2m51s   10.244.0.116   aks-system-11192511-vmss000000   <none>           <none>
gateway-6bc9cd9c-mz9l5                   1/1     Running     0             2m11s   10.244.0.188   aks-system-11192511-vmss000000   <none>           <none>
inscripciones-consumer-d455b4bc9-vgwch   1/1     Running     0             2m51s   10.244.0.111   aks-system-11192511-vmss000000   <none>           <none>
inscripciones-service-6667d56755-c2vv9   1/1     Running     0             2m11s   10.244.0.64    aks-system-11192511-vmss000000   <none>           <none>
inscripciones-service-6667d56755-wjw2f   1/1     Running     0             2m53s   10.244.0.107   aks-system-11192511-vmss000000   <none>           <none>
postgresql-0                             1/1     Running     0             2m11s   10.244.0.149   aks-system-11192511-vmss000000   <none>           <none>
rabbitmq-0                               1/1     Running     0             2m11s   10.244.0.105   aks-system-11192511-vmss000000   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     15m
cursos-service          1               N/A               1                     15m
estudiantes-service     1               N/A               1                     15m
gateway                 1               N/A               1                     15m
inscripciones-service   1               N/A               1                     15m
postgresql              N/A             1                 1                     15m
rabbitmq                N/A             1                 1                     15m
```

### Salida de kubectl drain

```
node/aks-system-11192511-vmss000001 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/azure-cns-qjvrn, kube-system/azure-ip-masq-agent-ft56d, kube-system/cloud-node-manager-4kgsp, kube-system/csi-azuredisk-node-9gzr5, kube-system/csi-azurefile-node-jrsj4, kube-system/kube-proxy-ww5j9, velero/node-agent-mvbbx
evicting pod velero/velero-7c7dfcb5bd-hvw4v
evicting pod argo-rollouts/argo-rollouts-755879f7fb-f8tnp
evicting pod kube-system/coredns-76df789c68-sqpcq
evicting pod kube-system/metrics-server-5d77586894-b9csj
evicting pod argocd/argocd-repo-server-d594df5b7-dwlcr
evicting pod kube-system/coredns-76df789c68-njjfn
evicting pod sa-p8/cursos-service-5b64f7cfb5-z9xfl
evicting pod kube-system/coredns-autoscaler-548c6d85c6-bgvlp
evicting pod sa-p8/estudiantes-service-7966b844b5-rhgp4
evicting pod sa-p8/estudiantes-service-7966b844b5-v4jqh
evicting pod sa-p8/gateway-6bc9cd9c-mqxr4
evicting pod sa-p8/gateway-6bc9cd9c-s74q7
evicting pod sa-p8/inscripciones-consumer-d455b4bc9-786sr
evicting pod sa-p8/inscripciones-service-6667d56755-mxrqn
evicting pod sa-p8/inscripciones-service-6667d56755-s5xv6
evicting pod sa-p8/postgresql-0
evicting pod sa-p8/rabbitmq-0
evicting pod argo-rollouts/argo-rollouts-755879f7fb-fsm4l
evicting pod argocd/argocd-application-controller-0
evicting pod argocd/argocd-applicationset-controller-799fdbb568-6nsjz
evicting pod argocd/argocd-dex-server-6cdb668d4-5ldf5
evicting pod argocd/argocd-notifications-controller-dd988c74b-mwscc
evicting pod argocd/argocd-redis-7c6c9c7b5-xmb6p
evicting pod argocd/argocd-server-66f5f8c7c-vnxv4
evicting pod kube-system/konnectivity-agent-74bcffdbbc-kdxx4
evicting pod kube-system/konnectivity-agent-74bcffdbbc-jw8kb
evicting pod kyverno/kyverno-migrate-resources-5nn9b
evicting pod kube-system/sealed-secrets-controller-7c5bc6b888-xzzq9
evicting pod kyverno/kyverno-admission-controller-69f647b47f-ln8m2
evicting pod kyverno/kyverno-background-controller-5c5cb48d8c-m2h29
evicting pod kyverno/kyverno-cleanup-controller-6dd57b99bd-69jqx
evicting pod sa-p8/auth-service-6f674f48d-snk7z
evicting pod kyverno/kyverno-reports-controller-d659f94fc-tk7lb
evicting pod sa-p8/auth-service-6f674f48d-lpjgs
evicting pod kube-system/konnectivity-agent-autoscaler-747595f466-fr4rf
evicting pod sa-p8/cron-insert-29869004-mhz9n
evicting pod sa-p8/cron-resumen-consumer-64846656d7-gx9nk
evicting pod kube-system/metrics-server-5d77586894-6x445
evicting pod sa-p8/cursos-service-5b64f7cfb5-mhdn4
I1016 02:46:10.922104    4560 request.go:729] Waited for 1.000639s due to client-side throttling, not priority and fairness, request: POST:https://aks-sa-p9-dc6j2u9e.hcp.eastus.azmk8s.io:443/api/v1/namespaces/kube-system/pods/metrics-server-5d77586894-b9csj/eviction
error when evicting pods/"coredns-76df789c68-njjfn" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"estudiantes-service-7966b844b5-rhgp4" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/argo-rollouts-755879f7fb-fsm4l evicted
error when evicting pods/"gateway-6bc9cd9c-s74q7" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"inscripciones-service-6667d56755-mxrqn" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"konnectivity-agent-74bcffdbbc-jw8kb" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/argocd-notifications-controller-dd988c74b-mwscc evicted
pod/argocd-redis-7c6c9c7b5-xmb6p evicted
pod/argocd-server-66f5f8c7c-vnxv4 evicted
pod/velero-7c7dfcb5bd-hvw4v evicted
pod/argo-rollouts-755879f7fb-f8tnp evicted
error when evicting pods/"auth-service-6f674f48d-lpjgs" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/argocd-dex-server-6cdb668d4-5ldf5 evicted
pod/coredns-autoscaler-548c6d85c6-bgvlp evicted
pod/argocd-application-controller-0 evicted
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/argocd-applicationset-controller-799fdbb568-6nsjz evicted
error when evicting pods/"cursos-service-5b64f7cfb5-mhdn4" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/coredns-76df789c68-njjfn
evicting pod sa-p8/estudiantes-service-7966b844b5-rhgp4
pod/metrics-server-5d77586894-b9csj evicted
error when evicting pods/"estudiantes-service-7966b844b5-rhgp4" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/kyverno-migrate-resources-5nn9b evicted
evicting pod sa-p8/gateway-6bc9cd9c-s74q7
error when evicting pods/"gateway-6bc9cd9c-s74q7" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/sealed-secrets-controller-7c5bc6b888-xzzq9 evicted
evicting pod sa-p8/inscripciones-service-6667d56755-mxrqn
error when evicting pods/"inscripciones-service-6667d56755-mxrqn" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/kyverno-admission-controller-69f647b47f-ln8m2 evicted
evicting pod kube-system/konnectivity-agent-74bcffdbbc-jw8kb
error when evicting pods/"konnectivity-agent-74bcffdbbc-jw8kb" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/kyverno-background-controller-5c5cb48d8c-m2h29 evicted
pod/kyverno-cleanup-controller-6dd57b99bd-69jqx evicted
pod/kyverno-reports-controller-d659f94fc-tk7lb evicted
pod/konnectivity-agent-autoscaler-747595f466-fr4rf evicted
pod/cron-insert-29869004-mhz9n evicted
evicting pod sa-p8/auth-service-6f674f48d-lpjgs
error when evicting pods/"auth-service-6f674f48d-lpjgs" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/coredns-76df789c68-sqpcq evicted
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/cursos-service-5b64f7cfb5-mhdn4
error when evicting pods/"cursos-service-5b64f7cfb5-mhdn4" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I1016 02:46:21.022477    4560 request.go:729] Waited for 4.2482282s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-dc6j2u9e.hcp.eastus.azmk8s.io:443/api/v1/namespaces/kube-system/pods/coredns-76df789c68-njjfn
evicting pod sa-p8/estudiantes-service-7966b844b5-rhgp4
evicting pod sa-p8/gateway-6bc9cd9c-s74q7
error when evicting pods/"gateway-6bc9cd9c-s74q7" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/inscripciones-service-6667d56755-mxrqn
evicting pod kube-system/konnectivity-agent-74bcffdbbc-jw8kb
pod/coredns-76df789c68-njjfn evicted
evicting pod sa-p8/auth-service-6f674f48d-lpjgs
error when evicting pods/"auth-service-6f674f48d-lpjgs" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/cursos-service-5b64f7cfb5-mhdn4
evicting pod sa-p8/gateway-6bc9cd9c-s74q7
evicting pod sa-p8/auth-service-6f674f48d-lpjgs
error when evicting pods/"auth-service-6f674f48d-lpjgs" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I1016 02:46:31.022544    4560 request.go:729] Waited for 3.1176591s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-dc6j2u9e.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/inscripciones-consumer-d455b4bc9-786sr
evicting pod sa-p8/auth-service-6f674f48d-lpjgs
error when evicting pods/"auth-service-6f674f48d-lpjgs" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/auth-service-6f674f48d-lpjgs
error when evicting pods/"auth-service-6f674f48d-lpjgs" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-6x445
I1016 02:46:41.022610    4560 request.go:729] Waited for 3.1170255s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-dc6j2u9e.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/inscripciones-service-6667d56755-s5xv6
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/auth-service-6f674f48d-lpjgs
error when evicting pods/"auth-service-6f674f48d-lpjgs" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/konnectivity-agent-74bcffdbbc-kdxx4 evicted
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/auth-service-6f674f48d-lpjgs
error when evicting pods/"auth-service-6f674f48d-lpjgs" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I1016 02:46:51.023062    4560 request.go:729] Waited for 2.9154885s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-dc6j2u9e.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/cursos-service-5b64f7cfb5-mhdn4
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/estudiantes-service-7966b844b5-rhgp4 evicted
pod/cron-resumen-consumer-64846656d7-gx9nk evicted
pod/gateway-6bc9cd9c-s74q7 evicted
pod/inscripciones-consumer-d455b4bc9-786sr evicted
pod/gateway-6bc9cd9c-mqxr4 evicted
pod/inscripciones-service-6667d56755-s5xv6 evicted
pod/inscripciones-service-6667d56755-mxrqn evicted
pod/postgresql-0 evicted
pod/cursos-service-5b64f7cfb5-mhdn4 evicted
pod/rabbitmq-0 evicted
pod/konnectivity-agent-74bcffdbbc-jw8kb evicted
pod/estudiantes-service-7966b844b5-v4jqh evicted
pod/argocd-repo-server-d594df5b7-dwlcr evicted
pod/auth-service-6f674f48d-snk7z evicted
pod/cursos-service-5b64f7cfb5-z9xfl evicted
evicting pod sa-p8/auth-service-6f674f48d-lpjgs
error when evicting pods/"auth-service-6f674f48d-lpjgs" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/auth-service-6f674f48d-lpjgs
error when evicting pods/"auth-service-6f674f48d-lpjgs" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/auth-service-6f674f48d-lpjgs
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/auth-service-6f674f48d-lpjgs evicted
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-6x445
error when evicting pods/"metrics-server-5d77586894-6x445" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-5d77586894-6x445
pod/metrics-server-5d77586894-6x445 evicted
node/aks-system-11192511-vmss000001 drained
```

### Registro con marcas de tiempo

```

2026-10-16T08:45:53Z | prueba-nodo: escenario=stateful nodo a drenar=aks-system-11192511-vmss000001 (postgresql-0 esta en aks-system-11192511-vmss000001)
2026-10-16T08:46:08Z | prueba-nodo: sondeo en marcha (linea base 10 s)
2026-10-16T08:46:08Z | prueba-nodo: kubectl drain aks-system-11192511-vmss000001 --ignore-daemonsets --delete-emptydir-data --timeout=300s
2026-10-16T08:47:28Z | prueba-nodo: drain terminado (codigo 0)
2026-10-16T08:48:35Z | prueba-nodo: todos los workloads Ready con un solo nodo
2026-10-16T08:48:47Z | prueba-nodo: uncordon aks-system-11192511-vmss000001

```
