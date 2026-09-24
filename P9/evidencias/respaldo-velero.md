# Respaldos con Velero - evidencia (generada por scripts/evidencia-continuidad.ps1)

Estado real del cluster `aks-sa-p9` (reconstruido desde cero) consultado el 2026-09-24T09:30:28Z UTC.

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
| BackupStorageLocation | `default` - fase **Available** (ultima validacion 2026-09-24T09:29:37Z) |
| Proveedor / contenedor | `azure` / `velero` |
| Cuenta de almacenamiento | `stp9velero201901385` en el resource group `rg-sa-p9-backend` (eastus, Standard_LRS, acceso publico a blobs: False) |
| Ubicacion respecto al cluster | El cluster vive en `rg-sa-p9` (se destruye en el DR); el almacenamiento esta en `rg-sa-p9-backend` (capa persistente, otro resource group y otro estado de Terraform) |
| Repositorio Kopia en el Blob | 573 objetos bajo `kopia/` |

Respaldos visibles en el Blob (`backups/<nombre>/...-logs.gz`):

```
backups/p9-datos-prueba-20260924072558/p9-datos-prueba-20260924072558-logs.gz
backups/p9-datos-prueba-20260924072724/p9-datos-prueba-20260924072724-logs.gz
backups/p9-datos-prueba-20260924073115/p9-datos-prueba-20260924073115-logs.gz
backups/p9-datos-prueba-20260924092142/p9-datos-prueba-20260924092142-logs.gz
backups/p9-dr-20260924081100/p9-dr-20260924081100-logs.gz
backups/p9-dr-20260924083642/p9-dr-20260924083642-logs.gz
backups/p9-dr-20260924085848/p9-dr-20260924085848-logs.gz
```

## 3. Respaldos existentes

Incluye los creados **antes** de destruir el cluster: Velero los sincronizo desde el Blob al cluster nuevo.

| Respaldo | Fase | Inicio | Fin | Expira | Items |
|---|---|---|---|---|---|
| `p9-datos-prueba-20260924072558` | PartiallyFailed | 2026-09-24T07:26:00Z | 2026-09-24T07:26:07Z | 2026-10-24T07:25:59Z | 705 |
| `p9-datos-prueba-20260924072724` | Completed | 2026-09-24T07:27:26Z | 2026-09-24T07:27:54Z | 2026-10-24T07:27:26Z | 707 |
| `p9-datos-prueba-20260924073115` | Completed | 2026-09-24T07:31:16Z | 2026-09-24T07:32:01Z | 2026-10-24T07:31:16Z | 798 |
| `p9-dr-20260924081100` | Completed | 2026-09-24T08:11:01Z | 2026-09-24T08:12:13Z | 2026-10-24T08:11:01Z | 1215 |
| `p9-dr-20260924083642` | Completed | 2026-09-24T08:36:44Z | 2026-09-24T08:37:16Z | 2026-10-24T08:36:44Z | 798 |
| `p9-dr-20260924085848` | Completed | 2026-09-24T08:58:50Z | 2026-09-24T08:59:45Z | 2026-10-24T08:58:49Z | 727 |
| `p9-datos-prueba-20260924092142` | Completed | 2026-09-24T09:21:43Z | 2026-09-24T09:22:23Z | 2026-10-24T09:21:43Z | 758 |

## 4. Volumenes persistentes dentro del ultimo respaldo (`p9-datos-prueba-20260924092142`)

| Pod | Volumen | Fase | Tamano | Uploader |
|---|---|---|---|---|
| `sa-p8/postgresql-0` | `data` | Completed | 62.7 MiB | kopia |
| `sa-p8/rabbitmq-0` | `data` | Completed | 0.2 MiB | kopia |

## 5. La restauracion se demuestra funcionando

Ver [restauracion-datos.md](restauracion-datos.md) (restauracion en el mismo cluster, con verificacion de filas) y
[reconstruccion-cronometrada.md](reconstruccion-cronometrada.md) (restauracion en un cluster reconstruido desde cero).
