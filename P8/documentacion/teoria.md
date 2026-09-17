# Fundamentos teóricos

## GitOps
GitOps utiliza Git como fuente declarativa del estado deseado. Argo CD sincroniza el repositorio GitOps con Kubernetes.

## Terraform
Terraform administra Namespace, ResourceQuota, LimitRange, ServiceAccounts, Role y RoleBindings.

## Helm
Helm empaqueta los microservicios mediante charts y permite separar valores por ambiente.

## Entrega progresiva
Argo Rollouts utiliza Canary: 20% -> 50% -> 80% -> 100%. Cada etapa intermedia utiliza AnalysisTemplate.

## Rollback
Cuando el análisis falla, Argo Rollouts puede abortar la progresión y mantener el tráfico en la versión estable.

## Seguridad
Trivy analiza vulnerabilidades. Syft genera SBOM. Cosign firma y verifica imágenes. k6 valida comportamiento mediante smoke, integration y load tests.

## Versionado
Las versiones de release se derivan de tags Git. No se utiliza latest.

## Secretos
Los secretos de aplicación se gestionan mediante Sealed Secrets y no deben almacenarse en texto plano en GitOps.

## Kyverno
Las políticas obligan a no utilizar latest, exigir requests/limits y ejecutar como usuario no root.
