# Prueba de perdida de nodo - evidencia automatica

## Escenario A - perdida de un nodo con replicas sin estado

Generado por `P9/scripts/prueba-perdida-nodo.ps1 -Scenario stateless` (todas las horas UTC).

| Campo | Valor |
|---|---|
| Nodo drenado | `aks-system-35358252-vmss000000` (postgresql-0 estaba en `aks-system-35358252-vmss000001`) |
| Hora de inicio del drenaje | 2026-09-24T07:59:08Z |
| Hora de fin del drenaje | 2026-09-24T08:00:29Z (codigo de salida de kubectl drain: 0) |
| Workloads Ready sin el nodo | 2026-09-24T08:00:31Z |
| Uncordon | 2026-09-24T08:00:42Z |
| Replicas configuradas | 2 por microservicio (gateway = Rollout), 1 PostgreSQL, 1 RabbitMQ |
| PDB observado | `minAvailable: 1` en los 5 servicios; `maxUnavailable: 1` en PostgreSQL y RabbitMQ |
| Anti-afinidad | `podAntiAffinity preferred` por `kubernetes.io/hostname` (una replica por nodo) |
| Sondeo | desde esta maquina, IP publica del gateway, 2 endpoints cada ~1 s |

### Resultado del sondeo durante toda la prueba

```

Endpoint Total Errores Disponibilidad MaxErroresSeguidos InicioRacha P95ms
-------- ----- ------- -------------- ------------------ ----------- -----
/health    142       0 100.00%                         0                74
/cursos    142       0 100.00%                         0                75
```

Respuestas no exitosas (si las hubo):

```
(ninguna: todas las respuestas fueron HTTP 200)
```

