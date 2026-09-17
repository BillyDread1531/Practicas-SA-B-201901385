# Incidente y rollback automático

## Contexto

Durante la validación de entrega progresiva del gateway se utilizó una revisión defectuosa para comprobar el mecanismo de detección y reversión.

El objetivo fue demostrar que una versión que no supera el análisis del canary no continúa hacia el 100%.

## Comportamiento observado

Argo Rollouts inició la nueva revisión y comenzó la progresión Canary.

La versión defectuosa llegó a la primera etapa de exposición, correspondiente al 20%.

Durante el AnalysisRun, la métrica de salud del gateway canary terminó en estado Error.

El análisis registró errores consecutivos por encima del límite permitido.

## Acción automática

El Rollout fue abortado.

Argo Rollouts:

1. Detuvo la progresión.
2. Restauró el selector del servicio canary hacia la versión estable.
3. Redujo la capacidad de la ReplicaSet defectuosa.
4. Conservó la versión estable como versión activa.

No fue necesario ejecutar un rollback manual mediante kubectl.

## Resultado

La prueba confirmó que la entrega progresiva puede detectar una versión defectuosa antes de completar la promoción.

El incidente demuestra la separación entre:

- CI;
- repositorio GitOps;
- sincronización mediante Argo CD;
- análisis de canary;
- rollback mediante Argo Rollouts.

## Lección técnica

La entrega progresiva reduce el impacto de una versión defectuosa porque permite detener la promoción durante una etapa intermedia en lugar de exponer inmediatamente la nueva versión al 100%.