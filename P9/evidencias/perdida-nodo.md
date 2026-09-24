# Prueba de perdida de nodo - evidencia automatica

## Escenario A - perdida de un nodo con replicas sin estado

Generado por `P9/scripts/prueba-perdida-nodo.ps1 -Scenario stateless` (todas las horas UTC).

| Campo | Valor |
|---|---|
| Nodo drenado | `aks-system-30288723-vmss000000` (postgresql-0 estaba en `aks-system-30288723-vmss000001`) |
| Hora de inicio del drenaje | 2026-09-24T09:24:32Z |
| Hora de fin del drenaje | 2026-09-24T09:25:37Z (codigo de salida de kubectl drain: 0) |
| Workloads Ready sin el nodo | 2026-09-24T09:27:18Z |
| Uncordon | 2026-09-24T09:27:30Z |
| Replicas configuradas | 2 por microservicio (gateway = Rollout), 1 PostgreSQL, 1 RabbitMQ |
| PDB observado | `minAvailable: 1` en los 5 servicios; `maxUnavailable: 1` en PostgreSQL y RabbitMQ |
| Anti-afinidad | `podAntiAffinity preferred` por `kubernetes.io/hostname` (una replica por nodo) |
| Sondeo | desde esta maquina, IP publica del gateway, 2 endpoints cada ~1 s |

### Resultado del sondeo durante toda la prueba

```

Endpoint Total Errores Disponibilidad MaxErroresSeguidos InicioRacha P95ms
-------- ----- ------- -------------- ------------------ ----------- -----
/health    242       0 100.00%                         0                66
/cursos    242       0 100.00%                         0                69
```

Respuestas no exitosas (si las hubo):

```
(ninguna: todas las respuestas fueron HTTP 200)
```

