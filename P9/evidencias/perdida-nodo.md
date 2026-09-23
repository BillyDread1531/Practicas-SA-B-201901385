# Prueba de pérdida de nodo

| Campo | Valor |
|---|---|
| Nodo drenado | PENDIENTE |
| Hora de inicio | PENDIENTE |
| Réplicas configuradas | PENDIENTE |
| PDB observado | PENDIENTE |
| Servicio respondió durante el drenaje | PENDIENTE |
| Hora de finalización | PENDIENTE |

Registrar `kubectl get pods -o wide`, `kubectl get pdb` y las respuestas del endpoint durante el drenaje.

## Preparación verificada

- PDB existentes en `sa-p8`: `auth-service`, `cursos-service`, `estudiantes-service`, `gateway` e `inscripciones-service`.
- Réplicas declaradas: 2 por servicio.
- Anti-afinidad añadida en los templates Helm para separar réplicas por `kubernetes.io/hostname`.
- Validación: `helm template sa-platform` renderiza `requiredDuringSchedulingIgnoredDuringExecution` para los cinco servicios y Gateway.
- Estado previo al drenaje: los PDB reportan `allowedDisruptions=0` porque el despliegue remoto todavía mantiene imágenes `p6` fallidas y solo una réplica disponible por servicio.
- Drenaje real: pendiente de sincronizar estos templates en ArgoCD y ejecutar la prueba sobre el despliegue corregido.