# Evidencia de rollback automático

## AnalysisRun fallido

- Nombre: `gateway-ffdcf76f4-2-1`
- Namespace: `sa-p8`
- Fase: `Error`
- Inicio: `2026-09-17T20:40:30Z`
- Fin: `2026-09-17T20:41:10Z`
- Resultado: cinco errores consecutivos al consultar `http://gateway-canary:3000/health`
- Umbral: `consecutiveErrorLimit: 4`

## Resultado posterior

El Rollout `gateway` quedó en fase `Healthy`, con 2 réplicas listas y 2 réplicas actualizadas. La revisión estable se mantuvo activa y la revisión defectuosa no llegó al 100% de tráfico.

Informe completo: [incidente-rollback.md](../documentacion/incidente-rollback.md)