### Estado ANTES del drenaje

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-30288723-vmss000000   Ready    <none>   12m   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-30288723-vmss000001   Ready    <none>   12m   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS        AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-ng2sb             1/1     Running     0               7m35s   10.244.1.164   aks-system-30288723-vmss000001   <none>           <none>
auth-service-c7d97959f-x6xzr             1/1     Running     0               7m35s   10.244.0.124   aks-system-30288723-vmss000000   <none>           <none>
cron-insert-29837360-42rnn               0/1     Error       0               4m10s   10.244.0.196   aks-system-30288723-vmss000000   <none>           <none>
cron-insert-29837360-mqjw9               0/1     Completed   0               3m48s   10.244.0.100   aks-system-30288723-vmss000000   <none>           <none>
cron-insert-29837360-rwg5b               0/1     Error       0               4m22s   10.244.0.108   aks-system-30288723-vmss000000   <none>           <none>
cron-insert-29837362-prdkg               0/1     Completed   0               2m22s   10.244.0.90    aks-system-30288723-vmss000000   <none>           <none>
cron-insert-29837364-st9gw               0/1     Completed   0               22s     10.244.0.164   aks-system-30288723-vmss000000   <none>           <none>
cron-resumen-29837360-2sznr              0/1     Error       0               4m10s   10.244.1.223   aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-29837360-2vzh7              0/1     Error       0               4m22s   10.244.1.67    aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-29837360-hnk9f              0/1     Error       0               3m48s   10.244.1.161   aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-consumer-867478f48f-6q76z   1/1     Running     1 (5m34s ago)   7m35s   10.244.0.240   aks-system-30288723-vmss000000   <none>           <none>
cursos-service-54dfc7b68c-9l7v8          1/1     Running     0               7m35s   10.244.1.158   aks-system-30288723-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-pwx2g          1/1     Running     0               7m34s   10.244.0.95    aks-system-30288723-vmss000000   <none>           <none>
estudiantes-service-6b9df98b75-q4pgd     1/1     Running     0               7m34s   10.244.0.111   aks-system-30288723-vmss000000   <none>           <none>
estudiantes-service-6b9df98b75-rf75g     1/1     Running     0               7m35s   10.244.1.114   aks-system-30288723-vmss000001   <none>           <none>
gateway-667bb95dfb-fqdh7                 1/1     Running     0               7m34s   10.244.1.250   aks-system-30288723-vmss000001   <none>           <none>
gateway-667bb95dfb-vdrl9                 1/1     Running     0               7m34s   10.244.0.193   aks-system-30288723-vmss000000   <none>           <none>
inscripciones-consumer-8b9c9bb65-6dlf9   1/1     Running     1 (5m39s ago)   7m34s   10.244.0.0     aks-system-30288723-vmss000000   <none>           <none>
inscripciones-service-5cff7c98f9-45df6   1/1     Running     0               7m35s   10.244.0.23    aks-system-30288723-vmss000000   <none>           <none>
inscripciones-service-5cff7c98f9-bwmdr   1/1     Running     0               7m34s   10.244.1.30    aks-system-30288723-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0               94s     10.244.1.127   aks-system-30288723-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0               94s     10.244.0.80    aks-system-30288723-vmss000000   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     7m47s
cursos-service          1               N/A               1                     7m47s
estudiantes-service     1               N/A               1                     7m47s
gateway                 1               N/A               1                     7m47s
inscripciones-service   1               N/A               1                     7m47s
postgresql              N/A             1                 1                     7m47s
rabbitmq                N/A             1                 1                     7m47s
```

### Estado con el nodo drenado (todo reprogramado en el nodo restante)

```nNAME                             STATUS                     ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-30288723-vmss000000   Ready,SchedulingDisabled   <none>   15m   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-30288723-vmss000001   Ready                      <none>   15m   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS      AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-hzssp             1/1     Running     0             104s    10.244.1.115   aks-system-30288723-vmss000001   <none>           <none>
auth-service-c7d97959f-ng2sb             1/1     Running     0             10m     10.244.1.164   aks-system-30288723-vmss000001   <none>           <none>
cron-insert-29837366-slhhb               0/1     Completed   0             79s     10.244.1.207   aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-29837360-2sznr              0/1     Error       0             7m7s    10.244.1.223   aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-29837360-2vzh7              0/1     Error       0             7m19s   10.244.1.67    aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-29837360-hnk9f              0/1     Error       0             6m45s   10.244.1.161   aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-consumer-867478f48f-5q7c9   1/1     Running     1 (12s ago)   104s    10.244.1.228   aks-system-30288723-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-9l7v8          1/1     Running     0             10m     10.244.1.158   aks-system-30288723-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-tfffz          1/1     Running     0             105s    10.244.1.150   aks-system-30288723-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-rf75g     1/1     Running     0             10m     10.244.1.114   aks-system-30288723-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-rm75n     1/1     Running     0             105s    10.244.1.148   aks-system-30288723-vmss000001   <none>           <none>
gateway-667bb95dfb-4wrww                 1/1     Running     0             105s    10.244.1.229   aks-system-30288723-vmss000001   <none>           <none>
gateway-667bb95dfb-fqdh7                 1/1     Running     0             10m     10.244.1.250   aks-system-30288723-vmss000001   <none>           <none>
inscripciones-consumer-8b9c9bb65-7bb2q   1/1     Running     1 (13s ago)   104s    10.244.1.139   aks-system-30288723-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-bwmdr   1/1     Running     0             10m     10.244.1.30    aks-system-30288723-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-zmqsj   1/1     Running     0             104s    10.244.1.131   aks-system-30288723-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0             4m31s   10.244.1.127   aks-system-30288723-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0             104s    10.244.1.248   aks-system-30288723-vmss000001   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     10m
cursos-service          1               N/A               1                     10m
estudiantes-service     1               N/A               1                     10m
gateway                 1               N/A               1                     10m
inscripciones-service   1               N/A               1                     10m
postgresql              N/A             1                 1                     10m
rabbitmq                N/A             1                 1                     10m
```

### Estado DESPUES del uncordon

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-30288723-vmss000000   Ready    <none>   16m   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-30288723-vmss000001   Ready    <none>   16m   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS      AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-hzssp             1/1     Running     0             2m12s   10.244.1.115   aks-system-30288723-vmss000001   <none>           <none>
auth-service-c7d97959f-ng2sb             1/1     Running     0             11m     10.244.1.164   aks-system-30288723-vmss000001   <none>           <none>
cron-insert-29837366-slhhb               0/1     Completed   0             107s    10.244.1.207   aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-29837360-2sznr              0/1     Error       0             7m35s   10.244.1.223   aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-29837360-2vzh7              0/1     Error       0             7m47s   10.244.1.67    aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-29837360-hnk9f              0/1     Error       0             7m13s   10.244.1.161   aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-consumer-867478f48f-5q7c9   1/1     Running     1 (40s ago)   2m12s   10.244.1.228   aks-system-30288723-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-9l7v8          1/1     Running     0             11m     10.244.1.158   aks-system-30288723-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-tfffz          1/1     Running     0             2m13s   10.244.1.150   aks-system-30288723-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-rf75g     1/1     Running     0             11m     10.244.1.114   aks-system-30288723-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-rm75n     1/1     Running     0             2m13s   10.244.1.148   aks-system-30288723-vmss000001   <none>           <none>
gateway-667bb95dfb-4wrww                 1/1     Running     0             2m13s   10.244.1.229   aks-system-30288723-vmss000001   <none>           <none>
gateway-667bb95dfb-fqdh7                 1/1     Running     0             10m     10.244.1.250   aks-system-30288723-vmss000001   <none>           <none>
inscripciones-consumer-8b9c9bb65-7bb2q   1/1     Running     1 (41s ago)   2m12s   10.244.1.139   aks-system-30288723-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-bwmdr   1/1     Running     0             10m     10.244.1.30    aks-system-30288723-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-zmqsj   1/1     Running     0             2m12s   10.244.1.131   aks-system-30288723-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0             4m59s   10.244.1.127   aks-system-30288723-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0             2m12s   10.244.1.248   aks-system-30288723-vmss000001   <none>           <none>

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
node/aks-system-30288723-vmss000000 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/azure-cns-2xmf4, kube-system/azure-ip-masq-agent-h4lzb, kube-system/cloud-node-manager-s6jb4, kube-system/csi-azuredisk-node-x2lrn, kube-system/csi-azurefile-node-kzmlc, kube-system/kube-proxy-7xgbz, velero/node-agent-9mv8c
evicting pod sa-p8/rabbitmq-0
evicting pod kyverno/kyverno-cleanup-controller-79bc549cd7-mp6l2
evicting pod argo-rollouts/argo-rollouts-67cbbf7967-vrfp8
evicting pod argocd/argocd-applicationset-controller-58b8dccbc9-mjzpz
evicting pod argocd/argocd-dex-server-5ddff64d4c-64pv7
evicting pod argocd/argocd-notifications-controller-6b4645cfc-fwvxg
evicting pod argocd/argocd-repo-server-7f88cf5b58-mwjlg
evicting pod argocd/argocd-server-86cf644d68-pvjkh
evicting pod kube-system/coredns-5d474ff6db-lwmzf
evicting pod kube-system/coredns-autoscaler-6769f8f9b-ntpfm
evicting pod kube-system/konnectivity-agent-57b68bb5bd-hnrs7
evicting pod kube-system/konnectivity-agent-autoscaler-57c596c6fd-5md8k
evicting pod kyverno/kyverno-admission-controller-644db5f8f4-55hr8
evicting pod kyverno/kyverno-background-controller-6dcbb8f98-mf65c
evicting pod sa-p8/cron-insert-29837364-st9gw
evicting pod kyverno/kyverno-reports-controller-77748cd6dd-6lrjf
evicting pod sa-p8/auth-service-c7d97959f-x6xzr
evicting pod sa-p8/cron-insert-29837360-42rnn
evicting pod sa-p8/cron-insert-29837360-mqjw9
evicting pod sa-p8/cron-insert-29837360-rwg5b
evicting pod sa-p8/cron-insert-29837362-prdkg
evicting pod sa-p8/estudiantes-service-6b9df98b75-q4pgd
evicting pod sa-p8/cron-resumen-consumer-867478f48f-6q76z
evicting pod sa-p8/cursos-service-54dfc7b68c-pwx2g
evicting pod sa-p8/inscripciones-consumer-8b9c9bb65-6dlf9
evicting pod sa-p8/gateway-667bb95dfb-vdrl9
evicting pod sa-p8/inscripciones-service-5cff7c98f9-45df6
I0924 03:24:35.003470   17700 request.go:729] Waited for 1.1997891s due to client-side throttling, not priority and fairness, request: POST:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/cron-insert-29837364-st9gw/eviction
pod/cron-insert-29837362-prdkg evicted
pod/cron-insert-29837364-st9gw evicted
pod/konnectivity-agent-autoscaler-57c596c6fd-5md8k evicted
pod/cron-insert-29837360-42rnn evicted
pod/kyverno-admission-controller-644db5f8f4-55hr8 evicted
pod/cron-insert-29837360-mqjw9 evicted
pod/cron-insert-29837360-rwg5b evicted
pod/kyverno-cleanup-controller-79bc549cd7-mp6l2 evicted
pod/kyverno-background-controller-6dcbb8f98-mf65c evicted
pod/coredns-5d474ff6db-lwmzf evicted
pod/coredns-autoscaler-6769f8f9b-ntpfm evicted
pod/kyverno-reports-controller-77748cd6dd-6lrjf evicted
I0924 03:24:45.096733   17700 request.go:729] Waited for 3.3330558s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/gateway-667bb95dfb-vdrl9
I0924 03:24:55.295807   17700 request.go:729] Waited for 2.9297924s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/argo-rollouts/pods/argo-rollouts-67cbbf7967-vrfp8
I0924 03:25:05.296971   17700 request.go:729] Waited for 2.9315837s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/cursos-service-54dfc7b68c-pwx2g
pod/konnectivity-agent-57b68bb5bd-hnrs7 evicted
I0924 03:25:15.495979   17700 request.go:729] Waited for 2.7341866s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/argocd/pods/argocd-dex-server-5ddff64d4c-64pv7
I0924 03:25:25.496034   17700 request.go:729] Waited for 2.7311278s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/argocd/pods/argocd-applicationset-controller-58b8dccbc9-mjzpz
pod/argo-rollouts-67cbbf7967-vrfp8 evicted
pod/argocd-notifications-controller-6b4645cfc-fwvxg evicted
I0924 03:25:35.696395   17700 request.go:729] Waited for 2.7309764s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/argocd/pods/argocd-server-86cf644d68-pvjkh
pod/argocd-server-86cf644d68-pvjkh evicted
pod/rabbitmq-0 evicted
pod/argocd-repo-server-7f88cf5b58-mwjlg evicted
pod/cursos-service-54dfc7b68c-pwx2g evicted
pod/estudiantes-service-6b9df98b75-q4pgd evicted
pod/argocd-applicationset-controller-58b8dccbc9-mjzpz evicted
pod/cron-resumen-consumer-867478f48f-6q76z evicted
pod/gateway-667bb95dfb-vdrl9 evicted
pod/inscripciones-consumer-8b9c9bb65-6dlf9 evicted
pod/inscripciones-service-5cff7c98f9-45df6 evicted
pod/auth-service-c7d97959f-x6xzr evicted
pod/argocd-dex-server-5ddff64d4c-64pv7 evicted
node/aks-system-30288723-vmss000000 drained
```

