# Reversión del canary por métricas - evidencia real

Generada a partir de una corrida real de `P10/scripts/prueba-canary-metricas.ps1` (con los
fixes ya aplicados: `podTemplateHashValue: Latest`, ventana de análisis ampliada y generador de
tráfico in-cluster). Fallo inducido: `CANARY_FAULT_INJECTION=true` en el **gateway** (distinto al
fallo de la Práctica 8 y al de `auth-service` usado en el recorrido síntoma-causa). Horas en UTC.

El mismo resultado (`AnalysisRun` → `Failed`, `Rollout` → `Degraded`/`abort=true`, sin
intervención humana) se reprodujo de forma independiente **dos veces** en esta sesión:

- Corrida anterior: `AnalysisRun` falló a las `2026-10-16T05:54:20Z` (69 s después de activar el fallo).
- **Corrida documentada aquí**: `AnalysisRun` falló a las `2026-10-16T06:36:40Z` (71 s después de activar el fallo).

## Resumen

| Campo | Valor |
|---|---|
| Rollout | `gateway` (namespace `sa-p8`) |
| Revisión estable (antes) | `6b5bc4b65f` |
| Revisión canary (con el fallo) | `769d6d65bd` |
| **AnalysisRun** | `gateway-769d6d65bd-22-1` → **Failed** |
| Fallo activado (T0) | `2026-10-16T06:35:29Z` |
| AnalysisRun iniciado | `2026-10-16T06:35:40Z` |
| AnalysisRun concluido (Failed) | `2026-10-16T06:36:40Z` (**71 s** después de T0) |
| Rollout abortado (`Degraded`, `abort=true`) | `2026-10-16T06:36:43Z` (**74 s** después de T0) |
| **Intervención humana durante la detección/reversión** | **Ninguna**: Argo Rollouts abortó solo al ver el AnalysisRun fallido |

## Por qué falló (valores reales medidos contra Prometheus)

El `AnalysisRun` solo necesitó 2 mediciones no vacías (de las 12 posibles, a 20s cada una) para
exceder `failureLimit: 1` y concluir `Failed` — mucho antes de llegar al límite de la ventana:

| Métrica | Medición 3 (20s) | Medición 4 (20s) | Umbral | Resultado |
|---|---|---|---|---|
| `tasa-de-error` | 0.1775 (17.75%) | 0.1785 (17.85%) | `< 0.10` | **Failed** (2 de 2 mediciones con dato real superan el umbral) |
| `latencia-p95` | 2.330 s | 2.344 s | `< 1 s` | **Failed** (2 de 2 mediciones con dato real superan el umbral) |

Mensaje textual del `AnalysisRun`:

```
Metric "tasa-de-error" assessed Failed due to failed (2) > failureLimit (1)
```

Consultas PromQL reales resueltas (con el hash del canary ya sustituido por Argo Rollouts):

```promql
# tasa-de-error
scalar(
  (sum(rate(http_requests_total{service="gateway", rollouts_pod_template_hash="769d6d65bd", status_code=~"5.."}[2m])) or vector(0))
  /
  (sum(rate(http_requests_total{service="gateway", rollouts_pod_template_hash="769d6d65bd"}[2m])) + 0.001)
)

# latencia-p95
scalar(
  histogram_quantile(0.95,
    sum(rate(http_request_duration_seconds_bucket{service="gateway", rollouts_pod_template_hash="769d6d65bd"}[2m])) by (le)
  )
)
```

## AnalysisRun completo (YAML real, con las mediciones)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisRun
metadata:
  annotations:
    rollout.argoproj.io/revision: "22"
  creationTimestamp: "2026-10-16T06:35:40Z"
  labels:
    app.kubernetes.io/name: gateway
    rollout-type: Step
    rollouts-pod-template-hash: 769d6d65bd
    step-index: "1"
  name: gateway-769d6d65bd-22-1
  namespace: sa-p8
  ownerReferences:
  - apiVersion: argoproj.io/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: Rollout
    name: gateway
spec:
  args:
  - name: canary-hash
    value: 769d6d65bd
  metrics:
  - count: 12
    failureCondition: result >= 0.10
    failureLimit: 1
    inconclusiveLimit: 9
    interval: 20s
    name: tasa-de-error
    successCondition: result < 0.10
  - count: 12
    failureCondition: result >= 1
    failureLimit: 1
    inconclusiveLimit: 9
    interval: 20s
    name: latencia-p95
    successCondition: result < 1
