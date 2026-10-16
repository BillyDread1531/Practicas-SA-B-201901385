# Práctica 10: Observabilidad y operación (del síntoma a la causa)

Instrumenta con OpenTelemetry tres microservicios del flujo de la Práctica 8 (`gateway`, `auth-service`,
`cursos-service`), despliega los tres pilares de la observabilidad (métricas, trazas, registros) con Prometheus,
Grafana, Loki y Tempo, y sustituye las pruebas sintéticas del canario de Argo Rollouts por un análisis gobernado por
métricas reales.

## Tabla de enlaces obligatoria

| Ítem | Enlace o dato requerido |
|---|---|
| **Repositorio de código** | https://github.com/BillyDread1531/Practicas-SA-B-201901385 (carpeta `/P10`, instrumentación en `P5/*/src/telemetry/`) |
| **Repositorio GitOps** | https://github.com/BillyDread1531/Practica-SA-P8-GitOps (rama `p10`) |
| **Servicios instrumentados** | `gateway`, `auth-service`, `cursos-service` — namespace `sa-p8` |
| **AnalysisTemplate por métricas** | `gateway-metrics` — [`P8/charts/gateway/templates/analysis-template.yaml`](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/P8/charts/gateway/templates/analysis-template.yaml) |
| **Consultas del análisis** | Tasa de error: `sum(rate(http_requests_total{service="gateway",rollouts_pod_template_hash="{{args.canary-hash}}",status_code=~"5.."}[2m])) / (sum(rate(http_requests_total{service="gateway",rollouts_pod_template_hash="{{args.canary-hash}}"}[2m])) + 0.001)` · Latencia p95: `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{service="gateway",rollouts_pod_template_hash="{{args.canary-hash}}"}[2m])) by (le))` |
| **SLO declarados** | Disponibilidad gateway: 99% sin 5xx (ventana 1h) · Latencia gateway: p95 < 500ms (ventana 1h). Ver [`informe-operacion.md`](informe-operacion.md) §1 |
| **Reglas de alerta** | [`P8-GitOps/apps/prometheus.yaml`](https://github.com/BillyDread1531/Practica-SA-P8-GitOps/blob/p10/apps/prometheus.yaml) (`serverFiles.alerting_rules.yml`) |
| **Tablero** | [`P10/dashboards/operacion.json`](dashboards/operacion.json) |
| **Reversión por métricas** | `gateway-769d6d65bd-22-1` → **Failed** (tasa de error 17.8%, p95 2.34s; falló 71s después de activar el fallo). Rollout `gateway` abortado solo (`Degraded`, `abort=true`). Ver [`evidencias/canary-metricas.md`](evidencias/canary-metricas.md) |
| **Recorrido síntoma a causa** | [`evidencias/sintoma-a-causa.md`](evidencias/sintoma-a-causa.md) — tiempo medido: detección 95s, causa confirmada 102s (1.7 min, bajo el objetivo de 3 min) |

## Documentos

| Documento | Archivo |
|---|---|
| Informe de operación (6 campos) | [informe-operacion.md](informe-operacion.md) |
| Runbooks (uno por alerta) | [runbooks/](runbooks/) |
| Diagrama del flujo de telemetría | [docs/diagrama-telemetria.md](docs/diagrama-telemetria.md) |
| Preguntas teóricas | [docs/preguntas-teoricas.md](docs/preguntas-teoricas.md) |
| Tablero exportado | [dashboards/operacion.json](dashboards/operacion.json) |

## Cómo está resuelto cada requisito

| Requisito | Solución | Dónde |
|---|---|---|
| Instrumentación con OpenTelemetry | SDK de Node (`@opentelemetry/sdk-node` + auto-instrumentations) en 3 servicios, propagación W3C automática vía el proxy del gateway | `P5/*/src/telemetry/instrumentation.js` |
| Métricas técnicas y de negocio | `prom-client`: 4 señales de oro + `usuarios_registrados_total` (auth-service) y `cursos_creados_total` (cursos-service) | `P5/*/src/telemetry/metrics.js` |
| Registros estructurados | `pino` en JSON con `trace_id`/`span_id` de la traza activa | `P5/*/src/telemetry/logger.js` |
| Recolección y almacenamiento vía GitOps | Prometheus+Alertmanager, Loki (single-binary), Tempo, OTel Collector, todo desplegado por ArgoCD, no a mano | `P8-GitOps/apps/{prometheus,loki,tempo,otel-collector,promtail,grafana}.yaml` |
| Canary gobernado por métricas | `AnalysisTemplate gateway-metrics`, provider `prometheus`, filtra por `rollouts_pod_template_hash` del canario | `P8/charts/gateway/templates/analysis-template.yaml` |
| SLO y presupuesto de error | `recording_rules.yml` calcula `sli:*` y `slo:*_error_budget_burn1h` | `P8-GitOps/apps/prometheus.yaml` |
| Alertas por consumo de presupuesto | 3 `PrometheusRule`-equivalentes vía `alerting_rules.yml`, cada una con `runbook_url` | `P8-GitOps/apps/prometheus.yaml`, `runbooks/` |
| Tablero por 4 señales de oro | Tráfico, errores, latencia, saturación + negocio + SLO + logs | `dashboards/operacion.json` |
| Recorrido síntoma a causa | Script automatizado y cronometrado | `scripts/prueba-sintoma-causa.ps1`, `evidencias/sintoma-a-causa.md` |
| Fallo inducido (canario) | `CANARY_FAULT_INJECTION`, reversión automática sin intervención | `scripts/prueba-canary-metricas.ps1`, `evidencias/canary-metricas.md` |
| Conservación del flujo previo | GitOps, Kyverno, Sealed Secrets, Argo Rollouts siguen operando (`scripts/verificar.ps1`) | `P8-GitOps/apps/` (olas 0/1/2 sin cambios de fondo) |

## Estructura

```
P10/
├── terraform/      AKS de 1 nodo (Standard_D2s_v7), sin ACR, sin LoadBalancer, estado local
├── scripts/        bootstrap.ps1 (entrada única), teardown.ps1, verificar.ps1,
│                   prueba-sintoma-causa.ps1, prueba-canary-metricas.ps1, generar-trafico.ps1
├── dashboards/      operacion.json (tablero exportado)
├── docs/            diagrama de telemetría, preguntas teóricas
├── runbooks/         uno por alerta
├── evidencias/       generadas por los scripts, con marcas de tiempo reales
└── informe-operacion.md
```

## Costo y ciclo de uso

Este clúster se diseñó para costar lo mínimo posible: 1 nodo `Standard_D2s_v7` (el SKU económico
disponible en la región/cuota de esta suscripción; `Standard_B2ms`/`B2s_v2` no tenían cupo), sin
Load Balancer ni IP pública (acceso vía `kubectl port-forward`), sin Azure Container Registry
(imágenes en ghcr.io, gratuito). Se
construye para trabajar, se apaga con `scripts/teardown.ps1` al terminar la sesión, y se reconstruye con
`scripts/bootstrap.ps1` (~10-15 min) la próxima vez.

```powershell
az login
.\P10\scripts\bootstrap.ps1          # construye y verifica
.\P10\scripts\prueba-sintoma-causa.ps1
.\P10\scripts\prueba-canary-metricas.ps1
.\P10\scripts\teardown.ps1           # apaga todo (costo = 0)
```
