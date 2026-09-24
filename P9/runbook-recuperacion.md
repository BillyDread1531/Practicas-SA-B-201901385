# Runbook de recuperación ante desastres — Práctica 9

**Para quién:** una persona que **no conoce el sistema** y no tiene acceso a quien lo construyó. Todo lo necesario está en
este documento y en el repositorio. Cada paso trae el comando exacto, lo que debe ver y qué hacer si no lo ve.

**Objetivos declarados:** RTO **60 min** · RPO **6 h** (respaldos cada 6 h).
**Tiempo medido de la reconstrucción completa:** ver [evidencias/reconstruccion-cronometrada.md](evidencias/reconstruccion-cronometrada.md).

## 0. ¿Qué escenario tengo?

| Síntoma | Escenario | Ir a |
|---|---|---|
| `kubectl` no conecta, el clúster `aks-sa-p9` ya no existe o está irrecuperable | **A. Pérdida total del clúster** | §3 |
| El clúster funciona pero faltan/están corruptos los datos de PostgreSQL o RabbitMQ | **B. Pérdida de datos** | §4 |
| Un nodo está `NotReady` o hay que darlo de baja | **C. Pérdida de un nodo** | §5 |
| Pods de la aplicación en `CreateContainerConfigError` / el `SealedSecret` no se descifra | **D. Secretos ilegibles** | §6 |
| Nunca se ha instalado nada (entorno vacío) | **Preparación inicial** | §7 |

## 1. Prerrequisitos (verificar ANTES de empezar)

Herramientas instaladas en la máquina del operador (PowerShell 5.1 o `pwsh` 7):

| Herramienta | Versión probada | Comprobación |
|---|---|---|
| Azure CLI | 2.6x o superior | `az version` |
| Terraform | ≥ 1.6 (probado 1.16) | `terraform version` |
| kubectl | ≥ 1.30 | `kubectl version --client` |
| Git | cualquiera | `git --version` |

Cuenta de Azure con estos permisos sobre la suscripción (rol **Owner** los cubre; con menos se necesitan los tres):

- **Contributor** (crear AKS, resource group, Storage).
- **User Access Administrator** (Terraform crea el rol `AcrPull` para el clúster sobre el ACR `acrsa201901385`).
- **Key Vault Secrets User** sobre `kv-p9-201901385` y **Storage Blob Data Contributor** sobre `sttfstatesa201901385`
  (leer las llaves de Sealed Secrets y el estado remoto de Terraform).

```powershell
az login
az account show --query "{usuario:user.name, suscripcion:name}" -o table
git clone https://github.com/BillyDread1531/Practicas-SA-B-201901385.git
cd Practicas-SA-B-201901385\P9
```

**Verifique que la capa persistente sobrevive** (si esto falla, vaya a §8 «Límites»):

```powershell
az group exists --name rg-sa-p9-backend                       # debe imprimir: true
az keyvault secret show --vault-name kv-p9-201901385 --name sealed-secrets-keys --query "length(value)" -o tsv   # un numero > 2
az storage blob list --account-name sttfstatesa201901385 --container-name tfstate --auth-mode login --query "[].name" -o tsv   # debe listar p9-platform.tfstate
$k = az storage account keys list --account-name stp9velero201901385 -g rg-sa-p9-backend --query "[0].value" -o tsv
az storage blob list --account-name stp9velero201901385 --account-key $k --container-name velero --prefix backups/ --query "length(@)" -o tsv   # > 0 (hay respaldos)
```

## 2. Datos fijos del sistema

| Recurso | Valor |
|---|---|
| Suscripción / región | la de `az login` · `eastus` |
| Clúster / resource group | `aks-sa-p9` / `rg-sa-p9` (se destruye y se recrea) |
| **Capa persistente** (no se destruye) | resource group `rg-sa-p9-backend`: Storage `sttfstatesa201901385` (estado Terraform), Storage `stp9velero201901385` (respaldos), Key Vault `kv-p9-201901385` (llaves) |
| Estado remoto de Terraform | backend `azurerm`, contenedor `tfstate`, clave `p9-platform.tfstate` (bloqueo por lease del Blob) |
| Namespace de la aplicación | `sa-p8` |
| App raíz de ArgoCD | `p9-root-app`, namespace `argocd` |
| Repositorio GitOps (público) | https://github.com/BillyDread1531/Practica-SA-P8-GitOps.git, rama `p9` |
| Schedule de Velero | `velero-p9-platform` (`0 */6 * * *`, retención 720 h), namespace `velero` |

---

## 3. Escenario A — Pérdida total del clúster

