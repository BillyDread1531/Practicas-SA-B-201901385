# P8 - GitOps, entrega progresiva y seguridad de la cadena de suministro

## Flujo de entrega

Código fuente → GitHub Actions → validaciones → imagen versionada → PR GitOps → Argo CD → Kubernetes → Argo Rollouts → Canary → análisis → promoción o rollback.

## Componentes

- Terraform: infraestructura base del namespace.
- Helm: empaquetado y configuración de los servicios.
- GitHub Actions: integración continua y seguridad.
- Trivy: análisis de vulnerabilidades.
- Syft: generación de SBOM.
- Cosign: firma y verificación de imágenes.
- k6: pruebas smoke, integración y carga.
- Argo CD: sincronización GitOps.
- Argo Rollouts: entrega progresiva Canary y rollback.
- Kyverno: políticas de admisión.
- Sealed Secrets: manejo seguro de secretos.

## Evidencias y enlaces

| Evidencia | Ubicación |
|---|---|
| Repositorio de código | https://github.com/BillyDread1531/Practicas-SA-B-201901385 |
| Repositorio GitOps | https://github.com/BillyDread1531/Practica-SA-P8-GitOps |
| Workflow CI/CD seguro | https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/.github/workflows/p8-secure-gitops.yml |
| Terraform | https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/terraform |
| Helm | https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/charts |
| GitOps Application | https://github.com/BillyDread1531/Practica-SA-P8-GitOps/blob/main/apps/sa-platform-dev.yaml |
| Valores de desarrollo | https://github.com/BillyDread1531/Practica-SA-P8-GitOps/blob/main/environments/dev/values.yaml |
| Políticas Kyverno | https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/security/kyverno |
| Sealed Secrets | https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/charts/sa-platform/templates |
| Pruebas | https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/tests |
| Documentación | https://github.com/BillyDread1531/Practicas-SA-B-201901385/tree/main/P8/documentacion |

## Entrega progresiva

El gateway utiliza estrategia Canary con los siguientes pesos:

20% → análisis → 50% → análisis → 80% → análisis → 100%.

Ante un resultado fallido del análisis, Argo Rollouts aborta la nueva revisión y restaura el tráfico hacia la versión estable.

## Seguridad de la cadena de suministro

La integración continua realiza:

1. Validación de Helm.
2. Validación de manifiestos.
3. Análisis Trivy.
4. Generación de SBOM mediante Syft.
5. Firma mediante Cosign.
6. Verificación de firma.
7. Construcción de imágenes con versión derivada del tag Git.
8. Actualización del repositorio GitOps mediante Pull Request.

## Políticas de admisión

Kyverno aplica:

- Prohibición de imágenes con tag latest.
- Requerimiento de límites de CPU y memoria.
- Requerimiento de ejecución como usuario no root.

Las políticas excluyen los namespaces internos de Argo CD y Kyverno para evitar interferir con sus componentes de control.

## Incidente y rollback

Se probó deliberadamente una revisión defectuosa del gateway. El análisis Canary detectó errores durante la validación de salud y Argo Rollouts abortó automáticamente la promoción.

La evidencia muestra:

- nueva ReplicaSet defectuosa creada;
- tráfico Canary dirigido a la nueva revisión;
- AnalysisRun con resultado Error;
- RolloutAbort;
- restauración del selector estable;
- reducción de la ReplicaSet defectuosa;
- recuperación del servicio estable.

## Preconditions de evaluación

- P7 previamente entregado.
- Aplicación Argo CD sa-platform-dev.
- Namespace sa-p8.
- Sin despliegues directos mediante kubectl apply, kubectl set image o helm upgrade en el workflow P8.
- Despliegue gestionado mediante GitOps.
- Rollback automático demostrado.
- Repositorio GitOps independiente y público.

## Video de demostración

La demostración debe mostrar:

- 00:00–01:00 arquitectura y repositorios.
- 01:00–02:00 Terraform y Helm.
- 02:00–03:00 GitHub Actions y seguridad.
- 03:00–04:00 Argo CD Synced/Healthy.
- 04:00–05:00 Canary y AnalysisRun.
- 05:00–06:00 rollback automático.
- 06:00–07:00 Kyverno y evidencias finales.
