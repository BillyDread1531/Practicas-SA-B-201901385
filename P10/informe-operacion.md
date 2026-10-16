# Informe de operación — Práctica 10

**Sistema:** plataforma de microservicios en AKS `aks-sa-p10` (namespace `sa-p8`) · **Fecha:** [PENDIENTE: fecha de la prueba]

## 1. SLO declarados

| SLO | Objetivo | Ventana | Por qué ese número |
|---|---|---|---|
| **Disponibilidad del gateway** | 99% de peticiones sin error 5xx | 1 h (en producción: 30 d) | Es lo que el usuario experimenta al interactuar con la plataforma, no una métrica de un componente interno. 99% (presupuesto de error 1%) es el estándar de entrada para un servicio académico con tráfico bajo: deja margen para errores transitorios de red/reinicio de pods sin convertir cada incidente menor en una violación de SLO. |
| **Latencia del gateway** | 95% de peticiones en menos de 500 ms | 1 h (en producción: 30 d) | 500 ms es el umbral habitual para que una interacción se perciba como "inmediata" en una SPA/API REST; el 95% (no el 100%) reconoce que siempre habrá una cola de peticiones más lentas (cold start, GC, picos de carga) que no deben contar como incumplimiento mientras sean minoría. |

La ventana se acortó a 1 h (en vez de los 30 d típicos de producción) porque el clúster de esta práctica vive solo
mientras se trabaja en ella (ver `P10/terraform/`, diseñado para costo mínimo): una ventana de 30 d nunca
acumularía suficiente historia dentro de una sesión de prueba.

## 2. Fallo inducido

Se indujeron **dos** fallos distintos, ninguno igual al de la Práctica 8:

- **`FAULT_INJECTION=true` en `auth-service`:** 40% de las peticiones a `/auth/login` fallan con 500 y todas se
  retrasan 1.5 s. Gobierna la demo de síntoma-a-causa (operador humano).
- **`CANARY_FAULT_INJECTION=true` en `gateway`:** 50% de las peticiones fallan con 503 y se retrasan 2 s en TODAS
  las rutas excepto `/health`. Gobierna la demo del canario revertido por métricas (sin intervención).

Ambos se activan/desactivan cambiando una variable en el `ConfigMap` del servicio vía GitOps (commit + push), nunca
tocando pods en ejecución directamente — así el cambio dispara una revisión nueva (y, en el caso del gateway, un
canario) en lugar de perderse en el siguiente reconciliado de ArgoCD.

## 3. Tiempo de detección

[PENDIENTE: completar con `P10/evidencias/sintoma-a-causa.md` tras ejecutar `P10/scripts/prueba-sintoma-causa.ps1`]

| Marca | Hora (UTC) |
|---|---|
| T0 — fallo activado | [PENDIENTE] |
| T1 — primera señal (alerta `TasaErrorAuthServiceElevada` firing) | [PENDIENTE] |
| **Tiempo de detección (T1 − T0)** | **[PENDIENTE] s** |

## 4. Recorrido hasta la causa

[PENDIENTE: completar con la misma evidencia]

Pasos exactos seguidos (automatizados por el script, reproducibles a mano con el mismo orden):

1. Alerta `TasaErrorAuthServiceElevada` en estado *firing* (Alertmanager/Prometheus).
2. Desde el tablero de Grafana, panel de errores por servicio → confirmar que es específicamente `auth-service`.
3. Explore → datasource Tempo → `{ resource.service.name="auth-service" && status=error }` → una traza con error.
4. Desde esa traza, abrir sus registros en Loki (enlace automático `trace_id`) → confirmar el mensaje
   `"fallo inducido (FAULT_INJECTION) en /auth/login"`.

**Tiempo total (T2 − T0): [PENDIENTE] s ([PENDIENTE] min).** Objetivo de la rúbrica: menos de 3 minutos.

## 5. Tiempo de recuperación

[PENDIENTE: completar con la misma evidencia]

| Fallo | Quién/qué lo resolvió | Tiempo (T_fin − T0) |
|---|---|---|
| `FAULT_INJECTION` en auth-service | Un operador revierte el flag vía GitOps (`set-gitops-flag.ps1 -Value false`) | [PENDIENTE] s |
| `CANARY_FAULT_INJECTION` en gateway | **Argo Rollouts, automáticamente** (AnalysisRun `Failed` → abort) — ver `P10/evidencias/canary-metricas.md` | [PENDIENTE] s |

## 6. Alerta faltante o sobrante

**Faltante:** no existe una alerta separada para "latencia alta de PostgreSQL específicamente" — las alertas
actuales solo ven el síntoma agregado en el gateway/auth-service. Una alerta de saturación de la base de datos
(`pg_stat_activity` o `rate(process_cpu_seconds_total{service="postgresql"}[5m])`) habría acortado el diagnóstico
en el escenario donde la causa es la base de datos y no el código del servicio (ver runbook
`tasa-error-auth-service.md`, sección de límites).

**Sobrante (ruido potencial en producción):** `TasaErrorAuthServiceElevada` usa una ventana de evaluación corta
(1 minuto, `for: 1m`) comparada con las de presupuesto de error (2 minutos sobre 1h). Un pico aislado de ~70
segundos la dispara sin que el SLO general se vea afectado. Se mantuvo así por tratarse de un servicio crítico de
autenticación, pero en producción real debería evaluarse contra una ventana mayor antes de decidir si amerita
despertar a alguien cada vez.

## Mejora concreta propuesta a la propia instrumentación

Agregar una métrica de negocio específica `auth_fallidos_por_causa_total{causa="credenciales"|"bd"|"interno"}` en
`auth-service`, en lugar de depender de leer el mensaje de texto del log para distinguir la causa real de un 500.
Hoy, para saber si un error es "credenciales incorrectas" (esperado) o "la base de datos no responde"
(incidente real), hay que abrir la traza y leer el registro; con esa métrica adicional, la alerta
`TasaErrorAuthServiceElevada` podría dividirse por causa y dejar de dispararse por errores de usuario normales
(contraseña incorrecta), reduciendo el ruido sin perder sensibilidad ante fallos reales.
