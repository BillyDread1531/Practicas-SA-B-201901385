# P8 - Documentación

## Objetivo

La práctica implementa un flujo de entrega basado en GitOps, entrega progresiva y seguridad de la cadena de suministro de software.

El objetivo es validar los cambios automáticamente, construir imágenes versionadas, mantener el estado deseado en un repositorio GitOps independiente y utilizar Argo CD y Argo Rollouts para realizar la entrega progresiva.

## Componentes

- Terraform: infraestructura base del namespace.
- Helm: empaquetado y configuración de microservicios.
- GitHub Actions: integración continua y validaciones de seguridad.
- Trivy: análisis de vulnerabilidades.
- Syft: generación de SBOM.
- Cosign: firma y verificación de imágenes.
- k6: pruebas smoke, integración y carga.
- GitOps: repositorio independiente para el estado deseado.
- Argo CD: sincronización con Kubernetes.
- Argo Rollouts: entrega Canary y rollback automático.
- Kyverno: políticas de admisión.
- Sealed Secrets: gestión segura de secretos.

## Flujo de entrega

Código fuente -> GitHub Actions -> validaciones -> imagen versionada -> actualización del repositorio GitOps -> Argo CD -> Kubernetes -> Argo Rollouts.

## Entrega progresiva

El gateway utiliza una estrategia Canary:

20% -> análisis -> 50% -> análisis -> 80% -> análisis -> 100%.

Cada etapa intermedia utiliza un AnalysisTemplate para validar la salud del servicio.

Si el análisis falla, Argo Rollouts aborta la progresión y mantiene el tráfico en la versión estable.

## Seguridad de la cadena de suministro

La integración continua realiza:

1. Validación de Helm.
2. Validación de manifiestos.
3. Análisis Trivy del código y de las imágenes.
4. Generación de SBOM mediante Syft.
5. Firma mediante Cosign.
6. Verificación de la firma.
7. Construcción de imágenes con versiones derivadas del flujo de release.
8. Actualización del repositorio GitOps sin realizar un despliegue directo desde GitHub Actions.

## Políticas de admisión

Kyverno aplica:

- Prohibición de imágenes con tag latest.
- Requerimiento de requests y limits de CPU y memoria.
- Requerimiento de ejecución como usuario no root.

Las políticas excluyen los namespaces internos necesarios para los componentes de control de Argo CD y Kyverno.

## Rollback automático

La práctica incluye una prueba controlada con una revisión defectuosa del gateway.

El AnalysisRun detectó errores consecutivos durante la exposición Canary y el Rollout fue abortado automáticamente.

La evidencia del incidente se encuentra en:

P8/documentacion/incidente-rollback.md

## Evidencias

La matriz completa de evidencias se encuentra en:

P8/documentacion/evidencias.md

La arquitectura está definida en:

P8/documentacion/arquitectura.puml

## Teoría

Los fundamentos conceptuales de GitOps, Terraform, Helm, entrega progresiva, rollback, seguridad, versionado, secretos y Kyverno se encuentran en:

P8/documentacion/teoria.md
"@ | Set-Content .\P8\documentacion\README.md -Encoding utf8

@"
# Fundamentos teóricos

## GitOps

GitOps utiliza Git como fuente declarativa del estado deseado. Los cambios se almacenan en un repositorio Git y Argo CD sincroniza ese estado con Kubernetes.

La principal separación de responsabilidades es que CI valida y construye, mientras que el repositorio GitOps representa el estado que debe ejecutarse en el clúster.

## Terraform

Terraform permite definir la infraestructura base de forma declarativa y reproducible.

En esta práctica administra el namespace, ResourceQuota, LimitRange, ServiceAccounts, Role y RoleBindings requeridos por P8.

## Helm

Helm permite empaquetar aplicaciones Kubernetes mediante charts.

Los charts separan la estructura de los manifiestos de los valores utilizados por cada ambiente y permiten mantener una configuración reproducible.

## Entrega progresiva

Argo Rollouts implementa una estrategia Canary para exponer gradualmente una nueva versión.

En esta práctica las etapas son:

20% -> 50% -> 80% -> 100%.

Entre las etapas se ejecutan análisis de salud para determinar si la nueva revisión puede continuar.

## Rollback

Cuando el análisis de una nueva revisión falla, Argo Rollouts puede abortar la progresión y conservar la versión estable.

Esto evita promover automáticamente una versión defectuosa al 100% de los usuarios.

## Seguridad de la cadena de suministro

Trivy analiza vulnerabilidades conocidas.

Syft genera un Software Bill of Materials (SBOM) que describe los componentes incluidos en una imagen.

Cosign permite firmar las imágenes y posteriormente verificar que la imagen corresponde a una firma válida.

## Pruebas automatizadas

k6 permite ejecutar pruebas smoke, integración y carga para validar el comportamiento del servicio antes de actualizar el estado GitOps.

## Versionado

Las imágenes deben utilizar versiones identificables y reproducibles.

El flujo de release utiliza tags Git para obtener versiones de las imágenes y evita utilizar el tag mutable latest.

## Secretos

Los secretos de aplicación se gestionan mediante Sealed Secrets.

El repositorio GitOps no debe contener contraseñas ni secretos de aplicación en texto plano.

## Kyverno

Kyverno permite aplicar políticas de admisión directamente sobre los recursos Kubernetes.

En P8 se utilizan políticas para:

- impedir imágenes con tag latest;
- exigir requests y limits;
- exigir ejecución como usuario no root.

Estas políticas ayudan a impedir que recursos que incumplen los controles de seguridad lleguen al clúster.
