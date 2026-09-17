# Validacion automatizada P8

## Smoke

Verifica que el endpoint `/health` responda HTTP 200.

## Integracion

Realiza solicitudes concurrentes al gateway y valida que la respuesta sea HTTP 200 y JSON valido.

## Load

Incrementa progresivamente la concurrencia hasta 10 usuarios virtuales.

## Umbrales

- Error rate: menor al 5%.
- Latencia p95: menor a 1000 ms.

Estos valores permiten detectar fallos funcionales y degradaciones relevantes sin considerar como fallo pequeñas variaciones normales de latencia.

El AnalysisTemplate del gateway utiliza una validacion independiente durante el canary. Si la nueva version no responde correctamente, Argo Rollouts aborta la progresion y recupera la ReplicaSet estable.