### Estado ANTES del drenaje

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-35358252-vmss000000   Ready    <none>   24h   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-35358252-vmss000001   Ready    <none>   24h   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS   AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-j595w             1/1     Running     0          4m49s   10.244.1.189   aks-system-35358252-vmss000000   <none>           <none>
auth-service-c7d97959f-sh4bp             1/1     Running     0          4m55s   10.244.0.38    aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837274-jc485               0/1     Completed   0          4m58s   10.244.0.86    aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837276-bzz47               0/1     Completed   0          2m58s   10.244.0.123   aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837278-vg66d               0/1     Completed   0          58s     10.244.0.179   aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-29837230-hqrwt              0/1     Completed   0          48m     10.244.1.106   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837240-jr7f9              0/1     Completed   0          38m     10.244.1.169   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837250-89s2q              0/1     Error       0          28m     10.244.1.224   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837250-m2s74              0/1     Error       0          28m     10.244.1.142   aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-29837270-l54gq              0/1     Completed   0          8m3s    10.244.0.218   aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-consumer-867478f48f-m95z7   1/1     Running     0          37m     10.244.1.101   aks-system-35358252-vmss000000   <none>           <none>
cursos-service-54dfc7b68c-9ggqs          1/1     Running     0          4m49s   10.244.1.85    aks-system-35358252-vmss000000   <none>           <none>
cursos-service-54dfc7b68c-gp2z2          1/1     Running     0          4m55s   10.244.0.23    aks-system-35358252-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-9gtms     1/1     Running     0          4m55s   10.244.0.148   aks-system-35358252-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-9vx4r     1/1     Running     0          4m49s   10.244.1.105   aks-system-35358252-vmss000000   <none>           <none>
gateway-667bb95dfb-dlj26                 1/1     Running     0          3m23s   10.244.0.146   aks-system-35358252-vmss000001   <none>           <none>
gateway-667bb95dfb-dt69d                 1/1     Running     0          4m54s   10.244.0.233   aks-system-35358252-vmss000001   <none>           <none>
inscripciones-consumer-8b9c9bb65-wsdhz   1/1     Running     0          22m     10.244.0.69    aks-system-35358252-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-mq2xx   1/1     Running     0          4m49s   10.244.1.203   aks-system-35358252-vmss000000   <none>           <none>
inscripciones-service-5cff7c98f9-vwwtc   1/1     Running     0          4m55s   10.244.0.219   aks-system-35358252-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0          4m53s   10.244.0.246   aks-system-35358252-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0          4m42s   10.244.0.2     aks-system-35358252-vmss000001   <none>           <none>

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
aks-system-35358252-vmss000000   Ready,SchedulingDisabled   <none>   24h   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-35358252-vmss000001   Ready                      <none>   24h   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS   AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-kjlcx             1/1     Running     0          50s     10.244.0.237   aks-system-35358252-vmss000001   <none>           <none>
auth-service-c7d97959f-sh4bp             1/1     Running     0          6m29s   10.244.0.38    aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837276-bzz47               0/1     Completed   0          4m32s   10.244.0.123   aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837278-vg66d               0/1     Completed   0          2m32s   10.244.0.179   aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837280-mtp2w               0/1     Completed   0          32s     10.244.0.39    aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-29837270-l54gq              0/1     Completed   0          9m37s   10.244.0.218   aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-29837280-27d4g              0/1     Completed   0          32s     10.244.0.159   aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-consumer-867478f48f-jkj9z   1/1     Running     0          46s     10.244.0.8     aks-system-35358252-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-gp2z2          1/1     Running     0          6m29s   10.244.0.23    aks-system-35358252-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-nhjcw          1/1     Running     0          47s     10.244.0.28    aks-system-35358252-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-9gtms     1/1     Running     0          6m29s   10.244.0.148   aks-system-35358252-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-tqkjl     1/1     Running     0          48s     10.244.0.34    aks-system-35358252-vmss000001   <none>           <none>
gateway-667bb95dfb-dlj26                 1/1     Running     0          4m57s   10.244.0.146   aks-system-35358252-vmss000001   <none>           <none>
gateway-667bb95dfb-dt69d                 1/1     Running     0          6m28s   10.244.0.233   aks-system-35358252-vmss000001   <none>           <none>
inscripciones-consumer-8b9c9bb65-wsdhz   1/1     Running     0          23m     10.244.0.69    aks-system-35358252-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-qjs6r   1/1     Running     0          48s     10.244.0.236   aks-system-35358252-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-vwwtc   1/1     Running     0          6m29s   10.244.0.219   aks-system-35358252-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0          6m27s   10.244.0.246   aks-system-35358252-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0          6m16s   10.244.0.2     aks-system-35358252-vmss000001   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     23h
cursos-service          1               N/A               1                     23h
estudiantes-service     1               N/A               1                     23h
gateway                 1               N/A               1                     23h
inscripciones-service   1               N/A               1                     23h
postgresql              N/A             1                 1                     23h
rabbitmq                N/A             1                 1                     23h
```

### Estado DESPUES del uncordon

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-35358252-vmss000000   Ready    <none>   24h   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-35358252-vmss000001   Ready    <none>   24h   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS   AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-kjlcx             1/1     Running     0          76s     10.244.0.237   aks-system-35358252-vmss000001   <none>           <none>
auth-service-c7d97959f-sh4bp             1/1     Running     0          6m55s   10.244.0.38    aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837276-bzz47               0/1     Completed   0          4m58s   10.244.0.123   aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837278-vg66d               0/1     Completed   0          2m58s   10.244.0.179   aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837280-mtp2w               0/1     Completed   0          58s     10.244.0.39    aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-29837270-l54gq              0/1     Completed   0          10m     10.244.0.218   aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-29837280-27d4g              0/1     Completed   0          58s     10.244.0.159   aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-consumer-867478f48f-jkj9z   1/1     Running     0          72s     10.244.0.8     aks-system-35358252-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-gp2z2          1/1     Running     0          6m55s   10.244.0.23    aks-system-35358252-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-nhjcw          1/1     Running     0          73s     10.244.0.28    aks-system-35358252-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-9gtms     1/1     Running     0          6m55s   10.244.0.148   aks-system-35358252-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-tqkjl     1/1     Running     0          74s     10.244.0.34    aks-system-35358252-vmss000001   <none>           <none>
gateway-667bb95dfb-dlj26                 1/1     Running     0          5m23s   10.244.0.146   aks-system-35358252-vmss000001   <none>           <none>
gateway-667bb95dfb-dt69d                 1/1     Running     0          6m54s   10.244.0.233   aks-system-35358252-vmss000001   <none>           <none>
inscripciones-consumer-8b9c9bb65-wsdhz   1/1     Running     0          24m     10.244.0.69    aks-system-35358252-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-qjs6r   1/1     Running     0          74s     10.244.0.236   aks-system-35358252-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-vwwtc   1/1     Running     0          6m55s   10.244.0.219   aks-system-35358252-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0          6m53s   10.244.0.246   aks-system-35358252-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0          6m42s   10.244.0.2     aks-system-35358252-vmss000001   <none>           <none>

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
node/aks-system-35358252-vmss000000 cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/azure-cns-xhbcg, kube-system/azure-ip-masq-agent-hldrp, kube-system/cloud-node-manager-pflvz, kube-system/csi-azuredisk-node-x2r7w, kube-system/csi-azurefile-node-pxk88, kube-system/kube-proxy-stdhk, velero/node-agent-jqmgp
evicting pod argo-rollouts/argo-rollouts-67cbbf7967-q79s2
evicting pod argocd/argocd-notifications-controller-6b4645cfc-xxlt4
evicting pod argocd/argocd-server-86cf644d68-wttx2
evicting pod argocd/argocd-redis-6cfcdf9796-2wc8v
evicting pod argocd/argocd-repo-server-7f88cf5b58-nkzv7
evicting pod sa-p8/inscripciones-service-5cff7c98f9-mq2xx
evicting pod argo-rollouts/argo-rollouts-67cbbf7967-txnt5
evicting pod kube-system/konnectivity-agent-5b85b4bcfb-9d945
evicting pod kube-system/coredns-5d474ff6db-mlcx5
evicting pod sa-p8/auth-service-c7d97959f-j595w
evicting pod kube-system/konnectivity-agent-5b85b4bcfb-nrzgx
evicting pod kube-system/konnectivity-agent-autoscaler-57c596c6fd-jdg72
evicting pod kube-system/coredns-5d474ff6db-46pjg
evicting pod kube-system/metrics-server-85768b658b-bqllh
evicting pod kube-system/metrics-server-85768b658b-x8b7w
evicting pod kube-system/sealed-secrets-controller-5d847f4b47-xk6sm
evicting pod kyverno/kyverno-admission-controller-644db5f8f4-6mkss
evicting pod argocd/argocd-application-controller-0
evicting pod argocd/argocd-applicationset-controller-58b8dccbc9-jzldm
evicting pod sa-p8/cron-resumen-29837230-hqrwt
evicting pod kube-system/coredns-autoscaler-6769f8f9b-2tn2h
evicting pod sa-p8/cron-resumen-29837240-jr7f9
evicting pod argocd/argocd-dex-server-5ddff64d4c-mjfsg
evicting pod sa-p8/cron-resumen-29837250-89s2q
evicting pod sa-p8/cron-resumen-29837250-m2s74
evicting pod sa-p8/cursos-service-54dfc7b68c-9ggqs
evicting pod sa-p8/estudiantes-service-6b9df98b75-9vx4r
evicting pod kyverno/kyverno-cleanup-controller-79bc549cd7-hnszf
evicting pod sa-p8/cron-resumen-consumer-867478f48f-m95z7
error when evicting pods/"coredns-5d474ff6db-mlcx5" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-resumen-29837230-hqrwt evicted
I0924 01:59:11.266973   20592 request.go:729] Waited for 1.1992682s due to client-side throttling, not priority and fairness, request: POST:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/cron-resumen-29837240-jr7f9/eviction
error when evicting pods/"konnectivity-agent-5b85b4bcfb-9d945" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-resumen-29837240-jr7f9 evicted
evicting pod kube-system/coredns-5d474ff6db-mlcx5
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-resumen-29837250-89s2q evicted
pod/cron-resumen-29837250-m2s74 evicted
evicting pod kube-system/konnectivity-agent-5b85b4bcfb-9d945
pod/sealed-secrets-controller-5d847f4b47-xk6sm evicted
pod/kyverno-admission-controller-644db5f8f4-6mkss evicted
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/coredns-5d474ff6db-46pjg evicted
I0924 01:59:21.348615   20592 request.go:729] Waited for 4.7325014s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/inscripciones-service-5cff7c98f9-mq2xx
pod/kyverno-cleanup-controller-79bc549cd7-hnszf evicted
pod/coredns-autoscaler-6769f8f9b-2tn2h evicted
pod/konnectivity-agent-autoscaler-57c596c6fd-jdg72 evicted
pod/metrics-server-85768b658b-bqllh evicted
pod/coredns-5d474ff6db-mlcx5 evicted
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 01:59:31.355321   20592 request.go:729] Waited for 3.1369291s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/argo-rollouts/pods/argo-rollouts-67cbbf7967-txnt5
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 01:59:41.548812   20592 request.go:729] Waited for 3.1254315s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/inscripciones-service-5cff7c98f9-mq2xx
pod/konnectivity-agent-5b85b4bcfb-nrzgx evicted
pod/argocd-notifications-controller-6b4645cfc-xxlt4 evicted
pod/auth-service-c7d97959f-j595w evicted
pod/inscripciones-service-5cff7c98f9-mq2xx evicted
pod/argocd-dex-server-5ddff64d4c-mjfsg evicted
pod/argocd-application-controller-0 evicted
pod/cursos-service-54dfc7b68c-9ggqs evicted
pod/argocd-repo-server-7f88cf5b58-nkzv7 evicted
pod/estudiantes-service-6b9df98b75-9vx4r evicted
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/argocd-applicationset-controller-58b8dccbc9-jzldm evicted
pod/argocd-server-86cf644d68-wttx2 evicted
pod/cron-resumen-consumer-867478f48f-m95z7 evicted
pod/argocd-redis-6cfcdf9796-2wc8v evicted
pod/argo-rollouts-67cbbf7967-q79s2 evicted
pod/argo-rollouts-67cbbf7967-txnt5 evicted
pod/konnectivity-agent-5b85b4bcfb-9d945 evicted
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-x8b7w
error when evicting pods/"metrics-server-85768b658b-x8b7w" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-x8b7w
pod/metrics-server-85768b658b-x8b7w evicted
node/aks-system-35358252-vmss000000 drained
```

