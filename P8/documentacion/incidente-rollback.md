# Incidente y rollback automático

## 1. Qué falló

Durante una prueba controlada de entrega progresiva del gateway se utilizó deliberadamente una revisión defectuosa.

La nueva ReplicaSet llegó a la primera etapa de exposición Canary, correspondiente al 20%. La validación de salud del gateway Canary comenzó a fallar y el AnalysisRun terminó en estado Error.

El análisis registró errores consecutivos por encima del límite configurado.

## 2. Cómo se detectó

La detección fue realizada automáticamente por Argo Rollouts mediante el AnalysisTemplate gateway-health.

El flujo observado fue:

1. Creación de la nueva ReplicaSet.
2. Activación de la nueva revisión como Canary.
3. Exposición inicial del 20%.
4. Ejecución del AnalysisRun.
5. Resultado Error por fallos consecutivos de la métrica de salud.
6. Aborto automático del Rollout.

No fue necesaria una intervención manual para detectar el fallo.

## 3. Cómo se contuvo

Argo Rollouts contuvo automáticamente la versión defectuosa:

1. Abortó la progresión.
2. Restauró el tráfico del servicio Canary hacia la versión estable.
3. Redujo la ReplicaSet defectuosa.
4. Conservó la versión estable como revisión activa.

No se ejecutó kubectl apply, kubectl set image ni un rollback manual para recuperar el servicio.

## 4. Tiempo de recuperación

La recuperación ocurrió automáticamente durante la misma ejecución del Rollout, después de que el AnalysisRun alcanzó el estado Error.

En esta práctica no se registró un cronómetro externo para expresar la recuperación en segundos. Por ello, el tiempo se documenta como recuperación automática dentro de la ejecución de la entrega progresiva y no como una duración inventada.

## 5. Cómo prevenirlo

Las medidas preventivas implementadas son:

- Canary antes de promover al 100%.
- AnalysisTemplate en las etapas intermedias.
- Umbral de errores consecutivos para determinar fallo.
- Rollback automático mediante Argo Rollouts.
- Pruebas smoke, integración y carga mediante k6.
- Análisis de vulnerabilidades con Trivy.
- Generación de SBOM mediante Syft.
- Firma y verificación de imágenes mediante Cosign.
- Políticas Kyverno para impedir imágenes latest, exigir recursos y evitar ejecución como root.
- Flujo GitOps mediante repositorio independiente y Argo CD.

## Resultado

La prueba confirmó que una versión defectuosa puede ser detectada antes de completar la promoción al 100% y que Argo Rollouts puede restaurar automáticamente el tráfico hacia la versión estable.

La evidencia observada incluyó:

- nueva ReplicaSet defectuosa;
- tráfico Canary dirigido a la nueva revisión;
- AnalysisRun con resultado Error;
- RolloutAbort;
- restauración del selector estable;
- reducción de la ReplicaSet defectuosa;
- recuperación de la versión estable.

## Lección técnica

La entrega progresiva reduce el impacto de una versión defectuosa porque permite validar una nueva versión en etapas controladas antes de exponerla completamente.