### Registro con marcas de tiempo

```

2026-09-24T09:24:18Z | prueba-nodo: escenario=stateless nodo a drenar=aks-system-30288723-vmss000000 (postgresql-0 esta en aks-system-30288723-vmss000001)
2026-09-24T09:24:32Z | prueba-nodo: sondeo en marcha (linea base 10 s)
2026-09-24T09:24:32Z | prueba-nodo: kubectl drain aks-system-30288723-vmss000000 --ignore-daemonsets --delete-emptydir-data --timeout=300s
2026-09-24T09:25:37Z | prueba-nodo: drain terminado (codigo 0)
2026-09-24T09:27:18Z | prueba-nodo: todos los workloads Ready con un solo nodo
2026-09-24T09:27:30Z | prueba-nodo: uncordon aks-system-30288723-vmss000000

```

## Escenario B - perdida del nodo que aloja PostgreSQL (peor caso, 1 replica)

Generado por `P9/scripts/prueba-perdida-nodo.ps1 -Scenario stateful` (todas las horas UTC).

| Campo | Valor |
|---|---|
| Nodo drenado | `aks-system-30288723-vmss000001` (postgresql-0 estaba en `aks-system-30288723-vmss000001`) |
| Hora de inicio del drenaje | 2026-09-24T09:28:02Z |
| Hora de fin del drenaje | 2026-09-24T09:29:30Z (codigo de salida de kubectl drain: 0) |
| Workloads Ready sin el nodo | 2026-09-24T09:29:50Z |
| Uncordon | 2026-09-24T09:30:01Z |
| Replicas configuradas | 2 por microservicio (gateway = Rollout), 1 PostgreSQL, 1 RabbitMQ |
| PDB observado | `minAvailable: 1` en los 5 servicios; `maxUnavailable: 1` en PostgreSQL y RabbitMQ |
| Anti-afinidad | `podAntiAffinity preferred` por `kubernetes.io/hostname` (una replica por nodo) |
| Sondeo | desde esta maquina, IP publica del gateway, 2 endpoints cada ~1 s |