**Un solo comando** reconstruye todo (no hay pasos manuales intermedios):

```powershell
cd P9
.\scripts\bootstrap.ps1 -LogFile .\evidencias\mi-recuperacion.log
```

Qué hace, en este orden (cada paso imprime una marca de tiempo `| bootstrap: ...`):

| # | Paso automático | Marca que debe ver | Si no aparece |
|---|---|---|---|
| 1 | `terraform init` + `apply` (estado remoto): AKS → ArgoCD → llaves de Sealed Secrets (desde Key Vault) → Velero → `p9-root-app` | `terraform apply COMPLETO` | ver §9 (fila «terraform») |
| 2 | Espera nodos y ArgoCD | `AKS disponible`, `ArgoCD disponible` | ver §9 |
| 3 | ArgoCD sincroniza por olas: `sealed-secrets`, `argo-rollouts`, `kyverno` → `p8-kyverno-policies` → `sa-platform-dev` | `app <nombre> Synced` (5 veces) y `p9-root-app Healthy` | ver §9 (fila «app no sincroniza») |
| 4 | El controlador descifra el SealedSecret con la llave restaurada | `SealedSecret sa-platform-secrets DESCIFRADO` | ir a §6 |
| 5 | PostgreSQL y RabbitMQ arrancan con volúmenes nuevos (vacíos) | `PostgreSQL y RabbitMQ Ready` | ver §9 |
| 6 | Restauración de datos desde el último respaldo (`restore-datos.ps1`) | `PodVolumeRestore completados = N/N` y `datos restaurados desde Velero` | ir a §4 |
| 7 | Verificación (`verificar.ps1`) | `RESULTADO = todos los controles PASS` | leer el control `FAIL` y ver §9 |

**Verificación manual final (2 minutos):**

```powershell
kubectl get nodes                                   # 2 nodos Ready
kubectl get applications -n argocd                  # p9-root-app y las 5 hijas: Synced
kubectl get pods -n sa-p8                           # todo Running (los cron-* aparecen Completed)
kubectl -n sa-p8 get sealedsecret sa-platform-secrets -o jsonpath='{.status.conditions[0].type}={.status.conditions[0].status}'   # Synced=True
$ip = kubectl -n sa-p8 get svc gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
curl.exe -s "http://${ip}:3000/health"              # {"status":"ok","service":"gateway"}
```

Comprobar los datos (no solo que el pod arranque): la base debe tener las filas que tenía en el último respaldo.

```powershell
# (la clave se lee dentro del pod; no se imprime)
"select count(*) from estudiantes; select count(*) from usuarios;" | kubectl -n sa-p8 exec -i postgresql-0 -c postgresql -- bash -c 'export PGPASSWORD=$(cat /opt/bitnami/postgresql/secrets/postgres-password); psql -U postgres -d academia -At'
```

**Si `bootstrap.ps1` se interrumpe** (cierre de sesión, corte de red): vuelva a ejecutarlo. Es idempotente:
Terraform continúa desde el estado remoto y `restore-datos.ps1` vuelve a restaurar el último respaldo.
Si Terraform quedó con el bloqueo tomado: `terraform -chdir=terraform force-unlock <ID que muestra el error>`.

**Primera instalación** (Key Vault vacío): `bootstrap.ps1` lo detecta, no hay respaldos que restaurar y guarda solo la
llave del controlador en el Key Vault al terminar.

---

## 4. Escenario B — Pérdida de datos con el clúster funcionando

```powershell
cd P9
kubectl -n velero get backup -l velero.io/schedule-name=velero-p9-platform    # elegir uno en fase Completed
.\scripts\restore-datos.ps1                         # usa el ultimo respaldo Completed del schedule
# o uno concreto:
.\scripts\restore-datos.ps1 -BackupName velero-p9-platform-20260924060026
```

El script hace, sin intervención: (1) pausa GitOps (`p9-root-app` y `sa-platform-dev`, si no ArgoCD recrearía volúmenes
vacíos), (2) borra el StatefulSet y el PVC de PostgreSQL y RabbitMQ, (3) crea un `Restore` de Velero limitado a
`statefulsets, pods, persistentvolumeclaims, persistentvolumes` con esos dos selectores, (4) espera los
`PodVolumeRestore` y que `postgresql-0`/`rabbitmq-0` queden `Ready`, (5) reactiva GitOps.

**Debe ver:** `Restore ... -> Completed`, `PodVolumeRestore completados = 5/5`, `postgresql-0 Ready con el volumen restaurado`.
Luego verifique el contenido con el `select` del §3. Datos insertados después del respaldo elegido **no** se recuperan
(ese es el RPO).

