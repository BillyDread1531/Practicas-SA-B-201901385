# Evidencias P8

Estos archivos son registros textuales de verificaciones realizadas sobre el clúster y el repositorio.

## Disponibles

- [Estado final de ArgoCD y Rollout](evidencia-estado-final.md)
- [Rollback y AnalysisRun fallido](evidencia-rollback.md)
- [Verificación de imagen firmada](evidencia-cosign.md)
- [Políticas Kyverno](evidencia-kyverno.md)
- [Pruebas k6](evidencia-k6.md)

## Capturas

- [ArgoCD y Rollout](01-argocd-rollout-healthy.png)
- [Rollback](02-rollback-analysisrun.png)
- [Políticas Kyverno](03-kyverno-politicas.png)
- [Rechazo Kyverno](04-kyverno-rechazo.png)
- [Cosign](05-cosign-verificacion.png)
- [k6](06-k6-load.png)
- [Verificador](07-verificador-final.txt)
- [GitHub Actions](08-github-actions-exitoso.png)
- [Diagrama](09-diagrama-gitops.png)

## Pendientes de captura externa

- Run directo de GitHub Actions y artefactos del pipeline.
- Pull Request bloqueado por Trivy.
- Recurso rechazado por Kyverno con su evento o salida de `kubectl apply`.
- Reporte de ejecución de k6.
- Captura de la interfaz de ArgoCD.
- Video demostrativo de 5 a 8 minutos.

No se presentan como evidencia hechos que no tengan un registro local o una URL pública verificable.
