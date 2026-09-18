# Matriz de evidencias P8

| Requisito | Evidencia |
|---|---|
| Terraform | P8/terraform/main.tf y estado Terraform |
| Terraform plan/apply | Ejecución de terraform plan y terraform apply sobre la infraestructura P8 |
| Namespace | kubernetes_namespace administrado por Terraform |
| ResourceQuota | kubernetes_resource_quota administrado por Terraform |
| LimitRange | kubernetes_limit_range administrado por Terraform |
| RBAC | ServiceAccounts, Role y RoleBindings administrados por Terraform |
| Helm | P8/charts/ |
| Helm lint | Workflow p8-secure-gitops.yml |
| Helm template | Workflow p8-secure-gitops.yml |
| GitOps independiente | Repositorio Practica-SA-P8-GitOps |
| Argo CD Application | P8-GitOps/apps/sa-platform-dev.yaml |
| Argo CD estado | sa-platform-dev en estado Synced y Healthy |
| Argo CD sync history | Historial de sincronizaciones de sa-platform-dev |
| Canary | P8/charts/gateway/templates/rollout.yaml |
| Promoción 20/50/80/100 | Argo Rollouts |
| AnalysisTemplate | P8/charts/gateway/templates/analysis-template.yaml |
| Smoke | P8/tests/k6/smoke.js |
| Integration | P8/tests/k6/integration.js |
| Load | P8/tests/k6/load.js |
| Thresholds | Thresholds definidos en los scripts de k6 |
| Trivy filesystem | Workflow P8 |
| Trivy imagen | Workflow P8 |
| SBOM | Syft en workflow y artefactos de SBOM |
| Firma | Cosign en workflow |
| Verificación | cosign verify en workflow |
| No latest | Validación CI + política Kyverno |
| Recursos obligatorios | Política Kyverno p8-require-resources |
| No root | Política Kyverno p8-require-non-root |
| Secretos | Sealed Secrets |
| Versionado | Tags Git / SemVer |
| Rollback automático | P8/documentacion/incidente-rollback.md |
| Arquitectura | P8/documentacion/arquitectura.puml |
| Documentación | P8/documentacion/ |

## Separación de responsabilidades

GitHub Actions valida y construye las imágenes.

El repositorio GitOps contiene el estado deseado de la aplicación.

Argo CD sincroniza el estado deseado con Kubernetes.

Argo Rollouts controla la entrega progresiva Canary y el rollback automático.

Kyverno aplica las políticas de admisión.

No se utiliza kubectl apply, kubectl set image, helm upgrade ni kubeconfig desde el workflow P8 para desplegar directamente en el clúster.
