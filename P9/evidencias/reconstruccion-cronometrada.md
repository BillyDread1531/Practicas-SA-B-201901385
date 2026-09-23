# Reconstrucción cronometrada

Completar durante la prueba real. Usar ISO 8601 con zona horaria.

| Marca | Hora | Comando o evidencia |
|---|---|---|
| Destrucción iniciada | PENDIENTE | |
| Terraform apply iniciado | PENDIENTE | |
| AKS disponible | PENDIENTE | |
| ArgoCD disponible | PENDIENTE | |
| `p9-root-app` Healthy | PENDIENTE | |
| Servicio responde | PENDIENTE | |
| Datos verificados | PENDIENTE | |

**RTO real:** PENDIENTE, calcular desde destrucción iniciada hasta datos verificados.

## Hitos del bootstrap actual

- AKS `aks-sa-p9`: `Running` y `Succeeded` en Azure.
- `p9-root-app`: `Synced/Healthy`.
- `sa-platform-dev`: `Synced`; la salud global queda `Degraded` mientras terminan workloads secundarios.
- Namespace `sa-p8`: creado.
- PostgreSQL: `Running`, con PVC persistente `Bound`.
- Velero: servidor y dos node-agents `Running`; `BackupStorageLocation/default` `Available`.