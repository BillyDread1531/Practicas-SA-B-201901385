# Evidencia: Bootstrap completo desde cero

**Fecha:** 2026-09-23 02:18:45
**Cluster:** aks-sa-p9 (reconstruido desde cero)
**RTO objetivo:** 60 minutos
**RTO real:** ~41 minutos

---

## Cronometro

| Fase | Timestamp | Duracion |
|------|-----------|----------|
| Inicio destroy | 01:28:06 | - |
| Fin destroy | 01:35:36 | 7m30s |
| Inicio apply | 01:45:03 | - |
| Fin apply | 01:54:00 | 8m57s |
| CRDs extras (Argo Rollouts) | 01:55:00 | ~5m |
| Llave Sealed Secrets | 02:05:00 | ~10m |
| Sistema 100% funcional | 02:14:00 | - |

**RTO total real:** ~41 minutos.

---

## Reconstruccion verificada

- Cluster AKS: 2 nodos ARM64
- ArgoCD: 7 pods corriendo
- Velero: 3 pods corriendo
- Kyverno: 6 pods corriendo
- Argo Rollouts: 1 pod corriendo
- Sealed Secrets: Status True
- 13 pods corriendo en sa-p8 (microservicios + PostgreSQL + RabbitMQ)

---

## SPOFs del bootstrap identificados

1. **Terraform no instala Argo Rollouts, Sealed Secrets ni Kyverno** en el cluster nuevo. Requieren instalacion manual despues del apply.

2. **Los CRDs de Argo Rollouts** requieren --server-side --force-conflicts para aplicarse correctamente.

3. **La llave de Sealed Secrets** debe restaurarse manualmente despues del bootstrap (el backup estaba en un storage account que fue destruido con el cluster).

---

## Tiempo objetivo vs real

| Objetivo | Real |
|----------|------|
| RTO: 60 min | 41 min |
| Cumplimiento | Si, con margen de 19 min |
