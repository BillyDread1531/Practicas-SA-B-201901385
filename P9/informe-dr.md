# Informe de la Prueba de Recuperación ante Desastres

**Práctica:** 9 — Continuidad operativa y recuperación ante desastres
**Estudiante:** Billy Dread (201901385)
**Cluster:** aks-sa-p9
**Fecha:** 2026-09-23

---

## 1. Objetivos declarados

**RTO (Recovery Time Objective):** 60 minutos
**RPO (Recovery Point Objective):** 6 horas

**Justificación:**

El RTO de 60 minutos se eligió porque el bootstrap completo con Terraform tarda aproximadamente 15-20 minutos en crear el clúster y aplicar la app-of-apps con ArgoCD, más el tiempo de sincronización de los microservicios (~30 minutos). Un RTO de 60 minutos da margen para verificación.

El RPO de 6 horas se eligió porque el schedule de Velero corre cada 6 horas (0 */6 * * *). Es el intervalo máximo de pérdida de datos aceptable para el sistema.


---

## 2. Escenario ejecutado

Se ejecutaron tres pruebas de recuperación:

**Prueba 1: Pérdida de un nodo**

Se drenó el nodo aks-system-29442814-vmss000000 con kubectl drain, forzando la evicción de todos los pods de la aplicación. El servicio gateway siguió respondiendo durante todo el proceso.

**Prueba 2: Pérdida de datos en PostgreSQL**

Se insertaron tres estudiantes de prueba en la base de datos academia. Se ejecutó un respaldo con Velero. Se eliminaron los tres registros con DELETE. Se intentó restaurar el respaldo a un namespace separado.

**Prueba 3: Eliminación y recreación de Deployments**

Se eliminaron los Deployments de auth-service, cursos-service, estudiantes-service, inscripciones-service y el Rollout de gateway, para forzar su recreación desde el repositorio GitOps mediante ArgoCD.


---

## 3. Tiempos medidos

**Prueba 1 — Pérdida de nodo:**

- Inicio del drain: registrado en el log de drain
- Duración del drain: 75 segundos
- Fin del drain (nodo cordoned): node drained
- Uncordon: ejecutado 30 segundos después
- Tiempo total de indisponibilidad: 0 segundos (el servicio nunca dejó de responder)
- RTO real prueba 1: 75 segundos

**Prueba 2 — Restauración de datos:**

- Backup creado: 06:22:20 UTC
- Backup completado: 06:22:55 UTC (duración: 35 segundos)
- DELETE ejecutado: 06:23:00 UTC
- Restore iniciado: 06:23:02 UTC
- Restore completado: 06:23:03 UTC
- Verificación con SELECT: NO SE PUDO VERIFICAR LOS DATOS
- RTO real prueba 2: NO APLICABLE (restore de datos falló)

**Prueba 3 — Recreación de Deployments:**

- Deployments eliminados: registrado en consola
- ArgoCD recreó los recursos: 30-60 segundos
- Todos los pods Running: 2 minutos después de la eliminación


---

## 4. Pérdida medida

**Prueba 1:** Cero pérdida de datos. Los pods evictados fueron recreados por sus Deployments sin pérdida de estado, porque ninguno de ellos usa almacenamiento persistente.

**Prueba 2:** Tres registros de estudiantes fueron eliminados y NO se recuperaron del respaldo durante la prueba. Los datos originales permanecen en Azure Blob (Kopia) pero no fueron inyectados en el PVC restaurado.

**Prueba 3:** Cero pérdida de datos. ArgoCD recreó todos los recursos desde el repositorio GitOps.

**RPO real medido:** los datos eliminados no se recuperaron. RPO efectivo indefinido para el flujo probado.


---

## 5. Puntos únicos de fallo detectados

Las pruebas revelaron 8 SPOFs que no eran evidentes durante la operación normal. Los tres más críticos:

**SPOF 1: ArgoCD application-controller con 0 réplicas**

El StatefulSet argocd-application-controller tenía replicas: 0. ArgoCD reportaba las aplicaciones como Synced pero no sincronizaba cambios nuevos. El sistema GitOps estaba silenciosamente roto.

Mitigación: kubectl scale statefulset argocd-application-controller --replicas=1

**SPOF 2: SealedSecret cifrado con llave obsoleta**

El SealedSecret sa-platform-secrets había sido cifrado con la llave del clúster anterior (aks-sa-p6). El controller no podía descifrarlo. Tras un reinicio del clúster, los secretos no podrían regenerarse.

Mitigación: re-cifrado de los secretos con kubeseal usando la llave del clúster actual. La llave fue respaldada en Azure Blob Storage.

**SPOF 3: Velero no restaura datos automáticamente**

El restore de Velero recupera la definición del PVC pero no inyecta los datos de Kopia. Los datos están en Azure Blob pero no se aplican al PVC nuevo. PostgreSQL ejecuta initdb y crea una base vacía.

Mitigación pendiente: crear PodVolumeRestore manualmente o usar Velero CLI con --restore-volumes.

**SPOFs adicionales documentados:** ver P9/docs/spofs-detectados.md


---

## 6. Brecha y plan

**Brecha entre lo declarado y lo medido:**

| Objetivo | Declarado | Medido | Brecha |
|----------|-----------|--------|--------|
| RTO prueba 1 (nodo) | 60 min | 75 segundos | Sin brecha |
| RTO prueba 3 (recreación) | 60 min | 2 minutos | Sin brecha |
| RPO prueba 2 (datos) | 6 horas | Falló el restore | Brecha total |

**Plan para cerrar la brecha:**

1. **Investigar el mecanismo de restauración de datos con Velero + Kopia.** El PodVolumeRestore debe crearse explícitamente cuando el namespace destino no tiene pods corriendo.

2. **Documentar el procedimiento de restore de datos con Velero CLI.** Comandos como velero restore create --from-backup <backup> --restore-volumes y --include-resources persistentvolumeclaims.

3. **Agregar verificación de datos en el runbook.** Antes de declarar un restore exitoso, verificar contenido con SELECT.

4. **Considerar migrar a restauración in-place** en el mismo namespace, donde Velero sí crea PodVolumeRestore automáticamente.

5. **Automatizar el proceso** con un script que combine el restore del PVC + el PodVolumeRestore + la verificación con SELECT.

**Conclusión:** Las pruebas de pérdida de nodo y de recreación de Deployments fueron exitosas. La prueba de restauración de datos reveló una limitación conocida de Velero + Kopia que requiere intervención manual. El sistema es recuperable pero requiere conocimiento técnico específico para el restore de datos.