### Registro con marcas de tiempo

```

2026-09-24T07:58:54Z | prueba-nodo: escenario=stateless nodo a drenar=aks-system-35358252-vmss000000 (postgresql-0 esta en aks-system-35358252-vmss000001)
2026-09-24T07:59:08Z | prueba-nodo: sondeo en marcha (linea base 10 s)
2026-09-24T07:59:08Z | prueba-nodo: kubectl drain aks-system-35358252-vmss000000 --ignore-daemonsets --delete-emptydir-data --timeout=300s
2026-09-24T08:00:29Z | prueba-nodo: drain terminado (codigo 0)
2026-09-24T08:00:31Z | prueba-nodo: todos los workloads Ready con un solo nodo
2026-09-24T08:00:42Z | prueba-nodo: uncordon aks-system-35358252-vmss000000

```

## Escenario B - perdida del nodo que aloja PostgreSQL (peor caso, 1 replica)

Generado por `P9/scripts/prueba-perdida-nodo.ps1 -Scenario stateful` (todas las horas UTC).

| Campo | Valor |
|---|---|
| Nodo drenado | `aks-system-35358252-vmss000001` (postgresql-0 estaba en `aks-system-35358252-vmss000001`) |
| Hora de inicio del drenaje | 2026-09-24T08:01:46Z |
| Hora de fin del drenaje | 2026-09-24T08:03:31Z (codigo de salida de kubectl drain: 0) |
| Workloads Ready sin el nodo | 2026-09-24T08:04:03Z |
| Uncordon | 2026-09-24T08:04:15Z |
| Replicas configuradas | 2 por microservicio (gateway = Rollout), 1 PostgreSQL, 1 RabbitMQ |
| PDB observado | `minAvailable: 1` en los 5 servicios; `maxUnavailable: 1` en PostgreSQL y RabbitMQ |
| Anti-afinidad | `podAntiAffinity preferred` por `kubernetes.io/hostname` (una replica por nodo) |
| Sondeo | desde esta maquina, IP publica del gateway, 2 endpoints cada ~1 s |

