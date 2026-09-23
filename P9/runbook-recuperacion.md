# Runbook de Recuperación ante Desastres

**Práctica:** 9 — Continuidad operativa y recuperación ante desastres
**Cluster:** aks-sa-p9 (resource group: rg-sa-p9)
**Namespace de aplicación:** sa-p8
**Repositorio GitOps:** https://github.com/BillyDread1531/Practica-SA-P8-GitOps.git (rama p9)
**Repositorio de código:** https://github.com/BillyDread1531/Practicas-SA-B-201901385.git (rama main)

---

## Propósito

Este documento describe el procedimiento completo para reconstruir el ecosistema de microservicios desde cero ante la pérdida total del clúster o de los datos. Está diseñado para ser ejecutado por una persona que no conoce el sistema, sin acceso al autor original.

**Objetivos declarados:**
- **RTO (Recovery Time Objective):** 60 minutos
- **RPO (Recovery Point Objective):** 6 horas (intervalo del schedule de Velero)

---

## Prerrequisitos

Antes de comenzar, verificar que se cuenta con:

1. **Acceso a Azure CLI:** az login autenticado con permisos de Contributor.
2. **Acceso al clúster:** kubectl configurado con el contexto aks-sa-p9.
3. **Terraform instalado:** versión mayor o igual a 1.16.0.
4. **Helm instalado:** versión mayor o igual a 3.14.
5. **Acceso al repositorio de código:** clonado localmente.
6. **Token de GitHub:** con permisos de lectura.

---

## Estructura del sistema

| Recurso | Tipo | Resource Group | Región |
|---------|------|----------------|--------|
| rg-sa-p9 | Resource Group principal | — | eastus |
| aks-sa-p9 | Cluster AKS | rg-sa-p9 | eastus |
| rg-sa-p9-backend | Resource Group del backend Terraform | — | eastus |
| sttfstatesa201901385 | Storage Account del tfstate | rg-sa-p9-backend | eastus |
| stvelerosa201901385 | Storage Account de Velero | rg-sa-p9 | eastus |
| acrsa201901385 | Azure Container Registry | rg-sa-p6 | centralus |

---

## Escenario 1: Reconstrucción completa desde cero

**Cuándo usar:** Cuando se pierde el clúster completo.
**Tiempo estimado:** 60 minutos.

### Paso 1: Verificar el estado de Azure

az login
az account show
az group list --query "[].name" -o table

**Verificación:** Debe mostrar los resource groups rg-sa-p9, rg-sa-p9-backend y rg-sa-p6.


### Paso 2: Verificar el backend remoto de Terraform

az storage blob list `
    --account-name sttfstatesa201901385 `
    --container-name tfstate `
    --auth-mode login `
    --query "[].name" -o table

**Verificación:** Debe aparecer p9-platform.tfstate.

### Paso 3: Reconstruir la infraestructura con Terraform

Este es el punto de entrada único del bootstrap.

cd "C:\Users\billy\OneDrive\Escritorio\SOTFWARE AVANZADO\PRACTICA 1\P9\terraform"
terraform state list
terraform plan
terraform apply -auto-approve

**Qué hace:**

1. Crea el resource group rg-sa-p9.
2. Crea el cluster AKS aks-sa-p9 con 2 nodos ARM64.
3. Configura el rol AcrPull.
4. Instala ArgoCD vía Helm.
5. Instala Velero vía Helm con Azure Blob.
6. Crea el Storage Account de Velero.
7. Aplica la app-of-apps p9-root-app.
8. Crea las credenciales de los repositorios.

**Tiempo esperado:** 15-20 minutos.


**Verificación después del bootstrap:**

az aks get-credentials --resource-group rg-sa-p9 --name aks-sa-p9 --overwrite-existing
kubectl get nodes
kubectl get pods -n argocd
kubectl get pods -n velero

**Esperado:** 2 nodos Ready, 6 pods de ArgoCD, 3 pods de Velero.

### Paso 4: Esperar la sincronización de ArgoCD

kubectl get applications -n argocd
kubectl wait --for=condition=Synced application/sa-platform-dev -n argocd --timeout=600s

**Esperado:** p9-root-app, sa-platform-dev, kyverno, p8-kyverno-policies como Synced.


**Verificación después del bootstrap:**

az aks get-credentials --resource-group rg-sa-p9 --name aks-sa-p9 --overwrite-existing
kubectl get nodes
kubectl get pods -n argocd
kubectl get pods -n velero

**Esperado:** 2 nodos Ready, 6 pods de ArgoCD, 3 pods de Velero.

### Paso 4: Esperar la sincronización de ArgoCD

