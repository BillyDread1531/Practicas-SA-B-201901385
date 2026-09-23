# Restauración de datos

| Campo | Valor |
|---|---|
| Backup usado | PENDIENTE |
| Hora del backup | PENDIENTE |
| Dato de control creado | PENDIENTE |
| Hora de eliminación | PENDIENTE |
| Restore ejecutado | PENDIENTE |
| Contenido verificado | PENDIENTE |
| RPO real | PENDIENTE |

Agregar aquí la salida de `velero restore describe --details` y la consulta de PostgreSQL sin incluir contraseñas.

## Avance verificado

- Backup de control: `p9-valid-20260922`.
- Estado del backup: `Completed`.
- Recursos respaldados: 568 de 568.
- Destino: `BackupStorageLocation/default`, estado `Available`.
- PostgreSQL: pod `postgresql-0` en `Running` y PVC `data-postgresql-0` en `Bound`.
- Tablas verificadas: `cron_ejecuciones`, `cron_resumenes`, `cursos`, `estudiantes`, `eventos_inscripciones`, `inscripciones`, `usuarios`.
- RPO real: pendiente de ejecutar eliminación y restauración controlada de un dato.

## Prueba de restore aislado

- Restore: `p9-data-restore` desde `p9-postapply-20260922`.
- Resultado: `Completed`, 12 recursos restaurados.
- Secretos y ConfigMaps: restaurados en `sa-p8-restore`.
- Resultado del PVC: `Pending`, porque el PV original ya estaba ligado al claim de `sa-p8`.
- Acción: namespace de prueba eliminado; no se modificó producción.
- Conclusión: Velero restaura recursos Kubernetes, pero la restauración verificable del volumen requiere una prueba con PV/CSI aislado o sobre un entorno reconstruido desde cero.

## Verificación posterior al apply

- Backup: `p9-postapply-20260922`.
- Estado: `Completed`.
- Recursos respaldados: 913 de 913.
- Errores: 0.
- Destino: `BackupStorageLocation/default`.