### Resultado del sondeo durante toda la prueba

```

Endpoint Total Errores Disponibilidad MaxErroresSeguidos InicioRacha P95ms
-------- ----- ------- -------------- ------------------ ----------- -----
/health    201       0 100.00%                         0                81
/cursos    201      65 67.66%                         65 08:02:23       75
```

Respuestas no exitosas (si las hubo):

```
08:02:23 /cursos -> 504 (71 ms)
08:02:24 /cursos -> 504 (64 ms)
08:02:25 /cursos -> 504 (67 ms)
08:02:26 /cursos -> 504 (73 ms)
08:02:26 /cursos -> 504 (74 ms)
08:02:27 /cursos -> 500 (89 ms)
08:02:28 /cursos -> 500 (63 ms)
08:02:29 /cursos -> 500 (73 ms)
08:02:30 /cursos -> 500 (77 ms)
08:02:31 /cursos -> 500 (60 ms)
08:02:32 /cursos -> 500 (61 ms)
08:02:32 /cursos -> 500 (61 ms)
08:02:33 /cursos -> 500 (61 ms)
08:02:34 /cursos -> 500 (62 ms)
08:02:35 /cursos -> 500 (60 ms)
08:02:36 /cursos -> 500 (62 ms)
08:02:37 /cursos -> 500 (63 ms)
08:02:37 /cursos -> 500 (63 ms)
08:02:38 /cursos -> 500 (61 ms)
08:02:39 /cursos -> 500 (63 ms)
08:02:40 /cursos -> 500 (61 ms)
08:02:41 /cursos -> 500 (61 ms)
08:02:42 /cursos -> 500 (61 ms)
08:02:42 /cursos -> 500 (61 ms)
08:02:43 /cursos -> 500 (61 ms)
08:02:44 /cursos -> 500 (60 ms)
08:02:45 /cursos -> 500 (61 ms)
08:02:46 /cursos -> 500 (61 ms)
08:02:47 /cursos -> 500 (59 ms)
08:02:47 /cursos -> 500 (62 ms)
08:02:48 /cursos -> 500 (62 ms)
08:02:49 /cursos -> 500 (61 ms)
08:02:50 /cursos -> 500 (61 ms)
08:02:51 /cursos -> 500 (61 ms)
08:02:52 /cursos -> 500 (60 ms)
08:02:52 /cursos -> 500 (60 ms)
08:02:54 /cursos -> 500 (1084 ms)
08:02:55 /cursos -> 500 (60 ms)
08:02:56 /cursos -> 500 (60 ms)
08:02:57 /cursos -> 500 (60 ms)
08:02:58 /cursos -> 500 (60 ms)
08:02:58 /cursos -> 500 (61 ms)
08:03:00 /cursos -> 500 (1068 ms)
08:03:01 /cursos -> 500 (62 ms)
08:03:02 /cursos -> 500 (83 ms)
08:03:03 /cursos -> 500 (65 ms)
08:03:04 /cursos -> 500 (70 ms)
08:03:05 /cursos -> 500 (61 ms)
08:03:05 /cursos -> 500 (59 ms)
08:03:07 /cursos -> 500 (1109 ms)
08:03:08 /cursos -> 500 (64 ms)
08:03:09 /cursos -> 500 (60 ms)
08:03:10 /cursos -> 500 (61 ms)
08:03:11 /cursos -> 500 (62 ms)
08:03:11 /cursos -> 500 (62 ms)
08:03:13 /cursos -> 500 (1078 ms)
08:03:14 /cursos -> 500 (61 ms)
08:03:15 /cursos -> 500 (61 ms)
08:03:16 /cursos -> 500 (63 ms)
08:03:17 /cursos -> 500 (60 ms)
08:03:18 /cursos -> 500 (59 ms)
08:03:18 /cursos -> 500 (60 ms)
08:03:20 /cursos -> 500 (1088 ms)
08:03:21 /cursos -> 500 (59 ms)
08:03:22 /cursos -> 500 (62 ms)
```