### Resultado del sondeo durante toda la prueba

```

Endpoint Total Errores Disponibilidad MaxErroresSeguidos InicioRacha P95ms
-------- ----- ------- -------------- ------------------ ----------- -----
/health    162       0 100.00%                         0                65
/cursos    162      64 60.49%                         64 09:28:35       76
```

Respuestas no exitosas (si las hubo):

```
09:28:35 /cursos -> 500 (100 ms)
09:28:36 /cursos -> 500 (69 ms)
09:28:37 /cursos -> 500 (69 ms)
09:28:37 /cursos -> 500 (74 ms)
09:28:38 /cursos -> 500 (67 ms)
09:28:39 /cursos -> 500 (64 ms)
09:28:40 /cursos -> 500 (64 ms)
09:28:41 /cursos -> 500 (64 ms)
09:28:42 /cursos -> 500 (64 ms)
09:28:42 /cursos -> 500 (63 ms)
09:28:43 /cursos -> 500 (62 ms)
09:28:44 /cursos -> 500 (70 ms)
09:28:45 /cursos -> 500 (65 ms)
09:28:46 /cursos -> 500 (64 ms)
09:28:47 /cursos -> 500 (68 ms)
09:28:48 /cursos -> 500 (68 ms)
09:28:48 /cursos -> 500 (68 ms)
09:28:49 /cursos -> 500 (63 ms)
09:28:50 /cursos -> 500 (63 ms)
09:28:51 /cursos -> 500 (68 ms)
09:28:52 /cursos -> 500 (63 ms)
09:28:53 /cursos -> 500 (65 ms)
09:28:53 /cursos -> 500 (65 ms)
09:28:54 /cursos -> 500 (63 ms)
09:28:55 /cursos -> 500 (65 ms)
09:28:56 /cursos -> 500 (64 ms)
09:28:57 /cursos -> 500 (64 ms)
09:28:58 /cursos -> 500 (63 ms)
09:28:58 /cursos -> 500 (64 ms)
09:28:59 /cursos -> 500 (62 ms)
09:29:00 /cursos -> 500 (84 ms)
09:29:01 /cursos -> 500 (63 ms)
09:29:02 /cursos -> 500 (64 ms)
09:29:03 /cursos -> 500 (63 ms)
09:29:03 /cursos -> 500 (63 ms)
09:29:04 /cursos -> 500 (64 ms)
09:29:05 /cursos -> 500 (66 ms)
09:29:07 /cursos -> 500 (1095 ms)
09:29:08 /cursos -> 500 (63 ms)
09:29:09 /cursos -> 500 (75 ms)
09:29:10 /cursos -> 500 (63 ms)
09:29:10 /cursos -> 500 (63 ms)
09:29:11 /cursos -> 500 (63 ms)
09:29:13 /cursos -> 500 (1099 ms)
09:29:14 /cursos -> 500 (63 ms)
09:29:15 /cursos -> 500 (62 ms)
09:29:16 /cursos -> 500 (67 ms)
09:29:16 /cursos -> 500 (72 ms)
09:29:17 /cursos -> 500 (62 ms)
09:29:18 /cursos -> 500 (66 ms)
09:29:20 /cursos -> 500 (1099 ms)
09:29:21 /cursos -> 500 (65 ms)
09:29:22 /cursos -> 500 (64 ms)
09:29:23 /cursos -> 500 (65 ms)
09:29:23 /cursos -> 500 (62 ms)
09:29:24 /cursos -> 500 (63 ms)
09:29:26 /cursos -> 500 (1116 ms)
09:29:27 /cursos -> 500 (64 ms)
09:29:28 /cursos -> 500 (63 ms)
09:29:29 /cursos -> 500 (63 ms)
09:29:29 /cursos -> 500 (64 ms)
09:29:30 /cursos -> 500 (63 ms)
09:29:32 /cursos -> 500 (1119 ms)
09:29:33 /cursos -> 500 (64 ms)
```

