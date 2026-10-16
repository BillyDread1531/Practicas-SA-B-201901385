# Respaldos con Velero - evidencia (generada por scripts/evidencia-continuidad.ps1)

Estado real del cluster `aks-sa-p9` (reconstruido desde cero) consultado el 2026-10-16T08:42:54Z UTC.

## 1. Respaldos programados con retencion (schedule)

| Campo | Valor |
|---|---|
| Schedule | `velero-p9-platform` (namespace `velero`) |
| Calendario | `0 */6 * * *` (cada 6 horas, UTC) |
| **Retencion** | `ttl: 720h` (30 dias) |
| Alcance | namespaces `sa-p8`, `includeClusterResources: True` |
| **Volumenes persistentes incluidos** | `defaultVolumesToFsBackup: True` (Kopia por node-agent); `snapshotVolumes: False` |
| Estado | Enabled |
| Ultimo respaldo programado | `` |

## 2. Destino EXTERNO al cluster

| Campo | Valor |
|---|---|
| BackupStorageLocation | `default` - fase **Available** (ultima validacion 2026-10-16T08:42:07Z) |
| Proveedor / contenedor | `azure` / `velero` |
| Cuenta de almacenamiento | `stp9velero201901385` en el resource group `rg-sa-p9-backend` (eastus, Standard_LRS, acceso publico a blobs: False) |
| Ubicacion respecto al cluster | El cluster vive en `rg-sa-p9` (se destruye en el DR); el almacenamiento esta en `rg-sa-p9-backend` (capa persistente, otro resource group y otro estado de Terraform) |
| Repositorio Kopia en el Blob | 285 objetos bajo `kopia/` |

Respaldos visibles en el Blob (`backups/<nombre>/...-logs.gz`):

```
backups/manual-test-1792138570/manual-test-1792138570-logs.gz
backups/p9-datos-prueba-20261016084025/p9-datos-prueba-20261016084025-logs.gz
backups/p9-dr-20261016081735/p9-dr-20261016081735-logs.gz
```

## 3. Respaldos existentes

Incluye los creados **antes** de destruir el cluster: Velero los sincronizo desde el Blob al cluster nuevo.

| Respaldo | Fase | Inicio | Fin | Expira | Items |
|---|---|---|---|---|---|
| `manual-test-1792138570` | Completed | 2026-10-16T08:16:13Z | 2026-10-16T08:16:46Z | 2026-11-15T08:16:13Z | 732 |
| `p9-dr-20261016081735` | Completed | 2026-10-16T08:17:38Z | 2026-10-16T08:18:03Z | 2026-11-15T08:17:38Z | 731 |
| `p9-datos-prueba-20261016084025` | Completed | 2026-10-16T08:40:27Z | 2026-10-16T08:41:04Z | 2026-11-15T08:40:27Z | 751 |

## 4. Volumenes persistentes dentro del ultimo respaldo (`p9-datos-prueba-20261016084025`)

| Pod | Volumen | Fase | Tamano | Uploader |
|---|---|---|---|---|
| `sa-p8/rabbitmq-0` | `data` | Completed | 0.2 MiB | kopia |
| `sa-p8/postgresql-0` | `data` | Completed | 62.7 MiB | kopia |

## 5. La restauracion se demuestra funcionando

Ver [restauracion-datos.md](restauracion-datos.md) (restauracion en el mismo cluster, con verificacion de filas) y
[reconstruccion-cronometrada.md](reconstruccion-cronometrada.md) (restauracion en un cluster reconstruido desde cero).
