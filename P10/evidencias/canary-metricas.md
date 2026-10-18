# Reversión del canary por métricas - evidencia automática

Generada por `P10/scripts/prueba-canary-metricas.ps1`. Fallo inducido: `CANARY_FAULT_INJECTION=true` en el
**gateway** (distinto al fallo de la Práctica 8 y al de `auth-service` usado en el recorrido síntoma-causa).
Horas en UTC.

| Campo | Valor |
|---|---|
| Rollout | `gateway` (namespace `sa-p8`) |
| Revisión estable (antes) | `6577c7b69f` |
| Revisión canary (con el fallo) | `674949f54c` |
| **AnalysisRun** | `gateway-674949f54c-2-1` -> **Failed** |
| Fallo activado | 2026-10-17T07:18:09Z |
| AnalysisRun concluido | 2026-10-17T07:19:22Z (73 s después) |
| Rollout abortado (0% canario) | 2026-10-17T07:19:23Z (74 s después) |
| Intervención humana durante la reversión | **Ninguna**: Argo Rollouts abortó solo al ver el AnalysisRun fallido |

## AnalysisRun completo (las consultas PromQL que decidieron la reversión están aquí)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
metadata:
  annotations:
    rollout.argoproj.io/revision: "2"
  creationTimestamp: "2026-10-17T07:18:19Z"
  generation: 5
  labels:
    app.kubernetes.io/name: gateway
    rollout-type: Step
    rollouts-pod-template-hash: 674949f54c
    step-index: "1"
  name: gateway-674949f54c-2-1
  namespace: sa-p8
  ownerReferences:
  - apiVersion: argoproj.io/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: Rollout
    name: gateway
    uid: 7701760b-8cbc-4661-88c6-fd697c84b6b2
  resourceVersion: "10032"
  uid: 5dfc1ba9-f702-437b-82af-83fd07f00cce
spec:
  args:
  - name: canary-hash
    value: 674949f54c
  metrics:
  - count: 12
    failureCondition: result >= 0.10
    failureLimit: 1
    inconclusiveLimit: 9
    interval: 20s
    name: tasa-de-error
    provider:
      prometheus:
        address: http://prometheus-server.observability.svc.cluster.local
        authentication:
          oauth2: {}
          sigv4: {}
        query: |
          scalar(
            (sum(rate(http_requests_total{service="gateway", rollouts_pod_template_hash="{{args.canary-hash}}", status_code=~"5.."}[2m])) or vector(0))
            /
            (sum(rate(http_requests_total{service="gateway", rollouts_pod_template_hash="{{args.canary-hash}}"}[2m])) + 0.001)
          )
        timeout: 10
    successCondition: result < 0.10
  - count: 12
    failureCondition: result >= 1
    failureLimit: 1
    inconclusiveLimit: 9
    interval: 20s
    name: latencia-p95
    provider:
      prometheus:
        address: http://prometheus-server.observability.svc.cluster.local
        authentication:
          oauth2: {}
          sigv4: {}
        query: |
          scalar(
            histogram_quantile(0.95,
              sum(rate(http_request_duration_seconds_bucket{service="gateway", rollouts_pod_template_hash="{{args.canary-hash}}"}[2m])) by (le)
            )
          )
        timeout: 10
    successCondition: result < 1