### Estado ANTES del drenaje

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-30288723-vmss000000   Ready    <none>   16m   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-30288723-vmss000001   Ready    <none>   16m   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS      AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-hzssp             1/1     Running     0             2m17s   10.244.1.115   aks-system-30288723-vmss000001   <none>           <none>
auth-service-c7d97959f-ng2sb             1/1     Running     0             11m     10.244.1.164   aks-system-30288723-vmss000001   <none>           <none>
cron-insert-29837366-slhhb               0/1     Completed   0             112s    10.244.1.207   aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-29837360-2sznr              0/1     Error       0             7m40s   10.244.1.223   aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-29837360-2vzh7              0/1     Error       0             7m52s   10.244.1.67    aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-29837360-hnk9f              0/1     Error       0             7m18s   10.244.1.161   aks-system-30288723-vmss000001   <none>           <none>
cron-resumen-consumer-867478f48f-5q7c9   1/1     Running     1 (45s ago)   2m17s   10.244.1.228   aks-system-30288723-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-9l7v8          1/1     Running     0             11m     10.244.1.158   aks-system-30288723-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-tfffz          1/1     Running     0             2m18s   10.244.1.150   aks-system-30288723-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-rf75g     1/1     Running     0             11m     10.244.1.114   aks-system-30288723-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-rm75n     1/1     Running     0             2m18s   10.244.1.148   aks-system-30288723-vmss000001   <none>           <none>
gateway-667bb95dfb-4wrww                 1/1     Running     0             2m18s   10.244.1.229   aks-system-30288723-vmss000001   <none>           <none>
gateway-667bb95dfb-fqdh7                 1/1     Running     0             11m     10.244.1.250   aks-system-30288723-vmss000001   <none>           <none>
inscripciones-consumer-8b9c9bb65-7bb2q   1/1     Running     1 (46s ago)   2m17s   10.244.1.139   aks-system-30288723-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-bwmdr   1/1     Running     0             11m     10.244.1.30    aks-system-30288723-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-zmqsj   1/1     Running     0             2m17s   10.244.1.131   aks-system-30288723-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0             5m4s    10.244.1.127   aks-system-30288723-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0             2m17s   10.244.1.248   aks-system-30288723-vmss000001   <none>           <none>

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

```nNAME                             STATUS                     ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-30288723-vmss000000   Ready                      <none>   18m   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-30288723-vmss000001   Ready,SchedulingDisabled   <none>   18m   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS   AGE    IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-k7txk             1/1     Running     0          64s    10.244.0.42    aks-system-30288723-vmss000000   <none>           <none>
auth-service-c7d97959f-qmtwk             1/1     Running     0          53s    10.244.0.173   aks-system-30288723-vmss000000   <none>           <none>
cron-insert-29837368-vpr7l               0/1     Completed   0          111s   10.244.0.92    aks-system-30288723-vmss000000   <none>           <none>
cron-resumen-consumer-867478f48f-npp8q   1/1     Running     0          107s   10.244.0.36    aks-system-30288723-vmss000000   <none>           <none>
cursos-service-54dfc7b68c-bq8p9          1/1     Running     0          65s    10.244.0.95    aks-system-30288723-vmss000000   <none>           <none>
cursos-service-54dfc7b68c-nwdxw          1/1     Running     0          107s   10.244.0.138   aks-system-30288723-vmss000000   <none>           <none>
estudiantes-service-6b9df98b75-225ln     1/1     Running     0          64s    10.244.0.234   aks-system-30288723-vmss000000   <none>           <none>
estudiantes-service-6b9df98b75-zvxgb     1/1     Running     0          107s   10.244.0.243   aks-system-30288723-vmss000000   <none>           <none>
gateway-667bb95dfb-jkh65                 1/1     Running     0          64s    10.244.0.141   aks-system-30288723-vmss000000   <none>           <none>
gateway-667bb95dfb-kzc7d                 1/1     Running     0          106s   10.244.0.27    aks-system-30288723-vmss000000   <none>           <none>
inscripciones-consumer-8b9c9bb65-r4phv   1/1     Running     0          107s   10.244.0.81    aks-system-30288723-vmss000000   <none>           <none>
inscripciones-service-5cff7c98f9-4r5p8   1/1     Running     0          107s   10.244.0.104   aks-system-30288723-vmss000000   <none>           <none>
inscripciones-service-5cff7c98f9-mrjkz   1/1     Running     0          65s    10.244.0.210   aks-system-30288723-vmss000000   <none>           <none>
postgresql-0                             1/1     Running     0          65s    10.244.0.85    aks-system-30288723-vmss000000   <none>           <none>
rabbitmq-0                               1/1     Running     0          64s    10.244.0.11    aks-system-30288723-vmss000000   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     13m
cursos-service          1               N/A               1                     13m
estudiantes-service     1               N/A               1                     13m
gateway                 1               N/A               1                     13m
inscripciones-service   1               N/A               1                     13m
postgresql              N/A             1                 1                     13m
rabbitmq                N/A             1                 1                     13m
```

