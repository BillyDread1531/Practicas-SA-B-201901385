# Restauracion de datos - evidencia automatica

Generada por `P9/scripts/prueba-restauracion-datos.ps1` (cluster `aks-sa-p9`, namespace `sa-p8`).
Todas las horas son UTC. El script termina con error si el contenido restaurado no coincide.

| Campo | Valor |
|---|---|
| Backup usado | `p9-datos-prueba-20260924073115` (template del schedule `velero-p9-platform`) |
| Destino del respaldo | Azure Blob `stp9velero201901385/velero` (fuera del cluster) |
| Inicio / fin del respaldo | 2026-09-24T07:31:16Z / 2026-09-24T07:32:01Z |
| Volumenes respaldados (Kopia) | rabbitmq-0/data = Completed; postgresql-0/data = Completed |
| Dato de control creado | 5 estudiantes `DR-0001`..`DR-0005` (antes del respaldo) |
| Dato posterior al respaldo | `DR-POST` insertado a las 2026-09-24T07:32:09Z |
| Hora de eliminacion (desastre) | 2026-09-24T07:32:11Z (`DELETE FROM estudiantes` -> count = 0) |
| Restore ejecutado | 2026-09-24T07:32:12Z -> 2026-09-24T07:34:01Z (109 s) |
| Contenido verificado | SI: las 5 filas (carnet + email) coinciden exactamente |
| Dato posterior al respaldo | NO recuperado (esperado, es el RPO) |
| **RPO real** | **55 s** entre el inicio del respaldo y el desastre; se perdio 1 registro (`DR-POST`) |

## Contenido antes del desastre (tabla estudiantes, filas de control)

```
DR-0001 dr1@p9.test
DR-0002 dr2@p9.test
DR-0003 dr3@p9.test
DR-0004 dr4@p9.test
DR-0005 dr5@p9.test
```

## Contenido tras la restauracion (SELECT real sobre el PVC restaurado)

```
DR-0001 dr1@p9.test
DR-0002 dr2@p9.test
DR-0003 dr3@p9.test
DR-0004 dr4@p9.test
DR-0005 dr5@p9.test
```

Filas vivas por tabla tras restaurar (pg_stat_user_tables):

```
cron_ejecuciones=1
cron_resumenes=0
cursos=0
estudiantes=0
eventos_inscripciones=0
inscripciones=0
usuarios=0
```

## Registro con marcas de tiempo

```

2026-09-24T07:31:12Z | prueba-datos: estado inicial
2026-09-24T07:31:13Z | prueba-datos: estudiantes antes de la prueba = 5
2026-09-24T07:31:15Z | prueba-datos: 5 estudiantes de control insertados
2026-09-24T07:31:16Z | prueba-datos: respaldo p9-datos-prueba-20260924073115 lanzado (template del schedule velero-p9-platform)
2026-09-24T07:32:07Z | prueba-datos: respaldo Completed | inicio 2026-09-24T07:31:16Z | fin 2026-09-24T07:32:01Z | items 798/798 | PVB de datos: rabbitmq-0=Completed(0.2 MiB), postgresql-0=Completed(62.7 MiB)
2026-09-24T07:32:09Z | prueba-datos: estudiante DR-POST insertado DESPUES del respaldo
2026-09-24T07:32:12Z | prueba-datos: DESASTRE - estudiantes borrados (count = 0)
2026-09-24T07:32:12Z | restore-datos: buscando respaldo (schedule=velero-p9-platform)
2026-09-24T07:32:13Z | restore-datos: respaldo elegido = p9-datos-prueba-20260924073115 (completado 2026-09-24T07:32:01Z)
2026-09-24T07:32:13Z | restore-datos: pausando GitOps (root app + sa-platform-dev)
2026-09-24T07:32:14Z | restore-datos: eliminando statefulset/postgresql y sus PVC
2026-09-24T07:32:16Z | restore-datos: eliminando statefulset/rabbitmq y sus PVC
2026-09-24T07:32:28Z | restore-datos: creando Restore p9-datos-20260924073228
2026-09-24T07:33:17Z | restore-datos: Restore p9-datos-20260924073228 -> Completed
2026-09-24T07:33:18Z | restore-datos: PodVolumeRestore completados = 5/5
2026-09-24T07:33:18Z | restore-datos: postgresql-0 Ready con el volumen restaurado
2026-09-24T07:34:00Z | restore-datos: rabbitmq-0 Ready con el volumen restaurado
2026-09-24T07:34:00Z | restore-datos: reactivando GitOps
2026-09-24T07:34:01Z | restore-datos: FIN
2026-09-24T07:34:04Z | prueba-datos: contenido restaurado COINCIDE con los 5 registros de control; DR-POST no recuperado (esperado)
2026-09-24T07:34:04Z | prueba-datos: RPO real (desastre - inicio del respaldo) = 55 s | duracion de la restauracion = 109 s

```

## Nota tecnica sobre el fallo de la primera version de la prueba

El primer intento de esta prueba (2026-09-23) dejaba los PVC restaurados vacios y se
documento como "limitacion de Velero". La causa real era otra: la politica Kyverno
`p8-require-non-root` rechazaba el pod restaurado porque Velero inyecta el initContainer
`restore-wait` sin `runAsNonRoot`; sin pod restaurado no se crea ningun PodVolumeRestore.
Se corrigio eximiendo unicamente ese initContainer (`P8/security/kyverno/03-require-non-root.yaml`)
y restaurando statefulsets + pods + PVC (no solo PVC).