status:
  completedAt: "2026-10-17T07:19:19Z"
  dryRunSummary: {}
  message: Metric "tasa-de-error" assessed Failed due to failed (2) > failureLimit
    (1)
  metricResults:
  - count: 4
    failed: 2
    inconclusive: 2
    measurements:
    - finishedAt: "2026-10-17T07:18:19Z"
      phase: Inconclusive
      startedAt: "2026-10-17T07:18:19Z"
      value: NaN
    - finishedAt: "2026-10-17T07:18:39Z"
      phase: Inconclusive
      startedAt: "2026-10-17T07:18:39Z"
      value: NaN
    - finishedAt: "2026-10-17T07:18:59Z"
      phase: Failed
      startedAt: "2026-10-17T07:18:59Z"
      value: "0.3314384788107893"
    - finishedAt: "2026-10-17T07:19:19Z"
      phase: Failed
      startedAt: "2026-10-17T07:19:19Z"
      value: "0.3401444078785795"
    metadata:
      ResolvedPrometheusQuery: |
        scalar(
          (sum(rate(http_requests_total{service="gateway", rollouts_pod_template_hash="674949f54c", status_code=~"5.."}[2m])) or vector(0))
          /
          (sum(rate(http_requests_total{service="gateway", rollouts_pod_template_hash="674949f54c"}[2m])) + 0.001)
        )
    name: tasa-de-error
    phase: Failed
  - count: 4
    failed: 2
    inconclusive: 2
    measurements:
    - finishedAt: "2026-10-17T07:18:19Z"
      phase: Inconclusive
      startedAt: "2026-10-17T07:18:19Z"
      value: NaN
    - finishedAt: "2026-10-17T07:18:39Z"
      phase: Inconclusive
      startedAt: "2026-10-17T07:18:39Z"
      value: NaN
    - finishedAt: "2026-10-17T07:18:59Z"
      phase: Failed
      startedAt: "2026-10-17T07:18:59Z"
      value: "2.33125"
    - finishedAt: "2026-10-17T07:19:19Z"
      phase: Failed
      startedAt: "2026-10-17T07:19:19Z"
      value: "2.3410352358050743"
    metadata:
      ResolvedPrometheusQuery: |
        scalar(
          histogram_quantile(0.95,
            sum(rate(http_request_duration_seconds_bucket{service="gateway", rollouts_pod_template_hash="674949f54c"}[2m])) by (le)
          )
        )
    name: latencia-p95
    phase: Failed
  phase: Failed
  runSummary:
    count: 2
    failed: 2
  startedAt: "2026-10-17T07:18:19Z"
```

## kubectl describe rollout gateway

```
Name:         gateway
Namespace:    sa-p8
Labels:       app.kubernetes.io/instance=sa-platform-dev
              app.kubernetes.io/managed-by=Helm
              app.kubernetes.io/name=gateway
              app.kubernetes.io/version=1.0.0
              helm.sh/chart=gateway-1.0.0
Annotations:  argocd.argoproj.io/tracking-id: sa-platform-dev:argoproj.io/Rollout:sa-p8/gateway
              rollout.argoproj.io/revision: 2
API Version:  argoproj.io/v1alpha1
Kind:         Rollout
Metadata:
  Creation Timestamp:  2026-10-17T07:08:54Z
  Generation:          5
  Resource Version:    10049
  UID:                 7701760b-8cbc-4661-88c6-fd697c84b6b2
Spec:
  Replicas:                2
  Revision History Limit:  3
  Selector:
    Match Labels:
      app.kubernetes.io/name:  gateway
  Strategy:
    Canary:
      Steps:
        Set Weight:  20
        Analysis:
          Analysis Run Metadata:
          Args:
            Name:  canary-hash
            Value From:
              Pod Template Hash Value:  Latest
          Templates:
            Template Name:  gateway-metrics
        Pause:
          Duration:  20s
        Set Weight:  50
        Analysis:
          Analysis Run Metadata:
          Args:
            Name:  canary-hash
            Value From:
              Pod Template Hash Value:  Latest
          Templates:
            Template Name:  gateway-metrics
        Pause:
          Duration:  20s
        Set Weight:  80
        Analysis:
          Analysis Run Metadata:
          Args:
            Name:  canary-hash
            Value From:
              Pod Template Hash Value:  Latest
          Templates:
            Template Name:  gateway-metrics
        Pause:
          Duration:  20s
        Set Weight:  100
        Analysis:
          Analysis Run Metadata:
          Args:
            Name:  canary-hash
            Value From:
              Pod Template Hash Value:  Latest
          Templates:
            Template Name:  gateway-metrics
  Template:
    Metadata:
      Annotations:
        checksum/config:       61efb0c706ea0dcd152a8ff0e44cefbb602d79c267c7bfaf30591013cbd02b2d
        prometheus.io/path:    /metrics
        prometheus.io/port:    3000
        prometheus.io/scrape:  true
      Labels:
        app.kubernetes.io/instance:  sa-platform-dev
        app.kubernetes.io/name:      gateway
    Spec:
      Affinity:
        Pod Anti Affinity:
          Preferred During Scheduling Ignored During Execution:
            Pod Affinity Term:
              Label Selector:
                Match Labels:
                  app.kubernetes.io/name:  gateway
              Topology Key:                kubernetes.io/hostname
            Weight:                        100
      Automount Service Account Token:     false
      Containers:
        Env From:
          Config Map Ref:
            Name:  gateway-config
          Secret Ref:
            Name:           sa-platform-secrets
        Image:              ghcr.io/billydread1531/gateway:p10-latest
        Image Pull Policy:  IfNotPresent
        Liveness Probe:
          Failure Threshold:  3
          Http Get:
            Path:                 /health
            Port:                 http
          Initial Delay Seconds:  15
          Period Seconds:         10
        Name:                     gateway
        Ports:
          Container Port:  3000
          Name:            http
          Protocol:        TCP
        Readiness Probe:
          Failure Threshold:  3
          Http Get:
            Path:                 /health
            Port:                 http
          Initial Delay Seconds:  5
          Period Seconds:         5
        Resources:
          Limits:
            Cpu:     200m
            Memory:  192Mi
          Requests:
            Cpu:     25m
            Memory:  96Mi
        Security Context:
          Allow Privilege Escalation:  false
          Capabilities:
            Drop:
              ALL
          Read Only Root Filesystem:  true
          Run As Non Root:            true
          Run As User:                1000
        Startup Probe:
          Failure Threshold:  12
          Http Get:
            Path:                 /health
            Port:                 http
          Initial Delay Seconds:  5
          Period Seconds:         5
        Volume Mounts:
          Mount Path:  /tmp
          Name:        tmp
      Security Context:
        Run As Non Root:  true
        Run As User:      1000
        Seccomp Profile:
          Type:              RuntimeDefault
      Service Account Name:  gateway-sa
      Volumes:
        Empty Dir:
        Name:  tmp