### Estado DESPUES del uncordon

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-30288723-vmss000000   Ready    <none>   18m   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-30288723-vmss000001   Ready    <none>   18m   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS   AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-k7txk             1/1     Running     0          91s     10.244.0.42    aks-system-30288723-vmss000000   <none>           <none>
auth-service-c7d97959f-qmtwk             1/1     Running     0          80s     10.244.0.173   aks-system-30288723-vmss000000   <none>           <none>
cron-insert-29837368-vpr7l               0/1     Completed   0          2m18s   10.244.0.92    aks-system-30288723-vmss000000   <none>           <none>
cron-insert-29837370-jjxwq               0/1     Completed   0          18s     10.244.0.248   aks-system-30288723-vmss000000   <none>           <none>
cron-resumen-29837370-gmdnp              0/1     Completed   0          18s     10.244.0.67    aks-system-30288723-vmss000000   <none>           <none>
cron-resumen-consumer-867478f48f-npp8q   1/1     Running     0          2m14s   10.244.0.36    aks-system-30288723-vmss000000   <none>           <none>
cursos-service-54dfc7b68c-bq8p9          1/1     Running     0          92s     10.244.0.95    aks-system-30288723-vmss000000   <none>           <none>
cursos-service-54dfc7b68c-nwdxw          1/1     Running     0          2m14s   10.244.0.138   aks-system-30288723-vmss000000   <none>           <none>
estudiantes-service-6b9df98b75-225ln     1/1     Running     0          91s     10.244.0.234   aks-system-30288723-vmss000000   <none>           <none>
estudiantes-service-6b9df98b75-zvxgb     1/1     Running     0          2m14s   10.244.0.243   aks-system-30288723-vmss000000   <none>           <none>
gateway-667bb95dfb-jkh65                 1/1     Running     0          91s     10.244.0.141   aks-system-30288723-vmss000000   <none>           <none>
gateway-667bb95dfb-kzc7d                 1/1     Running     0          2m13s   10.244.0.27    aks-system-30288723-vmss000000   <none>           <none>
inscripciones-consumer-8b9c9bb65-r4phv   1/1     Running     0          2m14s   10.244.0.81    aks-system-30288723-vmss000000   <none>           <none>
inscripciones-service-5cff7c98f9-4r5p8   1/1     Running     0          2m14s   10.244.0.104   aks-system-30288723-vmss000000   <none>           <none>
inscripciones-service-5cff7c98f9-mrjkz   1/1     Running     0          92s     10.244.0.210   aks-system-30288723-vmss000000   <none>           <none>
postgresql-0                             1/1     Running     0          92s     10.244.0.85    aks-system-30288723-vmss000000   <none>           <none>
rabbitmq-0                               1/1     Running     0          91s     10.244.0.11    aks-system-30288723-vmss000000   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     13m
cursos-service          1               N/A               1                     13m
estudiantes-service     1               N/A               1                     13m
gateway                 1               N/A               1                     13m
inscripciones-service   1               N/A               1                     13m
postgresql              N/A             1                 1                     13m
rabbitmq                N/A             1                 1                     13m
```

### Salida de kubectl drain

```
node/aks-system-30288723-vmss000001 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/azure-cns-25f82, kube-system/azure-ip-masq-agent-k5zkm, kube-system/cloud-node-manager-7t8lj, kube-system/csi-azuredisk-node-p7bln, kube-system/csi-azurefile-node-l9cn4, kube-system/kube-proxy-s98n7, velero/node-agent-jd8m9
evicting pod argocd/argocd-application-controller-0
evicting pod kube-system/coredns-5d474ff6db-7qb5x
evicting pod kube-system/konnectivity-agent-autoscaler-57c596c6fd-hfh78
evicting pod kube-system/coredns-5d474ff6db-86bjp
evicting pod argo-rollouts/argo-rollouts-67cbbf7967-hlhfq
evicting pod argo-rollouts/argo-rollouts-67cbbf7967-thn6v
evicting pod sa-p8/cron-resumen-29837360-2vzh7
evicting pod kube-system/konnectivity-agent-57b68bb5bd-kz2xt
evicting pod kube-system/konnectivity-agent-57b68bb5bd-8xzdj
evicting pod sa-p8/gateway-667bb95dfb-4wrww
evicting pod sa-p8/cron-resumen-29837360-hnk9f
evicting pod sa-p8/cron-resumen-consumer-867478f48f-5q7c9
evicting pod sa-p8/cursos-service-54dfc7b68c-9l7v8
evicting pod kube-system/metrics-server-85768b658b-l254s
evicting pod sa-p8/inscripciones-service-5cff7c98f9-bwmdr
evicting pod velero/velero-577cd7f6d4-plr26
evicting pod sa-p8/inscripciones-consumer-8b9c9bb65-7bb2q
evicting pod sa-p8/estudiantes-service-6b9df98b75-rf75g
evicting pod kube-system/metrics-server-85768b658b-mg6hg
evicting pod sa-p8/gateway-667bb95dfb-fqdh7
evicting pod argocd/argocd-applicationset-controller-58b8dccbc9-jrxlq
evicting pod argocd/argocd-dex-server-5ddff64d4c-twfgz
evicting pod argocd/argocd-notifications-controller-6b4645cfc-74mfk
evicting pod argocd/argocd-redis-6cfcdf9796-fg49g
evicting pod kube-system/sealed-secrets-controller-5d847f4b47-h24nj
evicting pod argocd/argocd-repo-server-7f88cf5b58-rq5pp
evicting pod argocd/argocd-server-86cf644d68-bgjtr
evicting pod kyverno/kyverno-admission-controller-644db5f8f4-tcbnb
evicting pod sa-p8/auth-service-c7d97959f-hzssp
evicting pod sa-p8/auth-service-c7d97959f-ng2sb
evicting pod kyverno/kyverno-background-controller-6dcbb8f98-4qsvl
evicting pod kyverno/kyverno-cleanup-controller-79bc549cd7-mqbvd
evicting pod kyverno/kyverno-migrate-resources-vgvvt
evicting pod kyverno/kyverno-reports-controller-77748cd6dd-fhh26
evicting pod sa-p8/cron-insert-29837366-slhhb
evicting pod sa-p8/postgresql-0
evicting pod sa-p8/cron-resumen-29837360-2sznr
evicting pod sa-p8/inscripciones-service-5cff7c98f9-zmqsj
evicting pod kube-system/coredns-autoscaler-6769f8f9b-xs5qp
evicting pod sa-p8/rabbitmq-0
evicting pod sa-p8/cursos-service-54dfc7b68c-tfffz
evicting pod sa-p8/estudiantes-service-6b9df98b75-rm75n
pod/cron-resumen-29837360-2vzh7 evicted
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 03:28:05.171833   11768 request.go:729] Waited for 1.018815s due to client-side throttling, not priority and fairness, request: POST:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/argocd/pods/argocd-notifications-controller-6b4645cfc-74mfk/eviction
error when evicting pods/"auth-service-c7d97959f-ng2sb" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"inscripciones-service-5cff7c98f9-zmqsj" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"cursos-service-54dfc7b68c-tfffz" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"coredns-5d474ff6db-86bjp" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-l254s
pod/kyverno-admission-controller-644db5f8f4-tcbnb evicted
error when evicting pods/"gateway-667bb95dfb-4wrww" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"konnectivity-agent-57b68bb5bd-8xzdj" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"estudiantes-service-6b9df98b75-rm75n" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/kyverno-background-controller-6dcbb8f98-4qsvl evicted
pod/kyverno-cleanup-controller-79bc549cd7-mqbvd evicted
pod/kyverno-migrate-resources-vgvvt evicted
pod/kyverno-reports-controller-77748cd6dd-fhh26 evicted
evicting pod sa-p8/auth-service-c7d97959f-ng2sb
error when evicting pods/"auth-service-c7d97959f-ng2sb" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-insert-29837366-slhhb evicted
pod/sealed-secrets-controller-5d847f4b47-h24nj evicted
evicting pod sa-p8/inscripciones-service-5cff7c98f9-zmqsj
error when evicting pods/"inscripciones-service-5cff7c98f9-zmqsj" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-resumen-29837360-2sznr evicted
evicting pod sa-p8/cursos-service-54dfc7b68c-tfffz
error when evicting pods/"cursos-service-54dfc7b68c-tfffz" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/coredns-5d474ff6db-86bjp
pod/konnectivity-agent-autoscaler-57c596c6fd-hfh78 evicted
evicting pod sa-p8/gateway-667bb95dfb-4wrww
I0924 03:28:15.247427   11768 request.go:729] Waited for 5.8082428s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/argo-rollouts/pods/argo-rollouts-67cbbf7967-hlhfq
error when evicting pods/"gateway-667bb95dfb-4wrww" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/konnectivity-agent-57b68bb5bd-8xzdj
evicting pod sa-p8/estudiantes-service-6b9df98b75-rm75n
pod/coredns-autoscaler-6769f8f9b-xs5qp evicted
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/metrics-server-85768b658b-mg6hg evicted
pod/cron-resumen-29837360-hnk9f evicted
pod/coredns-5d474ff6db-7qb5x evicted
evicting pod sa-p8/auth-service-c7d97959f-ng2sb
error when evicting pods/"auth-service-c7d97959f-ng2sb" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/inscripciones-service-5cff7c98f9-zmqsj
error when evicting pods/"inscripciones-service-5cff7c98f9-zmqsj" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/cursos-service-54dfc7b68c-tfffz
evicting pod sa-p8/gateway-667bb95dfb-4wrww
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/auth-service-c7d97959f-ng2sb
error when evicting pods/"auth-service-c7d97959f-ng2sb" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/inscripciones-service-5cff7c98f9-zmqsj
pod/coredns-5d474ff6db-86bjp evicted
I0924 03:28:25.248020   11768 request.go:729] Waited for 4.8422584s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/gateway-667bb95dfb-4wrww
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/auth-service-c7d97959f-ng2sb
error when evicting pods/"auth-service-c7d97959f-ng2sb" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/auth-service-c7d97959f-ng2sb
error when evicting pods/"auth-service-c7d97959f-ng2sb" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 03:28:35.447805   11768 request.go:729] Waited for 4.9319017s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/cursos-service-54dfc7b68c-9l7v8
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/auth-service-c7d97959f-ng2sb
error when evicting pods/"auth-service-c7d97959f-ng2sb" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/auth-service-c7d97959f-ng2sb
error when evicting pods/"auth-service-c7d97959f-ng2sb" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/konnectivity-agent-57b68bb5bd-kz2xt evicted
I0924 03:28:45.647648   11768 request.go:729] Waited for 4.9338888s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-z9st676j.hcp.eastus.azmk8s.io:443/api/v1/namespaces/kube-system/pods/konnectivity-agent-57b68bb5bd-8xzdj
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/inscripciones-service-5cff7c98f9-bwmdr evicted
pod/auth-service-c7d97959f-hzssp evicted
pod/argocd-repo-server-7f88cf5b58-rq5pp evicted
pod/argocd-application-controller-0 evicted
pod/postgresql-0 evicted
evicting pod sa-p8/auth-service-c7d97959f-ng2sb
error when evicting pods/"auth-service-c7d97959f-ng2sb" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/argocd-dex-server-5ddff64d4c-twfgz evicted
pod/argocd-server-86cf644d68-bgjtr evicted
pod/velero-577cd7f6d4-plr26 evicted
pod/inscripciones-service-5cff7c98f9-zmqsj evicted
pod/cursos-service-54dfc7b68c-tfffz evicted
pod/rabbitmq-0 evicted
pod/inscripciones-consumer-8b9c9bb65-7bb2q evicted
pod/cron-resumen-consumer-867478f48f-5q7c9 evicted
pod/estudiantes-service-6b9df98b75-rf75g evicted
pod/argo-rollouts-67cbbf7967-hlhfq evicted
pod/cursos-service-54dfc7b68c-9l7v8 evicted
pod/konnectivity-agent-57b68bb5bd-8xzdj evicted
pod/estudiantes-service-6b9df98b75-rm75n evicted
pod/argocd-notifications-controller-6b4645cfc-74mfk evicted
pod/argo-rollouts-67cbbf7967-thn6v evicted
pod/argocd-redis-6cfcdf9796-fg49g evicted
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/gateway-667bb95dfb-fqdh7 evicted
pod/argocd-applicationset-controller-58b8dccbc9-jrxlq evicted
pod/gateway-667bb95dfb-4wrww evicted
evicting pod sa-p8/auth-service-c7d97959f-ng2sb
error when evicting pods/"auth-service-c7d97959f-ng2sb" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/auth-service-c7d97959f-ng2sb
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-l254s
error when evicting pods/"metrics-server-85768b658b-l254s" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-l254s
pod/metrics-server-85768b658b-l254s evicted
pod/auth-service-c7d97959f-ng2sb evicted
node/aks-system-30288723-vmss000001 drained
```

### Registro con marcas de tiempo

```

2026-09-24T09:27:48Z | prueba-nodo: escenario=stateful nodo a drenar=aks-system-30288723-vmss000001 (postgresql-0 esta en aks-system-30288723-vmss000001)
2026-09-24T09:28:02Z | prueba-nodo: sondeo en marcha (linea base 10 s)
2026-09-24T09:28:02Z | prueba-nodo: kubectl drain aks-system-30288723-vmss000001 --ignore-daemonsets --delete-emptydir-data --timeout=300s
2026-09-24T09:29:30Z | prueba-nodo: drain terminado (codigo 0)
2026-09-24T09:29:50Z | prueba-nodo: todos los workloads Ready con un solo nodo
2026-09-24T09:30:01Z | prueba-nodo: uncordon aks-system-30288723-vmss000001

```
