# P8 - Documentación

## Componentes

- Terraform: infraestructura base.
- Helm: empaquetado de microservicios.
- GitHub Actions: CI y seguridad.
- Trivy: vulnerabilidades.
- Syft: SBOM.
- Cosign: firma y verificación.
- k6: smoke, integration y load.
- GitOps: repositorio independiente.
- Argo CD: sincronización.
- Argo Rollouts: entrega Canary y rollback.
- Kyverno: políticas de admisión.
- Sealed Secrets: gestión de secretos.

## Flujo

Código -> GitHub Actions -> validaciones -> PR GitOps -> Argo CD -> Kubernetes -> Argo Rollouts

Canary: 20% -> Analysis -> 50% -> Analysis -> 80% -> Analysis -> 100%