status:
  completedAt: "2026-10-16T06:36:40Z"
  message: Metric "tasa-de-error" assessed Failed due to failed (2) > failureLimit (1)
  metricResults:
  - count: 4
    failed: 2
    inconclusive: 2
    measurements:
    - finishedAt: "2026-10-16T06:35:40Z"
      phase: Inconclusive
      startedAt: "2026-10-16T06:35:40Z"
      value: NaN
    - finishedAt: "2026-10-16T06:36:00Z"
      phase: Inconclusive
      startedAt: "2026-10-16T06:36:00Z"
      value: NaN
    - finishedAt: "2026-10-16T06:36:20Z"
      phase: Failed
      startedAt: "2026-10-16T06:36:20Z"
      value: "2.329796928464858"
    - finishedAt: "2026-10-16T06:36:40Z"
      phase: Failed
      startedAt: "2026-10-16T06:36:40Z"
      value: "2.34412003019324"
    name: latencia-p95
    phase: Failed
  - count: 4
    failed: 2
    inconclusive: 2
    measurements:
    - finishedAt: "2026-10-16T06:35:40Z"
      phase: Inconclusive
      startedAt: "2026-10-16T06:35:40Z"
      value: NaN
    - finishedAt: "2026-10-16T06:36:00Z"
      phase: Inconclusive
      startedAt: "2026-10-16T06:36:00Z"
      value: NaN
    - finishedAt: "2026-10-16T06:36:20Z"
      phase: Failed
      startedAt: "2026-10-16T06:36:20Z"
      value: "0.177509012068335"
    - finishedAt: "2026-10-16T06:36:40Z"
      phase: Failed
      startedAt: "2026-10-16T06:36:40Z"
      value: "0.17849286179013688"
    name: tasa-de-error
    phase: Failed
  phase: Failed
  runSummary:
    count: 2
    failed: 2
  startedAt: "2026-10-16T06:35:40Z"
```

Nota sobre las 2 primeras mediciones (`NaN`/`Inconclusive`): el pod canary recién creado tarda unos
segundos en quedar `Ready` y en que Prometheus lo scrapee por primera vez; `inconclusiveLimit: 9`
(de 12) existe exactamente para tolerar ese arranque sin invalidar el análisis — en cuanto hay datos
reales (medición 3), el fallo se detecta y falla en la medición siguiente, muy por debajo del límite.

## Eventos reales del Rollout/AnalysisRun (kubectl get events)

```
2026-10-16T06:36:40Z  Warning  MetricFailed       analysisrun/gateway-769d6d65bd-22-1  Metric 'tasa-de-error' Completed. Result: Failed
2026-10-16T06:36:40Z  Warning  MetricFailed       analysisrun/gateway-769d6d65bd-22-1  Metric 'latencia-p95' Completed. Result: Failed
2026-10-16T06:36:40Z  Warning  AnalysisRunFailed  analysisrun/gateway-769d6d65bd-22-1  Analysis Completed. Result: Failed
```

## Registro de la corrida (con marcas de tiempo, texto real del script)

```
2026-10-16T06:34:53Z | canary-metricas: trafico de base (20s)
2026-10-16T06:35:22Z | generar-trafico(in-cluster): 56 peticiones exitosas, 0 con error, en 20s
2026-10-16T06:35:23Z | canary-metricas: revision estable actual = 6b5bc4b65f
2026-10-16T06:35:23Z | canary-metricas: activando CANARY_FAULT_INJECTION=true en el gateway
2026-10-16T06:35:29Z | set-gitops-flag: gateway.CANARY_FAULT_INJECTION=true publicado en GitOps (rama p10)
2026-10-16T06:35:30Z | canary-metricas: generando trafico continuo (arranca ya, en paralelo con la deteccion de la revision)
2026-10-16T06:35:30Z | canary-metricas: esperando que Argo Rollouts cree la revision canary
2026-10-16T06:35:36Z | canary-metricas: revision canary = 769d6d65bd
2026-10-16T06:35:36Z | canary-metricas: esperando el resultado del AnalysisRun (debe fallar por metricas del canary)
2026-10-16T06:36:43Z | canary-metricas: AnalysisRun gateway-769d6d65bd-22-1 -> Failed (a las 2026-10-16T06:36:43Z)
2026-10-16T06:36:43Z | canary-metricas: esperando que el Rollout quede Degraded/abortado con 0 replicas canary
2026-10-16T06:36:43Z | canary-metricas: Rollout abortado a las 2026-10-16T06:36:43Z (phase=Degraded, abort=True)
2026-10-16T06:40:40Z | generar-trafico(in-cluster): 1091 peticiones exitosas, 9 con error, en 300s
2026-10-16T06:40:42Z | canary-metricas: revirtiendo CANARY_FAULT_INJECTION=false
2026-10-16T06:40:45Z | set-gitops-flag: gateway.CANARY_FAULT_INJECTION=false publicado en GitOps (rama p10)
```

## Nota sobre el tiempo de reversión completa a "Healthy"

Revertir `CANARY_FAULT_INJECTION=false` cambia el ConfigMap otra vez, así que la propia reversión
dispara un rollout nuevo (ahora sin el fallo) que vuelve a recorrer los 4 pasos
`setWeight`/`analysis` del canario desde cero — por diseño, cada paso se gobierna por las mismas
métricas reales, así que la vuelta a 100% estable tampoco es instantánea ni manual, solo más lenta
que la detección del fallo (que es lo que mide esta rúbrica). El Rollout volvió a `Healthy` de forma
completamente automática minutos después, sin ninguna acción manual sobre el clúster.