Status:
  HPA Replicas:        2
  Abort:               true
  Aborted At:          2026-10-17T07:19:19Z
  Available Replicas:  2
  Blue Green:
  Canary:
    Current Step Analysis Run Status:
      Message:  Metric "tasa-de-error" assessed Failed due to failed (2) > failureLimit (1)
      Name:     gateway-674949f54c-2-1
      Status:   Failed
  Conditions:
    Last Transition Time:  2026-10-17T07:14:16Z
    Last Update Time:      2026-10-17T07:14:16Z
    Message:               Rollout has minimum availability
    Reason:                AvailableReason
    Status:                True
    Type:                  Available
    Last Transition Time:  2026-10-17T07:18:13Z
    Last Update Time:      2026-10-17T07:18:13Z
    Message:               Rollout is not healthy
    Reason:                RolloutHealthy
    Status:                False
    Type:                  Healthy
    Last Transition Time:  2026-10-17T07:18:13Z
    Last Update Time:      2026-10-17T07:18:13Z
    Message:               RolloutCompleted
    Reason:                RolloutCompleted
    Status:                False
    Type:                  Completed
    Last Transition Time:  2026-10-17T07:19:19Z
    Last Update Time:      2026-10-17T07:19:19Z
    Message:               Rollout aborted update to revision 2: Metric "tasa-de-error" assessed Failed due to failed (2) > failureLimit (1)
    Reason:                RolloutAborted
    Status:                False
    Type:                  Progressing
  Current Pod Hash:        674949f54c
  Current Step Hash:       7b48b8ccd
  Current Step Index:      0
  Message:                 RolloutAborted: Rollout aborted update to revision 2: Metric "tasa-de-error" assessed Failed due to failed (2) > failureLimit (1)
  Observed Generation:     5
  Phase:                   Degraded
  Ready Replicas:          2
  Replicas:                2
  Selector:                app.kubernetes.io/name=gateway
  Stable RS:               6577c7b69f
Events:
  Type     Reason                  Age   From                 Message
  ----     ------                  ----  ----                 -------
  Normal   RolloutAddedToInformer  14m   rollouts-controller  Rollout resource added to informer: sa-p8/gateway
  Normal   RolloutNotCompleted     14m   rollouts-controller  Rollout not completed, started update to revision 1 (6577c7b69f)
  Normal   RolloutUpdated          14m   rollouts-controller  Rollout updated to revision 1
  Normal   NewReplicaSetCreated    14m   rollouts-controller  Created ReplicaSet gateway-6577c7b69f (revision 1)
  Normal   ScalingReplicaSet       14m   rollouts-controller  Scaled up ReplicaSet gateway-6577c7b69f (revision 1) from 0 to 2
  Normal   RolloutCompleted        14m   rollouts-controller  Rollout completed update to revision 1 (6577c7b69f): Initial deploy
  Normal   RolloutNotCompleted     5m9s  rollouts-controller  Rollout not completed, started update to revision 2 (674949f54c)
  Normal   RolloutUpdated          5m9s  rollouts-controller  Rollout updated to revision 2
  Normal   NewReplicaSetCreated    5m9s  rollouts-controller  Created ReplicaSet gateway-674949f54c (revision 2)
  Normal   ScalingReplicaSet       5m9s  rollouts-controller  Scaled up ReplicaSet gateway-674949f54c (revision 2) from 0 to 1
  Normal   RolloutStepCompleted    5m3s  rollouts-controller  Rollout step 1/11 completed (setWeight: 20)
  Normal   AnalysisRunRunning      5m3s  rollouts-controller  Step Analysis Run 'gateway-674949f54c-2-1' Status New: 'Running' Previous: ''
  Warning  AnalysisRunFailed       4m3s  rollouts-controller  Step Analysis Run 'gateway-674949f54c-2-1' Status New: 'Failed' Previous: 'Running'
  Warning  RolloutAborted          4m3s  rollouts-controller  Rollout aborted update to revision 2: Metric "tasa-de-error" assessed Failed due to failed (2) > failureLimit (1)
  Normal   ScalingReplicaSet       4m3s  rollouts-controller  Scaled down ReplicaSet gateway-674949f54c (revision 2) from 1 to 0

