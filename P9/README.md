# Práctica 9: Continuidad operativa y recuperación ante desastres

Reconstruye desde cero el ecosistema de microservicios en AKS con **un solo comando**, recupera los datos desde respaldos
almacenados fuera del clúster y conserva el flujo de la Práctica 8 (GitOps, entrega progresiva, políticas de admisión).

Repositorio de código: https://github.com/BillyDread1531/Practicas-SA-B-201901385 (carpeta `P9`, rama `main`).

## Tabla de enlaces obligatoria

| Ítem | Enlace o dato requerido |
|---|---|
| **Repositorio GitOps** | https://github.com/BillyDread1531/Practica-SA-P8-GitOps (público; rama `p9`, carpeta [`apps/`](https://github.com/BillyDread1531/Practica-SA-P8-GitOps/tree/p9/apps)) |
| **Aplicación raíz en ArgoCD** | `p9-root-app`, namespace `argocd` (app-of-apps sobre `apps/`) |
| **Punto de entrada del bootstrap** | [`P9/scripts/bootstrap.ps1`](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/P9/scripts/bootstrap.ps1) — `.\P9\scripts\bootstrap.ps1` |
| **Backend remoto de Terraform** | Tipo `azurerm` (Azure Blob Storage con bloqueo por lease): cuenta `sttfstatesa201901385`, contenedor `tfstate`, clave `p9-platform.tfstate` (resource group `rg-sa-p9-backend`). Sin credenciales: autenticación Azure AD |
| **Schedule de Velero** | `velero-p9-platform` (namespace `velero`, `0 */6 * * *`, retención 720 h, incluye volúmenes con Kopia). Destino: Azure Blob `stp9velero201901385` / contenedor `velero` (fuera del clúster). Ver [respaldo-velero.md](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/P9/evidencias/respaldo-velero.md) |
| **Reconstrucción cronometrada** | [`P9/evidencias/reconstruccion-cronometrada.md`](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/P9/evidencias/reconstruccion-cronometrada.md) |
| **Restauración de datos** | [`P9/evidencias/restauracion-datos.md`](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/P9/evidencias/restauracion-datos.md) |
| **Prueba de pérdida de nodo** | [`P9/evidencias/perdida-nodo.md`](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/P9/evidencias/perdida-nodo.md) |
| **RTO y RPO declarados** | **Declarados:** RTO 60 min · RPO 6 h. **Medidos:** RTO **14 min 44 s**; RPO 1 min 03 s en la prueba (peor caso del diseño ≈ 6 h). Ver [`informe-dr.md`](https://github.com/BillyDread1531/Practicas-SA-B-201901385/blob/main/P9/informe-dr.md) |

## Documentos entregables

| Entregable | Archivo |
|---|---|
| Informe de la prueba de DR (6 campos) | [informe-dr.md](informe-dr.md) |
| Runbook de recuperación | [runbook-recuperacion.md](runbook-recuperacion.md) |
| Diagrama del bootstrap | [docs/diagrama-bootstrap.md](docs/diagrama-bootstrap.md) (Mermaid; fuente PlantUML en [.puml](docs/diagrama-bootstrap.puml)) |
| Puntos únicos de fallo | [docs/spofs-detectados.md](docs/spofs-detectados.md) |
| Preguntas teóricas | [docs/preguntas-teoricas.md](docs/preguntas-teoricas.md) |
| Continuidad de secretos | [evidencias/continuidad-secretos.md](evidencias/continuidad-secretos.md) |
| Configuración de respaldos | [terraform/velero.tf](terraform/velero.tf) y [evidencias/respaldo-velero.md](evidencias/respaldo-velero.md) |
| Manifiestos GitOps (app-of-apps, resiliencia) | repositorio GitOps rama `p9` |

## Cómo está resuelto cada requisito

| Requisito | Solución | Dónde |
|---|---|---|
| Bootstrap de día cero | Un comando: Terraform crea AKS, ArgoCD, llaves de Sealed Secrets, Velero y la app raíz; ArgoCD levanta el resto por olas; el script restaura datos y verifica. Sin pasos manuales | `scripts/bootstrap.ps1`, `terraform/`, GitOps `apps/` |
| Estado remoto con bloqueo | Backend `azurerm`; sin `.tfstate` ni credenciales en el repo; el lock de proveedores sí se versiona | `terraform/versions.tf` |
| Respaldos programados con Velero | Schedule cada 6 h, retención 30 d, volúmenes vía node-agent/Kopia, destino Blob en la **capa persistente** (sobrevive al `destroy`) | `terraform/velero.tf`, `terraform-persistent/` |
| Servicio con estado | PostgreSQL y RabbitMQ con PVC; verificación con filas de control | `evidencias/restauracion-datos.md` |
| Continuidad de secretos | Sealed Secrets con la llave respaldada en Azure Key Vault y restaurada por Terraform antes del controlador | `terraform/sealed-secrets-key.tf`, `scripts/backup-sealed-key.ps1` |
| Resiliencia ante pérdida de nodo | PDB, anti-afinidad, 2 réplicas, probes; requests ajustados para que un nodo aloje todo | charts + GitOps `environments/dev/values.yaml` |
| Prueba de recuperación cronometrada | `terraform destroy` + `bootstrap.ps1` con marcas de tiempo | `scripts/prueba-reconstruccion.ps1` |
| Prueba de restauración de datos | Borrado + restore desde Blob + verificación fila por fila | `scripts/prueba-restauracion-datos.ps1` |
| RTO/RPO declarados y contrastados | Ver informe | `informe-dr.md` |
| Runbook para un tercero | Comandos exactos, verificaciones y solución de problemas | `runbook-recuperacion.md` |
| Flujo de la P8 tras reconstruir | `verificar.ps1` comprueba GitOps, Rollout canary y que Kyverno bloquea `:latest` | `scripts/verificar.ps1` |

## Estructura

```
P9/
├── scripts/                 bootstrap.ps1 (entrada única), restore-datos.ps1, verificar.ps1,
│                            backup-sealed-key.ps1, prueba-*.ps1 (pruebas con evidencia automática)
├── terraform/               stack del clúster: AKS, ArgoCD, Velero, llaves, app raíz (estado remoto)
├── terraform-persistent/    capa persistente: Blob de respaldos + Key Vault (no se destruye en el DR)
├── docs/                    diagrama, SPOFs, preguntas teóricas
├── evidencias/              registros con marcas de tiempo generados por los scripts
├── informe-dr.md
└── runbook-recuperacion.md
```

## Uso rápido

```powershell
az login
.\P9\scripts\bootstrap.ps1                    # reconstruye todo (y restaura datos si hay respaldos)
.\P9\scripts\restore-datos.ps1                # solo restaurar datos desde el ultimo respaldo
.\P9\scripts\prueba-reconstruccion.ps1        # destruye y reconstruye midiendo RTO/RPO (DESTRUCTIVO)
```

Preparación inicial y prerrequisitos: [runbook-recuperacion.md](runbook-recuperacion.md) §1 y §7.
