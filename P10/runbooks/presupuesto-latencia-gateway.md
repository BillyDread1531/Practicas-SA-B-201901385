# Runbook: PresupuestoLatenciaGatewayAgotandose

**Alerta:** `PresupuestoLatenciaGatewayAgotandose` · **Severidad:** critical · **SLO:** latencia-gateway

## Por qué amerita intervención

El SLO de latencia declara que el 95% de las peticiones deben responder en menos de 500 ms (ventana de 1 h). Esta
alerta dispara cuando el presupuesto de error de esa ventana se consume a más de 2x la tasa sostenible durante al
menos 2 minutos — es decir, una fracción creciente de usuarios está esperando más de lo prometido, de forma
sostenida, no un pico aislado.

## Diagnóstico (objetivo: menos de 3 minutos)

1. **Tablero de operación** → panel "LATENCIA - p95 del gateway" y el gauge de presupuesto de latencia. Confirmar
   la tendencia (sostenida, no un pico que ya bajó).
2. **Aislar el servicio lento**, no solo el gateway (el gateway mide el tiempo total, incluido lo que tarda el
   servicio de abajo):
   ```promql
   histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))
   ```
   Ejecutar esta consulta en Grafana Explore (datasource Prometheus) para ver cuál servicio concentra la latencia.
3. **Abrir una traza lenta** del servicio identificado (panel de logs → `trace_id` → botón a Tempo) y mirar en qué
   *span* se concentra el tiempo: ¿es la base de datos (`pg` instrumentado automáticamente), una llamada downstream,
   o el propio procesamiento del servicio?
4. **Revisar fallos inducidos activos** (mismo comando que en el runbook de disponibilidad) — `FAULT_EXTRA_LATENCY_MS`
   y `CANARY_FAULT_LATENCY_MS` son las causas más probables en un entorno de práctica.

## Mitigación

- Si el canario está en curso: lo normal es que Argo Rollouts lo revierta solo por el `AnalysisTemplate` (métrica
  `latencia-p95`); confirmar en `kubectl -n sa-p8 get analysisrun`.
- Si es la versión estable y la causa es la base de datos: revisar `kubectl -n sa-p8 top pod postgresql-0` y si el
  CPU/memoria están saturados (señal de "saturación", no solo de latencia).
- Si es un fallo inducido olvidado encendido: apagarlo (`P10/scripts/set-gitops-flag.ps1 -Value false`).

## Límites conocidos

Un único nodo (cuota de la suscripción) significa que un pico real de carga puede degradar la latencia de *todos*
los servicios a la vez, no solo el que originó el problema (saturación compartida de CPU). El panel de "SATURACIÓN"
del tablero ayuda a distinguir ese caso.