```

## Eventos del Rollout

```
LAST SEEN   TYPE      REASON                   OBJECT                        MESSAGE
14m         Normal    NoPods                   poddisruptionbudget/gateway   No matching pods found
14m         Normal    RolloutAddedToInformer   rollout/gateway               Rollout resource added to informer: sa-p8/gateway
14m         Normal    RolloutNotCompleted      rollout/gateway               Rollout not completed, started update to revision 1 (6577c7b69f)
14m         Normal    RolloutUpdated           rollout/gateway               Rollout updated to revision 1
14m         Normal    NewReplicaSetCreated     rollout/gateway               Created ReplicaSet gateway-6577c7b69f (revision 1)
14m         Normal    ScalingReplicaSet        rollout/gateway               Scaled up ReplicaSet gateway-6577c7b69f (revision 1) from 0 to 2
14m         Normal    RolloutCompleted         rollout/gateway               Rollout completed update to revision 1 (6577c7b69f): Initial deploy
5m9s        Normal    RolloutNotCompleted      rollout/gateway               Rollout not completed, started update to revision 2 (674949f54c)
5m9s        Normal    RolloutUpdated           rollout/gateway               Rollout updated to revision 2
5m9s        Normal    NewReplicaSetCreated     rollout/gateway               Created ReplicaSet gateway-674949f54c (revision 2)
5m9s        Normal    ScalingReplicaSet        rollout/gateway               Scaled up ReplicaSet gateway-674949f54c (revision 2) from 0 to 1
5m3s        Normal    RolloutStepCompleted     rollout/gateway               Rollout step 1/11 completed (setWeight: 20)
5m3s        Normal    AnalysisRunRunning       rollout/gateway               Step Analysis Run 'gateway-674949f54c-2-1' Status New: 'Running' Previous: ''
4m3s        Warning   AnalysisRunFailed        rollout/gateway               Step Analysis Run 'gateway-674949f54c-2-1' Status New: 'Failed' Previous: 'Running'
4m3s        Warning   RolloutAborted           rollout/gateway               Rollout aborted update to revision 2: Metric "tasa-de-error" assessed Failed due to failed (2) > failureLimit (1)
4m3s        Normal    ScalingReplicaSet        rollout/gateway               Scaled down ReplicaSet gateway-674949f54c (revision 2) from 1 to 0
```

## Registro con marcas de tiempo

```

2026-10-17T07:17:39Z | canary-metricas: trafico de base (20s)
2026-10-17T07:18:04Z | canary-metricas: revision estable actual = 6577c7b69f
2026-10-17T07:18:04Z | canary-metricas: activando CANARY_FAULT_INJECTION=true en el gateway
2026-10-17T07:18:10Z | canary-metricas: generando trafico continuo (arranca ya, en paralelo con la deteccion de la revision)
2026-10-17T07:18:11Z | canary-metricas: esperando que Argo Rollouts cree la revision canary
2026-10-17T07:18:17Z | canary-metricas: revision canary = 674949f54c
2026-10-17T07:18:17Z | canary-metricas: esperando el resultado del AnalysisRun (debe fallar por metricas del canary)
2026-10-17T07:19:22Z | canary-metricas: AnalysisRun gateway-674949f54c-2-1 -> Failed (a las 2026-10-17T07:19:22Z)
2026-10-17T07:19:22Z | canary-metricas: esperando que el Rollout quede Degraded/abortado con 0 replicas canary
2026-10-17T07:19:23Z | canary-metricas: Rollout abortado a las 2026-10-17T07:19:23Z (phase=Degraded, abort=True)
2026-10-17T07:23:23Z | canary-metricas: revirtiendo CANARY_FAULT_INJECTION=false
2026-10-17T07:39:28Z | canary-metricas: Rollout Healthy de nuevo (100% estable)

```
