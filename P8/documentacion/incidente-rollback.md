# Informe de incidente: rollback automático

**Qué falló:** Se publicó deliberadamente una revisión defectuosa del `gateway`. La revisión llegó al primer paso Canary del 20%, pero la métrica `gateway-health` no pudo resolver `gateway-canary` y el `AnalysisRun` terminó en estado `Error` después de cinco errores consecutivos.

**Cómo se detectó:** Argo Rollouts ejecutó el `AnalysisTemplate` `gateway-health` durante la promoción. El umbral configurado fue `consecutiveErrorLimit: 4`; la ejecución registró cinco errores consecutivos y marcó la métrica como `Error`.

**Cómo se contuvo:** Argo Rollouts abortó automáticamente la promoción en el 20% de tráfico, conservó la ReplicaSet estable, redujo la revisión defectuosa y restauró el tráfico al servicio estable. No se ejecutó `kubectl apply`, `kubectl set image` ni rollback manual.

**Tiempo de recuperación:** El `AnalysisRun` comenzó a las `20:40:30` y terminó a las `20:41:10`, es decir, 40 segundos (0.67 minutos) desde la primera medición hasta la detección. El registro disponible no contiene la hora exacta de publicación, por lo que no se inventa un tiempo publicación-a-estable.

**Cómo prevenirlo:** Mantener análisis obligatorios antes de cada aumento de tráfico, pruebas smoke/integración/carga, Trivy para vulnerabilidades críticas, firma Cosign, revisión GitOps mediante Pull Request y políticas Kyverno de no `latest`, límites de recursos y ejecución no root.
