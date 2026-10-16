# Recorrido síntoma a causa - evidencia automática

Generada por `P10/scripts/prueba-sintoma-causa.ps1`. Fallo inducido: `FAULT_INJECTION=true` en
`auth-service` (distinto al fallo de la Práctica 8). Horas en UTC.

| Marca | Hora | Descripción |
|---|---|---|
| T0 - fallo activado | 2026-10-16T03:40:52Z | `FAULT_INJECTION=true` publicado en GitOps y sincronizado por ArgoCD |
| T1 - primera señal (alerta) | 2026-10-16T03:42:27Z | Alerta `TasaErrorAuthServiceElevada` en estado **firing** |
| T2 - causa confirmada | 2026-10-16T03:42:34Z | Traza con error localizada en Tempo (`trace_id=8684dc64a4c1dd00624876804f4cb113`) y su registro correspondiente abierto en Loki |
| T3 - sistema estable | 2026-10-16T03:45:05Z | `FAULT_INJECTION=false`, alerta resuelta |

## Tiempos medidos

| Indicador | Medido |
|---|---|
| **Tiempo de detección** (T1 - T0) | **95 s** |
| **Recorrido hasta la causa** (T2 - T0) | **102 s** (1.7 min) — objetivo de la rúbrica: menos de 3 minutos |
| Tiempo hasta la recuperación (T3 - T0) | 253 s |

## Registros encontrados para `trace_id=8684dc64a4c1dd00624876804f4cb113`

```
{"level":"error","time":"2026-10-16T03:41:27.310Z","service":"auth-service","trace_id":"8684dc64a4c1dd00624876804f4cb113","span_id":"118d522561a7e4d4","trace_flags":"01","email":"trafico-5a0b18cf@p10.test","msg":"fallo inducido (FAULT_INJECTION) en /auth/login"}
```

## Registro completo con marcas de tiempo

```

2026-10-16T03:40:23Z | sintoma-causa: trafico de base (20s, sin fallo)
2026-10-16T03:40:49Z | sintoma-causa: T0 - activando FAULT_INJECTION=true en auth-service
2026-10-16T03:40:52Z | sintoma-causa: T0 = 2026-10-16T03:40:52Z
2026-10-16T03:40:53Z | sintoma-causa: generando trafico continuo contra /auth/login mientras el fallo esta activo
2026-10-16T03:40:53Z | sintoma-causa: esperando la alerta TasaErrorAuthServiceElevada (firing)
2026-10-16T03:42:27Z | sintoma-causa: T1 (alerta firing) = 2026-10-16T03:42:27Z
2026-10-16T03:42:27Z | sintoma-causa: buscando una traza con error de auth-service en Tempo
2026-10-16T03:42:31Z | sintoma-causa: trace_id de error encontrado = 8684dc64a4c1dd00624876804f4cb113
2026-10-16T03:42:31Z | sintoma-causa: abriendo los registros de esa traza en Loki
2026-10-16T03:42:34Z | sintoma-causa: T2 (causa confirmada en Loki) = 2026-10-16T03:42:34Z (1 lineas de registro para esa traza)
2026-10-16T03:44:05Z | sintoma-causa: revirtiendo FAULT_INJECTION=false
2026-10-16T03:45:05Z | sintoma-causa: T3 (alerta resuelta, sistema estable) = 2026-10-16T03:45:05Z

```
