# Runbook de recuperación

## 1. Prerrequisitos

1. Tener Azure CLI autenticado con permisos para el grupo `rg-sa-p9`, la cuenta de almacenamiento del backend y la suscripción objetivo.
2. Tener Terraform, kubectl, Helm y Velero instalados.
3. Definir el PAT únicamente en la sesión local:

```powershell
$env:TF_VAR_github_pat = Read-Host "PAT de GitHub"
```

## 2. Reconstruir infraestructura

```powershell
Set-Location .\P9\terraform
terraform init
terraform plan -out p9.tfplan
terraform apply p9.tfplan
az aks get-credentials --resource-group rg-sa-p9 --name aks-sa-p9 --overwrite-existing
```

Verificar que ArgoCD exista antes de continuar:

```powershell
kubectl -n argocd rollout status deployment/argocd-server --timeout=10m
kubectl -n argocd get application p9-root-app
kubectl -n argocd wait application/p9-root-app --for=jsonpath='{.status.health.status}'=Healthy --timeout=20m
```

## 3. Verificar secretos y workloads

```powershell
kubectl -n sa-p8 get sealedsecret,secret,pvc
kubectl -n sa-p8 rollout status statefulset/postgresql --timeout=10m
kubectl -n sa-p8 get pods
```

Si el `Secret` derivado de `sa-platform-secrets` no aparece, detener el procedimiento: el respaldo de la llave de Sealed Secrets debe restaurarse antes de levantar aplicaciones.

## 4. Verificar Velero

```powershell
kubectl -n velero get backup-location,schedule
velero backup get
velero schedule get
```

El `BackupStorageLocation` debe estar `Available` y el schedule `p9-platform` debe existir antes de declarar recuperación completa.

## 5. Restaurar datos

```powershell
velero restore create p9-restore-<fecha> --from-backup <backup-completado> --wait
velero restore describe p9-restore-<fecha> --details
kubectl -n sa-p8 get pvc,pod
```

Verificar contenido real de PostgreSQL, no solo la existencia del PVC:

```powershell
$pod = kubectl -n sa-p8 get pod -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}'
kubectl -n sa-p8 exec $pod -- psql -U sa_user -d academia -c 'SELECT count(*) FROM information_schema.tables;'
```

Registrar los datos de control antes de eliminar información y repetir la consulta después de la restauración en `P9/evidencias/restauracion-datos.md`.

## 6. Cierre

Registrar hora de inicio, hora de primer servicio saludable, hora de datos verificados y cualquier intervención manual. El RTO termina cuando el servicio responde y los datos críticos fueron verificados; el RPO es la antigüedad del último dato confirmado que sobrevivió.