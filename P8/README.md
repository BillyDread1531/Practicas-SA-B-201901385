# P8 - README de entrega

Este es el documento principal de localización de evidencias para la Práctica 8.

## 4.1 Tabla obligatoria de enlaces

| Ítem | Enlace o dato requerido |
|---|---|
| Repositorio GitOps | [Practica-SA-P8-GitOps](https://github.com/BillyDread1531/Practica-SA-P8-GitOps) |
| URL pública | [Repositorio de código](https://github.com/BillyDread1531/Practicas-SA-B-201901385) y [repositorio GitOps](https://github.com/BillyDread1531/Practica-SA-P8-GitOps) |
| Aplicación en ArgoCD | `sa-platform-dev` en namespace `argocd`; destino Kubernetes `sa-p8`. [Manifiesto](https://github.com/BillyDread1531/Practica-SA-P8-GitOps/blob/main/apps/sa-platform-dev.yaml) |
| Ejecución exitosa del pipeline | [Workflow p8-secure-gitops.yml](https://github.com/BillyDread1531/Practicas-SA-B-201901385/actions/workflows/p8-secure-gitops.yml). El run directo no está publicado en el workspace. |
| Reversión automática | [Informe de incidente](documentacion/incidente-rollback.md), [Rollout](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/P8/charts/gateway/templates/rollout.yaml) y [AnalysisTemplate](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/P8/charts/gateway/templates/analysis-template.yaml). El run directo no está publicado. |
| Despliegue rechazado por política | [Políticas Kyverno](https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/security/kyverno) y [manifiestos de evidencia](https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/documentacion). La URL directa del evento de rechazo no está publicada. |
| Bloqueo por vulnerabilidad crítica | [Workflow con Trivy](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/.github/workflows/p8-secure-gitops.yml). La URL directa del Pull Request bloqueado no está publicada. |
| Imagen firmada | `acrsa201901385.azurecr.io/gateway:1.0.4`. Verificación Cosign incluida en el workflow. |
| Reporte de prueba de carga | [P8/tests/k6/load.js](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/P8/tests/k6/load.js) |
| Video demostrativo | No publicado. Guion de demostración: arquitectura 00:00-01:00, Terraform/Helm 01:00-02:00, CI y seguridad 02:00-03:00, ArgoCD 03:00-04:00, Canary 04:00-05:00, rollback 05:00-06:00 y Kyverno 06:00-07:00. |

## Flujo técnico

Código fuente -> GitHub Actions -> validaciones -> imagen versionada -> Pull Request GitOps -> ArgoCD -> Kubernetes -> Argo Rollouts -> Canary -> análisis -> promoción o rollback.

| Componente | Responsabilidad | Evidencia |
|---|---|---|
| Terraform | Namespace, cuotas, límites y RBAC | [P8/terraform](https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/terraform) |
| Helm | Empaquetado de servicios y configuración | [P8/charts](https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/charts) |
| GitHub Actions | Lint, template, Trivy, SBOM, firma y PR GitOps | [p8-secure-gitops.yml](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/.github/workflows/p8-secure-gitops.yml) |
| ArgoCD | Sincronización declarativa | [Application](https://github.com/BillyDread1531/Practica-SA-P8-GitOps/blob/main/apps/sa-platform-dev.yaml) |
| Argo Rollouts | Canary 20/50/80/100 y rollback | [Manifiestos gateway](https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/charts/gateway/templates) |
| Kyverno | No `latest`, recursos obligatorios y no root | [Políticas](https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/security/kyverno) |
| Sealed Secrets | Gestión de secretos cifrados | [SealedSecret](https://github.com/BillyDread1531/Practica-SA-P8-GitOps/blob/main/security/sealed-secret.yaml) |

## Entrega progresiva

El gateway utiliza Canary con las etapas `20% -> análisis -> 50% -> análisis -> 80% -> análisis -> 100%`. Si el `AnalysisRun` supera el umbral de errores consecutivos, Argo Rollouts aborta la revisión, mantiene la versión estable y reduce la ReplicaSet defectuosa.

## Pruebas y seguridad

Las pruebas están en [P8/tests](https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/tests): smoke, integración y carga mediante k6. El pipeline valida Helm y manifiestos, bloquea vulnerabilidades críticas con Trivy, genera SBOM con Syft, firma/verifica con Cosign y actualiza el repositorio GitOps mediante Pull Request.

## Documentación adicional

- [Diagrama de arquitectura y flujo](documentacion/arquitectura.puml)
- [Matriz de evidencias](documentacion/evidencias.md)
- [Informe de incidente](documentacion/incidente-rollback.md)
- [Teoría y preguntas de defensa](documentacion/teoria.md)
