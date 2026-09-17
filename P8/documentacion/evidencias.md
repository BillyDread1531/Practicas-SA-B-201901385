# Matriz de evidencias P8

| Requisito | Evidencia |
|---|---|
| Terraform | P8/terraform/ |
| Namespace | Terraform kubernetes_namespace |
| Quota | Terraform kubernetes_resource_quota |
| LimitRange | Terraform kubernetes_limit_range |
| RBAC | ServiceAccounts, Role y RoleBindings |
| Helm | P8/charts/ |
| Helm lint | Workflow P8 |
| GitOps independiente | Repositorio P8-GitOps |
| Argo CD | P8-GitOps/apps/sa-platform-dev.yaml |
| Canary | Rollout del gateway |
| Promoción 20/50/80/100 | Argo Rollouts |
| AnalysisTemplate | P8/charts/gateway/templates/analysis-template.yaml |
| Smoke | P8/tests/k6/smoke.js |
| Integration | P8/tests/k6/integration.js |
| Load | P8/tests/k6/load.js |
| Thresholds | Configuración 	hresholds de k6 |
| Trivy | Workflow P8 |
| SBOM | Syft en workflow |
| Firma | Cosign en workflow |
| Verificación | Cosign verify en workflow |
| No latest | Kyverno + validación CI |
| Recursos obligatorios | Kyverno |
| No root | Kyverno + securityContext |
| Secretos | Sealed Secrets |
| Versionado | Tags Git / SemVer |
| Rollback | incidente-rollback.md |
| Arquitectura | rquitectura.puml |

## Separación de responsabilidades

GitHub Actions valida y construye.

El repositorio GitOps contiene el estado deseado.

Argo CD sincroniza ese estado.

Argo Rollouts controla la entrega progresiva.

Kyverno aplica las políticas de admisión.

No se utiliza kubectl apply, kubectl set image ni helm upgrade desde el workflow para desplegar directamente.