### Estado ANTES del drenaje

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-35358252-vmss000000   Ready    <none>   24h   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-35358252-vmss000001   Ready    <none>   24h   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS   AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-kjlcx             1/1     Running     0          113s    10.244.0.237   aks-system-35358252-vmss000001   <none>           <none>
auth-service-c7d97959f-sh4bp             1/1     Running     0          7m32s   10.244.0.38    aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837276-bzz47               0/1     Completed   0          5m35s   10.244.0.123   aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837278-vg66d               0/1     Completed   0          3m35s   10.244.0.179   aks-system-35358252-vmss000001   <none>           <none>
cron-insert-29837280-mtp2w               0/1     Completed   0          95s     10.244.0.39    aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-29837270-l54gq              0/1     Completed   0          10m     10.244.0.218   aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-29837280-27d4g              0/1     Completed   0          95s     10.244.0.159   aks-system-35358252-vmss000001   <none>           <none>
cron-resumen-consumer-867478f48f-jkj9z   1/1     Running     0          109s    10.244.0.8     aks-system-35358252-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-gp2z2          1/1     Running     0          7m32s   10.244.0.23    aks-system-35358252-vmss000001   <none>           <none>
cursos-service-54dfc7b68c-nhjcw          1/1     Running     0          110s    10.244.0.28    aks-system-35358252-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-9gtms     1/1     Running     0          7m32s   10.244.0.148   aks-system-35358252-vmss000001   <none>           <none>
estudiantes-service-6b9df98b75-tqkjl     1/1     Running     0          111s    10.244.0.34    aks-system-35358252-vmss000001   <none>           <none>
gateway-667bb95dfb-dlj26                 1/1     Running     0          6m      10.244.0.146   aks-system-35358252-vmss000001   <none>           <none>
gateway-667bb95dfb-dt69d                 1/1     Running     0          7m31s   10.244.0.233   aks-system-35358252-vmss000001   <none>           <none>
inscripciones-consumer-8b9c9bb65-wsdhz   1/1     Running     0          24m     10.244.0.69    aks-system-35358252-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-qjs6r   1/1     Running     0          111s    10.244.0.236   aks-system-35358252-vmss000001   <none>           <none>
inscripciones-service-5cff7c98f9-vwwtc   1/1     Running     0          7m32s   10.244.0.219   aks-system-35358252-vmss000001   <none>           <none>
postgresql-0                             1/1     Running     0          7m30s   10.244.0.246   aks-system-35358252-vmss000001   <none>           <none>
rabbitmq-0                               1/1     Running     0          7m19s   10.244.0.2     aks-system-35358252-vmss000001   <none>           <none>

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
aks-system-35358252-vmss000000   Ready                      <none>   24h   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-35358252-vmss000001   Ready,SchedulingDisabled   <none>   24h   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS      AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-8d8jq             1/1     Running     0             70s     10.244.1.211   aks-system-35358252-vmss000000   <none>           <none>
auth-service-c7d97959f-s9kql             1/1     Running     0             2m17s   10.244.1.224   aks-system-35358252-vmss000000   <none>           <none>
cron-insert-29837282-rzm5q               0/1     Completed   0             42s     10.244.1.241   aks-system-35358252-vmss000000   <none>           <none>
cron-insert-29837284-7m7xg               0/1     Completed   0             4s      10.244.1.43    aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-consumer-867478f48f-dn2m4   1/1     Running     1 (13s ago)   2m14s   10.244.1.231   aks-system-35358252-vmss000000   <none>           <none>
cursos-service-54dfc7b68c-dd8bm          1/1     Running     0             70s     10.244.1.223   aks-system-35358252-vmss000000   <none>           <none>
cursos-service-54dfc7b68c-tf8lb          1/1     Running     0             2m14s   10.244.1.234   aks-system-35358252-vmss000000   <none>           <none>
estudiantes-service-6b9df98b75-jxs2p     1/1     Running     0             70s     10.244.1.230   aks-system-35358252-vmss000000   <none>           <none>
estudiantes-service-6b9df98b75-tps74     1/1     Running     0             2m13s   10.244.1.36    aks-system-35358252-vmss000000   <none>           <none>
gateway-667bb95dfb-7sk5p                 1/1     Running     0             70s     10.244.1.202   aks-system-35358252-vmss000000   <none>           <none>
gateway-667bb95dfb-rjz8s                 1/1     Running     0             2m13s   10.244.1.19    aks-system-35358252-vmss000000   <none>           <none>
inscripciones-consumer-8b9c9bb65-chfpz   1/1     Running     1 (11s ago)   2m12s   10.244.1.150   aks-system-35358252-vmss000000   <none>           <none>
inscripciones-service-5cff7c98f9-cwpr2   1/1     Running     0             2m12s   10.244.1.16    aks-system-35358252-vmss000000   <none>           <none>
inscripciones-service-5cff7c98f9-ttzlm   1/1     Running     0             70s     10.244.1.251   aks-system-35358252-vmss000000   <none>           <none>
postgresql-0                             1/1     Running     0             70s     10.244.1.222   aks-system-35358252-vmss000000   <none>           <none>
rabbitmq-0                               1/1     Running     0             70s     10.244.1.39    aks-system-35358252-vmss000000   <none>           <none>

NAME                    MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
auth-service            1               N/A               1                     23h
cursos-service          1               N/A               1                     23h
estudiantes-service     1               N/A               1                     23h
gateway                 1               N/A               1                     23h
inscripciones-service   1               N/A               1                     23h
postgresql              N/A             1                 1                     23h
rabbitmq                N/A             1                 1                     23h
```

### Estado DESPUES del uncordon

```nNAME                             STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
aks-system-35358252-vmss000000   Ready    <none>   24h   v1.35.8   10.224.0.4    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2
aks-system-35358252-vmss000001   Ready    <none>   24h   v1.35.8   10.224.0.5    <none>        Ubuntu 24.04.5 LTS   6.8.0-1067-azure   containerd://2.3.3-2

