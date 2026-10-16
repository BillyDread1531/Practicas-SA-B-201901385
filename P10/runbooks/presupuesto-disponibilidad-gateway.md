# Runbook: PresupuestoDisponibilidadGatewayAgotandose

**Alerta:** `PresupuestoDisponibilidadGatewayAgotandose` · **Severidad:** critical · **SLO:** disponibilidad-gateway

## Por qué amerita intervención

No es un umbral instantáneo ("hubo un 500"). Esta alerta solo dispara cuando el **presupuesto de error** del SLO de
disponibilidad (99% de peticiones sin 5xx, ventana de 1 h) se está consumiendo a más de 2x la tasa sostenible durante
al menos 2 minutos. Si sigue así, el SLO del mes se incumple en horas, no en semanas. Una persona debe decidir si
revertir, escalar o esperar — por eso despierta a alguien.

## Diagnóstico (objetivo: menos de 3 minutos)

1. **Abrir el tablero de operación** en Grafana (`sa-operacion`) — panel "ERRORES" y el gauge de presupuesto de
   disponibilidad. Confirmar que el consumo sigue subiendo (no es un pico de 10 segundos ya resuelto).
2. **Ver qué versión está sirviendo tráfico:**
   ```powershell
   kubectl -n sa-p8 get rollout gateway
   kubectl -n sa-p8 argo rollouts get rollout gateway   # si el plugin esta instalado
   ```
   Si hay un canary en curso, lo más probable es que **el propio Argo Rollouts ya lo esté revirtiendo solo**
   (ver `P10/evidencias/canary-metricas.md`): confirmar que el AnalysisRun asociado está `Failed`.
3. **Si NO hay canary en curso** (el problema es de la versión estable): seguir la traza de una petición fallida
   desde el panel de logs del dashboard (filtrar `status_code=~"5.."`), copiar su `trace_id`, abrirlo en Tempo
   (enlace automático desde Loki) para ver en qué servicio/span ocurrió el error real.
4. **Revisar si algún flag de fallo inducido quedó encendido por error** (debería estar en `false` en operación
   normal):
   ```powershell
   kubectl -n sa-p8 get configmap auth-service-config gateway-config -o jsonpath='{.items[*].data.FAULT_INJECTION}{" "}{.items[*].data.CANARY_FAULT_INJECTION}'
   ```

## Mitigación

- **Si es un canary que no se revirtió solo** (caso excepcional — ver §Límites): `kubectl -n sa-p8 argo rollouts abort gateway` o `kubectl -n sa-p8 patch rollout gateway --type merge -p '{"spec":{"paused":true}}'` seguido de `undo`.
- **Si es la versión estable:** revertir el commit en el repositorio GitOps (`git revert` sobre `environments/dev/values.yaml`) y dejar que ArgoCD sincronice el estado anterior.
- **Si es una dependencia externa** (PostgreSQL, RabbitMQ): ver `kubectl -n sa-p8 get pods` y los runbooks de P9 (pérdida de nodo / restauración de datos) si aplica.

## Límites conocidos

Esta alerta se superpone intencionalmente con la reversión automática del canary: si el fallo viene de un canary,
Argo Rollouts debería resolverlo antes de que el presupuesto de 1 h se agote del todo. Si esta alerta llega a
*firing* de todas formas, es la señal de que la reversión automática no alcanzó a tiempo o el fallo está en la
versión estable — en ambos casos, requiere una persona.
