# Diagrama del flujo de telemetría

Recorrido de una señal desde el servicio hasta el tablero y la alerta, y de un fallo hasta su causa.

```mermaid
flowchart TB
    classDef app fill:#d8f5d8,stroke:#1e8449,color:#000
    classDef otel fill:#fff3c4,stroke:#b7950b,color:#000
    classDef metrics fill:#d6e9ff,stroke:#2471a3,color:#000
    classDef logs fill:#ffe6cc,stroke:#b35900,color:#000
    classDef traces fill:#e8d8f5,stroke:#7d3c98,color:#000
    classDef canary fill:#ffd6d6,stroke:#c0392b,color:#000

    subgraph APP["Servicios instrumentados (namespace sa-p8)"]
        GW["gateway<br/>(Node + OTel SDK)"]:::app
        AUTH["auth-service<br/>(Node + OTel SDK)"]:::app
        CUR["cursos-service<br/>(Node + OTel SDK)"]:::app
    end

    GW -- "traceparent (W3C)<br/>propagado automático" --> AUTH
    GW -- "traceparent (W3C)" --> CUR

    subgraph SIGNALS["Tres señales por petición"]
        M["/metrics<br/>prom-client<br/>http_requests_total,<br/>http_request_duration_seconds,<br/>usuarios_registrados_total,<br/>cursos_creados_total"]:::metrics
        L["stdout JSON<br/>pino: {trace_id, span_id,<br/>service, level, msg}"]:::logs
        T["OTLP/HTTP :4318<br/>spans con trace_id"]:::traces
    end

    APP --> M
    APP --> L
    APP --> T

    PROM["Prometheus<br/>scrape /metrics cada 15s<br/>(anotación prometheus.io/scrape)"]:::metrics
    PROMTAIL["Promtail (DaemonSet)<br/>lee stdout de todos los pods"]:::logs
    OTELC["OTel Collector<br/>recibe OTLP, reenvía a Tempo"]:::otel

    M --> PROM
    L --> PROMTAIL
    T --> OTELC

    LOKI["Loki<br/>(logs, filtrables por trace_id)"]:::logs
    TEMPO["Tempo<br/>(trazas)"]:::traces

    PROMTAIL --> LOKI
    OTELC --> TEMPO

    PROM -- "recording rules" --> SLI["SLI + presupuesto de error<br/>(sli:*, slo:*)"]:::metrics
    SLI --> AM["Alertmanager<br/>(alerta con runbook_url)"]:::metrics

    GRAF["Grafana<br/>tablero de operación (4 señales de oro)"]:::metrics
    PROM --> GRAF
    LOKI -- "derivedField trace_id → Tempo" --> GRAF
    TEMPO -- "tracesToLogsV2 → Loki" --> GRAF
    GRAF --> AM

    subgraph ROLLOUT["Canario gobernado por métricas"]
        AR["Argo Rollouts<br/>Rollout gateway"]:::canary
        AT["AnalysisTemplate gateway-metrics<br/>consulta Prometheus:<br/>tasa-de-error, latencia-p95<br/>filtradas por rollouts_pod_template_hash"]:::canary
    end
    PROM -- "PromQL con {{args.canary-hash}}" --> AT
    AT -- "AnalysisRun Failed" --> AR
    AR -- "abort automático,<br/>sin intervención" --> GW

    OPERADOR["Operador humano"]
    AM -- "alerta firing" --> OPERADOR
    OPERADOR -- "sigue el trace_id<br/>de la alerta" --> GRAF
```

## Dos recorridos distintos, documentados en P10/evidencias/

1. **Síntoma → causa (operador humano, con alerta):** `FAULT_INJECTION=true` en auth-service → alerta
   `TasaErrorAuthServiceElevada` (Prometheus/Alertmanager) → traza con error en Tempo → registro con ese
   `trace_id` en Loki → causa confirmada. Ver `evidencias/sintoma-a-causa.md`.
2. **Canario → reversión automática (sin operador):** `CANARY_FAULT_INJECTION=true` en gateway → Argo Rollouts
   despliega la revisión como canario → `AnalysisTemplate gateway-metrics` consulta Prometheus filtrando por la
   revisión canaria → `AnalysisRun` falla → Argo Rollouts aborta solo. Ver `evidencias/canary-metricas.md`.
