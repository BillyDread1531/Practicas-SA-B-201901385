# Práctica 9: Continuidad operativa y recuperación ante desastres

Este directorio reconstruye AKS desde Terraform y entrega el resto del sistema mediante ArgoCD. Terraform también crea el almacenamiento Blob externo y despliega Velero con respaldo de volúmenes mediante node-agent.

## Estado actual

- **Estado remoto de Terraform:** backend azurerm con bloqueo en Azure Storage Account sttfstatesa201901385.
- **Bootstrap:** terraform apply en P9/terraform instala AKS, ArgoCD, Velero y la app-of-apps p9-root-app.
- **Datos:** PostgreSQL y RabbitMQ con PVC en sa-p8, definidos por el GitOps de P8.
- **Secretos:** Sealed Secrets con llave respaldada en Azure Blob (sealed-secrets-key6v5m9.yaml).
- **Velero:** schedule velero-p9-platform, cada 6 horas UTC, retención de 30 días, destino Blob privado fuera del clúster.
- **Resiliencia:** PDB, anti-afinidad preferred y prueba de drenaje de nodo ejecutada exitosamente.
- **Bootstrap cronometrado:** ejecutado el 2026-09-23. RTO real medido: 41 minutos (objetivo declarado: 60 minutos).

## Tabla de enlaces obligatoria

| Ítem | Enlace o dato requerido |
|------|-------------------------|
| **Repositorio GitOps** | https://github.com/BillyDread1531/Practica-SA-P8-GitOps.git (rama p9) |
| **Aplicación raíz en ArgoCD** | p9-root-app, namespace argocd |
| **Punto de entrada del bootstrap** | P9/terraform/ — terraform apply |
| **Backend remoto de Terraform** | Azure Storage Account sttfstatesa201901385, container tfstate, key p9-platform.tfstate |
| **Schedule de Velero** | velero-p9-platform, namespace velero, destino stvelerosa201901385/velero |
| **Reconstrucción cronometrada** | P9/evidencias/bootstrap-exitoso.md |
| **Restauración de datos** | P9/evidencias/restauracion-datos.md |
| **Prueba de pérdida de nodo** | P9/evidencias/perdida-nodo.md |
| **RTO y RPO declarados** | RTO: 60 min (real: 41 min). RPO: 6 h. Ver P9/informe-dr.md |
| **Video demostrativo** | https://www.youtube.com/watch?v=XXXXX — ver minutaje abajo |

### Minutaje del video

- 00:00 — Introducción y contexto
- 00:30 — Arquitectura GitOps en ArgoCD
- 01:30 — Bootstrap con Terraform
- 03:00 — Verificación del sistema reconstruido
- 04:00 — Prueba de pérdida de nodo
- 05:30 — Respaldo y restauración con Velero
- 07:00 — Cierre y lecciones aprendidas

## Documentación

- **Runbook de recuperación:** [runbook-recuperacion.md](runbook-recuperacion.md)
- **Informe de la prueba de DR:** [informe-dr.md](informe-dr.md)
- **SPOFs detectados:** [docs/spofs-detectados.md](docs/spofs-detectados.md)
- **Diagrama de bootstrap:** [docs/diagrama-bootstrap.puml](docs/diagrama-bootstrap.puml)

## Bootstrap

Desde PowerShell, con Azure CLI autenticado:

    Set-Location .\P9\terraform

    terraform init
    terraform plan
    terraform apply

    # Configurar kubectl
    az aks get-credentials --resource-group rg-sa-p9 --name aks-sa-p9 --overwrite-existing

    # Instalar controladores adicionales no incluidos en Terraform
    kubectl apply --server-side --force-conflicts -f https://github.com/argoproj/argo-rollouts/releases/download/v1.7.2/install.yaml
    kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.27.3/controller.yaml
    kubectl apply -f https://github.com/kyverno/kyverno/releases/download/v1.13.0/install.yaml

    # Restaurar llave de Sealed Secrets
    kubectl apply -f .\P9\secrets-backup\sealed-secrets-key6v5m9.yaml

    # Verificar
    kubectl get applications -n argocd
    kubectl get pods -n sa-p8

No se debe versionar archivos .tfplan, .tfvars con secretos, ni ningún archivo de estado local.

## Verificación del respaldo

    kubectl -n velero get schedule velero-p9-platform -o yaml
    velero backup create p9-manual-$(Get-Date -Format yyyyMMddHHmm) --include-namespaces sa-p8 --include-cluster-resources=true --default-volumes-to-fs-backup --wait
    velero backup get
    velero backup describe <NOMBRE> --details

La restauración se ejecuta solo sobre un namespace nuevo y después de registrar el estado original. El procedimiento y las verificaciones están en [runbook-recuperacion.md](runbook-recuperacion.md).

## Evidencias

Las marcas de tiempo y salidas reales se guardan en [evidencias](evidencias/).

| Evidencia | Archivo |
|-----------|---------|
| Bootstrap cronometrado | evidencias/bootstrap-exitoso.md |
| Pérdida de nodo | evidencias/perdida-nodo.md |
| Restauración de datos | evidencias/restauracion-datos.md |
| Respaldo Velero | evidencias/respaldo-velero-*.md |
| Reconstrucción | evidencias/reconstruccion-cronometrada.md |

## RTO y RPO

| Objetivo | Declarado | Medido | Cumplimiento |
|----------|-----------|--------|--------------|
| RTO bootstrap | 60 minutos | 41 minutos | Cumplido |
| RPO datos | 6 horas | Ver informe DR | Documentado en informe-dr.md |

