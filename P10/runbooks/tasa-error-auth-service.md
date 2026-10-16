# Runbook: TasaErrorAuthServiceElevada

**Alerta:** `TasaErrorAuthServiceElevada` · **Severidad:** critical · **Servicio:** auth-service

## Por qué amerita intervención

`auth-service` resuelve el login de toda la plataforma: si falla, nadie puede autenticarse y todos los servicios
protegidos detrás del gateway quedan inalcanzables para usuarios nuevos. Un 10% de error sostenido durante 1 minuto
ya afecta a una fracción significativa de los intentos de inicio de sesión — se trata como crítico aunque el SLO
general del gateway (ventana de 1 h) todavía no se haya resentido.

## Diagnóstico (objetivo: menos de 3 minutos — este es el escenario de la demo "síntoma a causa")

1. **Tablero de operación** → panel "Tasa de error por servicio": confirmar que el pico es específicamente de
   `auth-service` y no de todo el sistema.
2. **Abrir una traza con error:**
   ```promql
   # En Grafana Explore, datasource Tempo:
   { resource.service.name="auth-service" && status=error }
   ```
3. **Del resultado, copiar el `trace_id`** y abrir sus logs (botón "Logs for this span", o directamente en el panel
   de registros del tablero filtrando por ese `trace_id`). El mensaje de registro dice exactamente la causa (por
   ejemplo: `"fallo inducido (FAULT_INJECTION) en /auth/login"`).
4. Si el mensaje no es un fallo inducido, revisar la conexión a PostgreSQL:
   ```powershell
   kubectl -n sa-p8 exec -it deploy/auth-service -- wget -qO- http://localhost:3001/db-test
   ```

## Mitigación

- **Fallo inducido activo:** `P10/scripts/set-gitops-flag.ps1 -Service auth-service -Key FAULT_INJECTION -Value false`.
- **Base de datos caída/lenta:** ver runbooks de P9 (`P9/runbook-recuperacion.md`), escenarios de pérdida de nodo o
  restauración de datos.
- **Despliegue roto (no fallo inducido):** revertir el último commit de `environments/dev/values.yaml` en el
  repositorio GitOps.

## Límites conocidos

Esta alerta mide solo `auth-service`; no distingue si el error viene de su propio código o de una dependencia
(PostgreSQL). El paso 4 del diagnóstico cubre esa distinción, pero requiere un paso manual adicional — una mejora
pendiente sería una métrica de negocio específica de "fallos de conexión a base de datos" separada del contador
genérico de errores HTTP.