**Importante — no restaure solo los PVC.** Velero repone los datos con un initContainer (`restore-wait`) que inyecta en
el *pod* restaurado. Sin pod restaurado no hay `PodVolumeRestore` y el volumen queda vacío. Además la política Kyverno
`p8-require-non-root` debe eximir a ese initContainer (ya está en el repositorio; si alguien la revierte, el pod se rechaza).

Comandos manuales equivalentes (si el script no pudiera usarse):

```powershell
kubectl -n argocd patch application p9-root-app --type merge -p '{"spec":{"syncPolicy":{"automated":null}}}'
kubectl -n argocd patch application sa-platform-dev --type merge -p '{"spec":{"syncPolicy":{"automated":null}}}'
kubectl -n sa-p8 delete statefulset postgresql rabbitmq
kubectl -n sa-p8 delete pvc data-postgresql-0 data-rabbitmq-0
velero restore create restore-manual --from-backup <BACKUP> --include-namespaces sa-p8 `
  --include-resources statefulsets,pods,persistentvolumeclaims,persistentvolumes `
  --or-selector app.kubernetes.io/name=postgresql --or-selector app.kubernetes.io/name=rabbitmq --wait
kubectl -n velero get podvolumerestore                     # todos Completed
kubectl -n argocd patch application p9-root-app --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

(en PowerShell 5.1 las comillas dobles internas de `-p` se pierden: use `scripts/restore-datos.ps1`, que aplica los parches por archivo).

---

## 5. Escenario C — Pérdida de un nodo

No requiere reconstrucción: los Deployments, el Rollout y los PDB reprograman los pods en el nodo restante.

```powershell
kubectl get nodes -o wide
kubectl drain <NODO> --ignore-daemonsets --delete-emptydir-data --timeout=300s     # si hay que darlo de baja
kubectl -n sa-p8 get pods -o wide                        # los pods deben quedar Running en el nodo restante
kubectl uncordon <NODO>                                  # cuando el nodo vuelva
```

**Qué esperar (medido):** los 5 microservicios siguen respondiendo sin errores. **PostgreSQL tiene una sola réplica**: si el
nodo drenado es el que lo aloja, las rutas que usan base de datos devuelven 5xx unos ~60 s hasta que el pod se reprograma
y el disco se re-adjunta (ver [evidencias/perdida-nodo.md](evidencias/perdida-nodo.md), escenario B). No es una falla a
reparar: es el comportamiento conocido, documentado como brecha en el informe.

Prueba reproducible con evidencia: `.\scripts\prueba-perdida-nodo.ps1 -Scenario stateless` (o `stateful`).

---

## 6. Escenario D — Secretos ilegibles (Sealed Secrets)

Síntoma:

```powershell
kubectl -n sa-p8 get sealedsecret sa-platform-secrets -o jsonpath='{.status.conditions[0].message}'
# "no key could decrypt secret" -> el controlador no tiene la llave con la que se cifro el SealedSecret
```

Causa: el controlador arrancó **antes** de que existiera la llave restaurada y generó una nueva. Solución (restaurar las
llaves del Key Vault y reiniciar el controlador):

```powershell
$json = az keyvault secret show --vault-name kv-p9-201901385 --name sealed-secrets-keys --query value -o tsv | ConvertFrom-Json
foreach ($k in $json) {
@"
apiVersion: v1
kind: Secret
type: kubernetes.io/tls
metadata:
  name: $($k.name)
  namespace: kube-system
  labels:
    sealedsecrets.bitnami.com/sealed-secrets-key: active
data:
  tls.crt: $($k.crt)
  tls.key: $($k.key)
"@ | kubectl apply -f -
}
kubectl -n kube-system rollout restart deployment sealed-secrets-controller
kubectl -n kube-system rollout status deployment sealed-secrets-controller
kubectl -n sa-p8 get sealedsecret sa-platform-secrets -o jsonpath='{.status.conditions[0].status}'   # True
```

(No imprima la variable `$json`: contiene llaves privadas.)

**Si la llave se perdió también del Key Vault** los `SealedSecret` del repositorio son irrecuperables. Hay que crear los
secretos de nuevo y volver a sellarlos con el certificado del controlador nuevo:

```powershell
kubeseal --controller-name sealed-secrets-controller --controller-namespace kube-system --fetch-cert > cert.pem
# crear el Secret en claro (sin subirlo a Git), sellarlo y reemplazar P8/charts/sa-platform/templates/sealed-secret.yaml
kubeseal --cert cert.pem --format yaml < secret-en-claro.yaml > sealed-secret.yaml
.\scripts\backup-sealed-key.ps1          # respaldar la llave nueva
```

Como el controlador se despliega con `keyrenewperiod: "0"` (sin rotación automática), la copia del Key Vault no caduca.
Si alguien rota la llave a mano, ejecute `.\scripts\backup-sealed-key.ps1` inmediatamente después.

---

## 7. Preparación inicial (se hace UNA vez, antes de cualquier desastre)

```powershell
# 7.1 Backend de Terraform (estado remoto con bloqueo) — solo si no existe
az group create -n rg-sa-p9-backend -l eastus
az storage account create -n sttfstatesa201901385 -g rg-sa-p9-backend -l eastus --sku Standard_LRS --min-tls-version TLS1_2 --allow-blob-public-access false
az storage container create --account-name sttfstatesa201901385 -n tfstate --auth-mode login