NAME                                     READY   STATUS      RESTARTS      AGE     IP             NODE                             NOMINATED NODE   READINESS GATES
auth-service-c7d97959f-8d8jq             1/1     Running     0             97s     10.244.1.211   aks-system-35358252-vmss000000   <none>           <none>
auth-service-c7d97959f-s9kql             1/1     Running     0             2m44s   10.244.1.224   aks-system-35358252-vmss000000   <none>           <none>
cron-insert-29837282-rzm5q               0/1     Completed   0             69s     10.244.1.241   aks-system-35358252-vmss000000   <none>           <none>
cron-insert-29837284-7m7xg               0/1     Completed   0             31s     10.244.1.43    aks-system-35358252-vmss000000   <none>           <none>
cron-resumen-consumer-867478f48f-dn2m4   1/1     Running     1 (40s ago)   2m41s   10.244.1.231   aks-system-35358252-vmss000000   <none>           <none>
cursos-service-54dfc7b68c-dd8bm          1/1     Running     0             97s     10.244.1.223   aks-system-35358252-vmss000000   <none>           <none>
cursos-service-54dfc7b68c-tf8lb          1/1     Running     0             2m41s   10.244.1.234   aks-system-35358252-vmss000000   <none>           <none>
estudiantes-service-6b9df98b75-jxs2p     1/1     Running     0             97s     10.244.1.230   aks-system-35358252-vmss000000   <none>           <none>
estudiantes-service-6b9df98b75-tps74     1/1     Running     0             2m40s   10.244.1.36    aks-system-35358252-vmss000000   <none>           <none>
gateway-667bb95dfb-7sk5p                 1/1     Running     0             97s     10.244.1.202   aks-system-35358252-vmss000000   <none>           <none>
gateway-667bb95dfb-rjz8s                 1/1     Running     0             2m40s   10.244.1.19    aks-system-35358252-vmss000000   <none>           <none>
inscripciones-consumer-8b9c9bb65-chfpz   1/1     Running     1 (38s ago)   2m39s   10.244.1.150   aks-system-35358252-vmss000000   <none>           <none>
inscripciones-service-5cff7c98f9-cwpr2   1/1     Running     0             2m39s   10.244.1.16    aks-system-35358252-vmss000000   <none>           <none>
inscripciones-service-5cff7c98f9-ttzlm   1/1     Running     0             97s     10.244.1.251   aks-system-35358252-vmss000000   <none>           <none>
postgresql-0                             1/1     Running     0             97s     10.244.1.222   aks-system-35358252-vmss000000   <none>           <none>
rabbitmq-0                               1/1     Running     0             97s     10.244.1.39    aks-system-35358252-vmss000000   <none>           <none>

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
Warning: ignoring DaemonSet-managed Pods: kube-system/azure-cns-l5bn2, kube-system/azure-ip-masq-agent-64gd4, kube-system/cloud-node-manager-j5m7d, kube-system/csi-azuredisk-node-jktmz, kube-system/csi-azurefile-node-gxh2l, kube-system/kube-proxy-rs6tm, velero/node-agent-dc4vn
evicting pod argo-rollouts/argo-rollouts-67cbbf7967-f5xd5
evicting pod argo-rollouts/argo-rollouts-67cbbf7967-bh8g7
evicting pod kyverno/kyverno-migrate-resources-ztr7w
evicting pod velero/velero-577cd7f6d4-pbdzm
evicting pod argocd/argocd-application-controller-0
evicting pod argocd/argocd-applicationset-controller-58b8dccbc9-gpj6k
evicting pod kyverno/kyverno-reports-controller-77748cd6dd-s5fr4
evicting pod argocd/argocd-dex-server-5ddff64d4c-p8gzd
evicting pod sa-p8/auth-service-c7d97959f-kjlcx
evicting pod sa-p8/auth-service-c7d97959f-sh4bp
evicting pod argocd/argocd-notifications-controller-6b4645cfc-bhfpk
evicting pod sa-p8/cron-insert-29837276-bzz47
evicting pod argocd/argocd-redis-6cfcdf9796-rqllv
evicting pod sa-p8/cron-insert-29837278-vg66d
evicting pod argocd/argocd-repo-server-7f88cf5b58-6nrkk
evicting pod sa-p8/cron-insert-29837280-mtp2w
evicting pod argocd/argocd-server-86cf644d68-sn5lv
evicting pod sa-p8/cron-resumen-29837270-l54gq
evicting pod kube-system/coredns-5d474ff6db-h7228
evicting pod kube-system/coredns-5d474ff6db-pfrng
evicting pod sa-p8/cron-resumen-29837280-27d4g
evicting pod kube-system/coredns-autoscaler-6769f8f9b-njdv8
evicting pod sa-p8/cron-resumen-consumer-867478f48f-jkj9z
evicting pod sa-p8/cursos-service-54dfc7b68c-gp2z2
evicting pod kube-system/konnectivity-agent-5b85b4bcfb-4n8s8
evicting pod sa-p8/cursos-service-54dfc7b68c-nhjcw
evicting pod kube-system/konnectivity-agent-5b85b4bcfb-jg6kb
evicting pod sa-p8/estudiantes-service-6b9df98b75-9gtms
evicting pod kube-system/konnectivity-agent-autoscaler-57c596c6fd-5gvs2
evicting pod sa-p8/estudiantes-service-6b9df98b75-tqkjl
evicting pod sa-p8/gateway-667bb95dfb-dlj26
evicting pod sa-p8/gateway-667bb95dfb-dt69d
evicting pod sa-p8/inscripciones-consumer-8b9c9bb65-wsdhz
evicting pod sa-p8/inscripciones-service-5cff7c98f9-qjs6r
evicting pod sa-p8/inscripciones-service-5cff7c98f9-vwwtc
evicting pod kube-system/metrics-server-85768b658b-62t4x
evicting pod sa-p8/postgresql-0
evicting pod sa-p8/rabbitmq-0
evicting pod kube-system/metrics-server-85768b658b-bwrv2
evicting pod kyverno/kyverno-admission-controller-644db5f8f4-n58kf
evicting pod kyverno/kyverno-background-controller-6dcbb8f98-hn6hf
evicting pod kube-system/sealed-secrets-controller-5d847f4b47-k77p6
evicting pod kyverno/kyverno-cleanup-controller-79bc549cd7-pjv9m
pod/cron-insert-29837276-bzz47 evicted
pod/kyverno-migrate-resources-ztr7w evicted
error when evicting pods/"auth-service-c7d97959f-sh4bp" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-insert-29837278-vg66d evicted
I0924 02:01:48.227973    2208 request.go:729] Waited for 1.0041899s due to client-side throttling, not priority and fairness, request: POST:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/argocd/pods/argocd-repo-server-7f88cf5b58-6nrkk/eviction
error when evicting pods/"coredns-5d474ff6db-pfrng" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/kyverno-reports-controller-77748cd6dd-s5fr4 evicted
pod/cron-insert-29837280-mtp2w evicted
pod/argocd-server-86cf644d68-sn5lv evicted
pod/argocd-applicationset-controller-58b8dccbc9-gpj6k evicted
error when evicting pods/"cursos-service-54dfc7b68c-nhjcw" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-resumen-29837270-l54gq evicted
error when evicting pods/"konnectivity-agent-5b85b4bcfb-jg6kb" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/argocd-dex-server-5ddff64d4c-p8gzd evicted
pod/argocd-application-controller-0 evicted
error when evicting pods/"estudiantes-service-6b9df98b75-tqkjl" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/argocd-redis-6cfcdf9796-rqllv evicted
pod/argo-rollouts-67cbbf7967-f5xd5 evicted
error when evicting pods/"gateway-667bb95dfb-dt69d" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/velero-577cd7f6d4-pbdzm evicted
pod/argocd-notifications-controller-6b4645cfc-bhfpk evicted
pod/argo-rollouts-67cbbf7967-bh8g7 evicted
error when evicting pods/"inscripciones-service-5cff7c98f9-vwwtc" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cron-resumen-29837280-27d4g evicted
evicting pod sa-p8/auth-service-c7d97959f-sh4bp
pod/coredns-autoscaler-6769f8f9b-njdv8 evicted
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/estudiantes-service-6b9df98b75-9gtms evicted
pod/konnectivity-agent-autoscaler-57c596c6fd-5gvs2 evicted
error when evicting pods/"auth-service-c7d97959f-sh4bp" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/coredns-5d474ff6db-pfrng
error when evicting pods/"coredns-5d474ff6db-pfrng" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/metrics-server-85768b658b-62t4x evicted
evicting pod sa-p8/cursos-service-54dfc7b68c-nhjcw
error when evicting pods/"cursos-service-54dfc7b68c-nhjcw" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/konnectivity-agent-5b85b4bcfb-jg6kb
error when evicting pods/"konnectivity-agent-5b85b4bcfb-jg6kb" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/kyverno-admission-controller-644db5f8f4-n58kf evicted
evicting pod sa-p8/estudiantes-service-6b9df98b75-tqkjl
error when evicting pods/"estudiantes-service-6b9df98b75-tqkjl" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/kyverno-background-controller-6dcbb8f98-hn6hf evicted
evicting pod sa-p8/gateway-667bb95dfb-dt69d
error when evicting pods/"gateway-667bb95dfb-dt69d" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/sealed-secrets-controller-5d847f4b47-k77p6 evicted
pod/kyverno-cleanup-controller-79bc549cd7-pjv9m evicted
evicting pod sa-p8/inscripciones-service-5cff7c98f9-vwwtc
error when evicting pods/"inscripciones-service-5cff7c98f9-vwwtc" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/coredns-5d474ff6db-h7228 evicted
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 02:01:58.305681    2208 request.go:729] Waited for 2.9318368s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/postgresql-0
evicting pod sa-p8/auth-service-c7d97959f-sh4bp
evicting pod kube-system/coredns-5d474ff6db-pfrng
error when evicting pods/"coredns-5d474ff6db-pfrng" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/cursos-service-54dfc7b68c-nhjcw
error when evicting pods/"cursos-service-54dfc7b68c-nhjcw" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/konnectivity-agent-5b85b4bcfb-jg6kb
error when evicting pods/"konnectivity-agent-5b85b4bcfb-jg6kb" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/estudiantes-service-6b9df98b75-tqkjl
error when evicting pods/"estudiantes-service-6b9df98b75-tqkjl" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/gateway-667bb95dfb-dt69d
error when evicting pods/"gateway-667bb95dfb-dt69d" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/inscripciones-service-5cff7c98f9-vwwtc
error when evicting pods/"inscripciones-service-5cff7c98f9-vwwtc" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/coredns-5d474ff6db-pfrng
error when evicting pods/"coredns-5d474ff6db-pfrng" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/cursos-service-54dfc7b68c-nhjcw
error when evicting pods/"cursos-service-54dfc7b68c-nhjcw" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/konnectivity-agent-5b85b4bcfb-jg6kb
error when evicting pods/"konnectivity-agent-5b85b4bcfb-jg6kb" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/estudiantes-service-6b9df98b75-tqkjl
error when evicting pods/"estudiantes-service-6b9df98b75-tqkjl" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/gateway-667bb95dfb-dt69d
error when evicting pods/"gateway-667bb95dfb-dt69d" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/inscripciones-service-5cff7c98f9-vwwtc
error when evicting pods/"inscripciones-service-5cff7c98f9-vwwtc" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 02:02:08.506187    2208 request.go:729] Waited for 2.1388867s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/inscripciones-consumer-8b9c9bb65-wsdhz
evicting pod kube-system/coredns-5d474ff6db-pfrng
error when evicting pods/"coredns-5d474ff6db-pfrng" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/cursos-service-54dfc7b68c-nhjcw
error when evicting pods/"cursos-service-54dfc7b68c-nhjcw" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/konnectivity-agent-5b85b4bcfb-jg6kb
error when evicting pods/"konnectivity-agent-5b85b4bcfb-jg6kb" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/estudiantes-service-6b9df98b75-tqkjl
error when evicting pods/"estudiantes-service-6b9df98b75-tqkjl" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/gateway-667bb95dfb-dt69d
error when evicting pods/"gateway-667bb95dfb-dt69d" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/inscripciones-service-5cff7c98f9-vwwtc
error when evicting pods/"inscripciones-service-5cff7c98f9-vwwtc" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/coredns-5d474ff6db-pfrng
error when evicting pods/"coredns-5d474ff6db-pfrng" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/cursos-service-54dfc7b68c-nhjcw
error when evicting pods/"cursos-service-54dfc7b68c-nhjcw" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/konnectivity-agent-5b85b4bcfb-jg6kb
error when evicting pods/"konnectivity-agent-5b85b4bcfb-jg6kb" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/estudiantes-service-6b9df98b75-tqkjl
error when evicting pods/"estudiantes-service-6b9df98b75-tqkjl" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/gateway-667bb95dfb-dt69d
error when evicting pods/"gateway-667bb95dfb-dt69d" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/inscripciones-service-5cff7c98f9-vwwtc
error when evicting pods/"inscripciones-service-5cff7c98f9-vwwtc" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 02:02:18.705418    2208 request.go:729] Waited for 2.1343964s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/cursos-service-54dfc7b68c-gp2z2
evicting pod kube-system/coredns-5d474ff6db-pfrng
evicting pod sa-p8/cursos-service-54dfc7b68c-nhjcw
error when evicting pods/"cursos-service-54dfc7b68c-nhjcw" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/konnectivity-agent-5b85b4bcfb-jg6kb
pod/konnectivity-agent-5b85b4bcfb-4n8s8 evicted
evicting pod sa-p8/estudiantes-service-6b9df98b75-tqkjl
error when evicting pods/"estudiantes-service-6b9df98b75-tqkjl" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/gateway-667bb95dfb-dt69d
error when evicting pods/"gateway-667bb95dfb-dt69d" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/inscripciones-service-5cff7c98f9-vwwtc
error when evicting pods/"inscripciones-service-5cff7c98f9-vwwtc" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/cursos-service-54dfc7b68c-nhjcw
error when evicting pods/"cursos-service-54dfc7b68c-nhjcw" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/estudiantes-service-6b9df98b75-tqkjl
error when evicting pods/"estudiantes-service-6b9df98b75-tqkjl" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/coredns-5d474ff6db-pfrng evicted
evicting pod sa-p8/gateway-667bb95dfb-dt69d
error when evicting pods/"gateway-667bb95dfb-dt69d" -n "sa-p8" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod sa-p8/inscripciones-service-5cff7c98f9-vwwtc
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 02:02:28.904630    2208 request.go:729] Waited for 2.29621s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/inscripciones-consumer-8b9c9bb65-wsdhz
evicting pod sa-p8/cursos-service-54dfc7b68c-nhjcw
evicting pod sa-p8/estudiantes-service-6b9df98b75-tqkjl
evicting pod sa-p8/gateway-667bb95dfb-dt69d
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 02:02:38.905073    2208 request.go:729] Waited for 2.9389055s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/cursos-service-54dfc7b68c-gp2z2
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0924 02:02:48.905079    2208 request.go:729] Waited for 2.9390499s due to client-side throttling, not priority and fairness, request: GET:https://aks-sa-p9-mess6c7g.hcp.eastus.azmk8s.io:443/api/v1/namespaces/sa-p8/pods/inscripciones-consumer-8b9c9bb65-wsdhz
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cursos-service-54dfc7b68c-gp2z2 evicted
pod/konnectivity-agent-5b85b4bcfb-jg6kb evicted
pod/auth-service-c7d97959f-sh4bp evicted
pod/gateway-667bb95dfb-dlj26 evicted
pod/inscripciones-consumer-8b9c9bb65-wsdhz evicted
pod/inscripciones-service-5cff7c98f9-qjs6r evicted
pod/argocd-repo-server-7f88cf5b58-6nrkk evicted
pod/estudiantes-service-6b9df98b75-tqkjl evicted
pod/postgresql-0 evicted
pod/auth-service-c7d97959f-kjlcx evicted
pod/rabbitmq-0 evicted
pod/inscripciones-service-5cff7c98f9-vwwtc evicted
pod/cron-resumen-consumer-867478f48f-jkj9z evicted
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/cursos-service-54dfc7b68c-nhjcw evicted
pod/gateway-667bb95dfb-dt69d evicted
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
error when evicting pods/"metrics-server-85768b658b-bwrv2" -n "kube-system" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod kube-system/metrics-server-85768b658b-bwrv2
pod/metrics-server-85768b658b-bwrv2 evicted
node/aks-system-35358252-vmss000001 drained
```

### Registro con marcas de tiempo

```

2026-09-24T08:01:32Z | prueba-nodo: escenario=stateful nodo a drenar=aks-system-35358252-vmss000001 (postgresql-0 esta en aks-system-35358252-vmss000001)
2026-09-24T08:01:46Z | prueba-nodo: sondeo en marcha (linea base 10 s)
2026-09-24T08:01:46Z | prueba-nodo: kubectl drain aks-system-35358252-vmss000001 --ignore-daemonsets --delete-emptydir-data --timeout=300s
2026-09-24T08:03:31Z | prueba-nodo: drain terminado (codigo 0)
2026-09-24T08:04:03Z | prueba-nodo: todos los workloads Ready con un solo nodo
2026-09-24T08:04:15Z | prueba-nodo: uncordon aks-system-35358252-vmss000001

```