kubectl get applications -n argocd
kubectl wait --for=condition=Synced application/sa-platform-dev -n argocd --timeout=600s

**Esperado:** p9-root-app, sa-platform-dev, kyverno, p8-kyverno-policies como Synced.


### Paso 5: Verificar los microservicios

kubectl get pods -n sa-p8
kubectl get svc -n sa-p8
kubectl exec -n sa-p8 (kubectl get pods -n sa-p8 -l app.kubernetes.io/name=gateway -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://gateway:3000/health

**Esperado:** El gateway responde con status ok.

### Paso 6: Restaurar los secretos (si es necesario)

Si el SealedSecret no se descifra, hay que restaurar la llave de sellado.

az storage blob download `
    --account-name sttfstatesa201901385 `
    --container-name sealed-secrets-backup `
    --name sealed-secrets-key6v5m9.yaml `
    --file ./sealed-secrets-key.yaml `
    --auth-mode login

kubectl apply -f ./sealed-secrets-key.yaml
kubectl rollout restart deployment sealed-secrets-controller -n kube-system
kubectl get sealedsecret sa-platform-secrets -n sa-p8


---

## Escenario 2: Restauración de datos desde Velero

**Cuándo usar:** Cuando se pierden los datos de PostgreSQL o RabbitMQ pero el clúster sigue funcionando.

### Paso 1: Listar backups disponibles

kubectl get backups -n velero

### Paso 2: Crear un restore a un namespace separado

apiVersion: velero.io/v1
kind: Restore
metadata:
  name: restore-dr
  namespace: velero
spec:
  backupName: nombre-del-backup
  includedNamespaces:
    - sa-p8
  namespaceMapping:
    sa-p8: sa-p8-restore
  includedResources:
    - persistentvolumeclaims
    - persistentvolumes
  restorePVs: true

### Paso 3: Verificar la restauración

kubectl get restore restore-dr -n velero
kubectl get pvc -n sa-p8-restore

**Limitación conocida:** El restore de Velero recupera la definición del PVC pero no inyecta los datos de Kopia automáticamente. Para restaurar los datos reales es necesario crear un PodVolumeRestore manualmente o usar la CLI de Velero con el flag --restore-volumes.


---

## Escenario 3: Restauración de un nodo

**Cuándo usar:** Cuando un nodo falla o necesita mantenimiento.

### Paso 1: Drenar el nodo

kubectl get nodes
kubectl drain nombre-nodo --ignore-daemonsets --delete-emptydir-data --force

**Verificar que el servicio sigue respondiendo:**

kubectl exec -n sa-p8 (kubectl get pods -n sa-p8 -l app.kubernetes.io/name=gateway -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://gateway:3000/health

**Uncordon:**

kubectl uncordon nombre-nodo

**Verificación:** Los pods evictados deben recrearse automáticamente. El gateway debe seguir respondiendo durante todo el drenaje.

---

## Escenario 4: Recuperación de secretos

**Cuándo usar:** Cuando los SealedSecrets no se descifran.

### Paso 1: Verificar el estado

kubectl get sealedsecret sa-platform-secrets -n sa-p8 -o jsonpath="{.status.conditions[0].message}"

Si el mensaje contiene "no key could decrypt secret", la llave es incorrecta.

### Paso 2: Restaurar la llave

az storage blob download `
    --account-name sttfstatesa201901385 `
    --container-name sealed-secrets-backup `
    --name sealed-secrets-key6v5m9.yaml `
    --file ./sealed-secrets-key.yaml `
    --auth-mode login

kubectl apply -f ./sealed-secrets-key.yaml
kubectl rollout restart deployment sealed-secrets-controller -n kube-system

### Paso 3: Re-cifrar si es necesario

kubeseal --fetch-cert --controller-namespace kube-system --controller-name sealed-secrets-controller > cert.pem
kubeseal --cert cert.pem --format yaml > sealed-secret.yaml


---

## Contactos y referencias

**Documentación:**
- Velero: https://velero.io/docs/
- ArgoCD app-of-apps: https://argo-cd.readthedocs.io/
- Sealed Secrets: https://github.com/bitnami-labs/sealed-secrets

**Repositorios:**
- Código: https://github.com/BillyDread1531/Practicas-SA-B-201901385.git
- GitOps: https://github.com/BillyDread1531/Practica-SA-P8-GitOps.git

**SPOFs detectados:** ver P9/docs/spofs-detectados.md

---

## Objetivos declarados

**RTO (Recovery Time Objective):** 60 minutos
**RPO (Recovery Point Objective):** 6 horas (intervalo del schedule de Velero)

Documento generado durante la practica de continuidad operativa.