# 7.2 Capa persistente: Blob de respaldos + Key Vault
terraform -chdir=terraform-persistent init
terraform -chdir=terraform-persistent apply

# 7.3 Primera instalación completa (crea también el schedule de respaldos)
.\scripts\bootstrap.ps1 -SkipRestore
# bootstrap.ps1 guarda la llave de Sealed Secrets en el Key Vault al terminar (primera instalación)
```

## 8. Límites — lo que este runbook NO puede recuperar

| Pérdida | Consecuencia | Mitigación pendiente |
|---|---|---|
| Se pierde la **capa persistente** (`rg-sa-p9-backend`): Blob de respaldos y/o Key Vault | Sin respaldos no hay datos; sin llaves los SealedSecret son ilegibles | Replicación geográfica (GRS) del Blob y copia de las llaves fuera de Azure |
| Se borra el repositorio GitHub (GitOps o código) | ArgoCD no tiene qué desplegar | Espejo del repositorio |
| Datos posteriores al último respaldo (hasta 6 h) | Se pierden | Reducir el intervalo del schedule o WAL archiving en PostgreSQL |
| Caída de la región `eastus` | Todo lo anterior está en una sola región | Despliegue multi-región (fuera del alcance) |
| Un nodo cae con PostgreSQL en él | ~60 s sin base de datos | PostgreSQL con réplica (fuera del alcance de la cuota de 4 vCPU) |

## 9. Solución de problemas (todos vistos durante las pruebas reales)

| Síntoma | Causa | Solución |
|---|---|---|
| terraform: `Error acquiring the state lock` | Una ejecución anterior murió con el bloqueo tomado | `terraform -chdir=terraform force-unlock <ID>` |
| terraform: `does not have secrets get permission on key vault` | Falta el rol en el Key Vault (propagación tarda ~5 min) | Asignar `Key Vault Secrets User` y reintentar |
| terraform: `Insufficient quota` / vCPU | La suscripción permite 4 vCPU en `eastus` = 2 nodos `Standard_D2s_v7` | No subir `node_count` sobre 2; pedir cuota en el portal |
| `restore-datos`: `PodVolumeRestore completados = 0/0` | Se restauraron solo PVC, o Kyverno rechazó el pod restaurado | Ver el error con `kubectl -n velero describe restore <R>`; comprobar la excepción `restore-wait` en `p8-require-non-root` |
| Backup `PartiallyFailed`: `repository not initialized in the provided storage` | Quedó un `BackupRepository` apuntando a un almacenamiento distinto | `kubectl -n velero delete backuprepositories --all` y repetir el respaldo |
| Pods `Pending` con `Insufficient cpu` | Requests demasiado altos para un solo nodo | Los requests ya están ajustados en `environments/dev/values.yaml`; no subirlos |
| Aplicación de ArgoCD `OutOfSync` en CRD | El API server normaliza campos de los CRD | `ignoreDifferences` ya configurado en `apps/*.yaml` |
| `verificar.ps1` marca FAIL en «Kyverno bloquea :latest» | Las políticas aún no estaban listas | Esperar 1 min y ejecutar `.\scripts\verificar.ps1` otra vez |

## 10. Referencias

- Diagrama del orden de reconstrucción: [docs/diagrama-bootstrap.md](docs/diagrama-bootstrap.md)
- Informe de la prueba: [informe-dr.md](informe-dr.md) · Puntos únicos de fallo: [docs/spofs-detectados.md](docs/spofs-detectados.md)
- Velero: https://velero.io/docs/ · ArgoCD app-of-apps: https://argo-cd.readthedocs.io/ · Sealed Secrets: https://github.com/bitnami/sealed-secrets
