# Práctica 9: continuidad operativa y recuperación ante desastres

Este directorio reconstruye AKS desde Terraform y entrega el resto del sistema mediante ArgoCD. Terraform también crea el almacenamiento Blob externo y despliega Velero con respaldo de volúmenes mediante node-agent.

## Estado actual

- Estado remoto de Terraform: backend `azurerm` con bloqueo.
- Bootstrap: `terraform apply` en `P9/terraform` instala AKS, ArgoCD y `p9-root-app`.
- Datos: PostgreSQL y RabbitMQ con PVC en `sa-p8`, definidos por el GitOps de P8.
- Secretos: Sealed Secrets en el repositorio GitOps de P8.
- Velero: schedule `p9-platform`, cada 6 horas UTC, retención de 30 días, destino Blob privado fuera del clúster.
- Resiliencia: PDB y afinidad anti-pod ya forman parte de los charts de P8; falta ejecutar y registrar el drenaje.
- Evidencia actual: `p9-valid-20260922` completó correctamente con 568 recursos respaldados.

## Tabla de enlaces de entrega

| Ítem | Enlace o dato requerido |
|---|---|
| Repositorio GitOps | https://github.com/BillyDread1531/Practica-SA-P8-GitOps |
| Aplicación raíz en ArgoCD | `p9-root-app`, namespace `argocd` |
| Punto de entrada del bootstrap | `P9/terraform/` con `terraform apply` |
| Backend remoto de Terraform | Azure Storage Account configurada en el backend, con locking Blob |
| Schedule de Velero | `p9-platform`, namespace `velero`, cuenta Blob `stvelerosa201901385` |
| Reconstrucción cronometrada | `P9/evidencias/reconstruccion-cronometrada.md` |
| Restauración de datos | `P9/evidencias/restauracion-datos.md` |
| Prueba de pérdida de nodo | `P9/evidencias/perdida-nodo.md` |
| RTO y RPO declarados | Pendiente de medir; objetivos iniciales: RTO 30 min, RPO 6 h |
| Video demostrativo | Pendiente de grabar; agregar URL y minutaje antes de entregar |

## Bootstrap

Desde PowerShell, con Azure CLI autenticado y `TF_VAR_github_pat` definido en la sesión:

```powershell
Set-Location .\P9\terraform
terraform init
terraform plan -out p9.tfplan
terraform apply p9.tfplan
az aks get-credentials --resource-group rg-sa-p9 --name aks-sa-p9 --overwrite-existing
kubectl -n velero get backup-location,schedule
kubectl -n argocd get application p9-root-app
```

No se debe versionar `p9.tfplan`, archivos `.tfvars` con secretos ni ningún archivo de estado local.

## Verificación del respaldo

```powershell
kubectl -n velero get schedule p9-platform -o yaml
velero backup create p9-manual-$(Get-Date -Format yyyyMMddHHmm) --include-namespaces sa-p8 --include-cluster-resources=true --snapshot-volumes=false --default-volumes-to-fs-backup
velero backup get
velero backup describe <NOMBRE> --details
```

La restauración se ejecuta solo sobre un nombre nuevo y después de registrar el estado original. El procedimiento y las verificaciones están en [runbook-recuperacion.md](runbook-recuperacion.md).

## Evidencias

Las marcas de tiempo y salidas reales se guardan en [evidencias](evidencias/). Los valores de RTO/RPO no se deben completar con estimaciones: se calculan a partir de esos registros.