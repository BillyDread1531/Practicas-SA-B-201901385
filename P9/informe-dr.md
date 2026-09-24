# Informe de la prueba de recuperación ante desastres — Práctica 9

**Sistema:** microservicios en AKS `aks-sa-p9` (namespace `sa-p8`) · **Fecha de la prueba:** 2026-09-24 (UTC) ·
**Evidencia:** [reconstruccion-cronometrada.md](evidencias/reconstruccion-cronometrada.md)

## 1. Objetivos declarados

| Objetivo | Valor | Justificación |
|---|---|---|
| **RTO** | **60 min** | Se fijó antes de las pruebas: crear AKS + ArgoCD (~10–15 min) y sincronizar los servicios (~5–10 min) suman ~25 min; se dejó margen ×2 por la variabilidad de Azure y para restaurar datos y verificar. |
| **RPO** | **6 h** | El schedule de Velero corre cada 6 h (`0 */6 * * *`). El sistema es un entorno académico sin transacciones de valor por minuto; 6 h es la pérdida máxima aceptada, y bajar el intervalo aumentaría costo de almacenamiento y carga sobre PostgreSQL. |

## 2. Escenario ejecutado

Script `P9/scripts/prueba-reconstruccion.ps1`, en este orden:

1. Se insertaron 5 estudiantes de control (`DR-0001`…`DR-0005`) y se lanzó un respaldo de Velero al Blob persistente (`p9-dr-20260924085848`, verificado en el Blob).
2. Se insertó `DR-POST` **después** del respaldo (dato que debía perderse).
3. **Destrucción total** con `terraform destroy`: AKS, ArgoCD, Velero, llaves en el clúster, resource group `rg-sa-p9`, discos y balanceador. No se tocó la capa persistente (Blob de respaldos, Key Vault, estado de Terraform).
4. **Recuperación con un solo comando**, `scripts/bootstrap.ps1`, sin intervención: Terraform (AKS → ArgoCD → llaves desde Key Vault → Velero → app raíz) → ArgoCD por olas → restauración de datos con Velero → verificación.
5. Verificación de contenido fila por fila.

Además, en el clúster reconstruido: restauración de datos aislada ([restauracion-datos.md](evidencias/restauracion-datos.md)) y drenaje de nodo con sondeo continuo ([perdida-nodo.md](evidencias/perdida-nodo.md)).

## 3. Tiempos medidos (UTC, del registro de los scripts)

| Marca | Hora |
|---|---|
| Destrucción iniciada → terminada (**T0**, el clúster ya no existe) | 08:59:53 → 09:06:37 (6 min 44 s) |
| Bootstrap lanzado / `terraform apply` completo | 09:06:37 / 09:15:53 (9 min 10 s) |
| SealedSecret descifrado (llave restaurada) | 09:19:12 |
| Restauración de datos | 09:19:15 → 09:21:10 (1 min 55 s) |
| Servicio responde / **datos verificados (T1)** | 09:21:17 / 09:21:21 |

**RTO real = T1 − T0 = 14 min 44 s** frente a 60 min declarados: **cumple**, con margen de 45 min. Es la tercera corrida
completa; las dos anteriores dieron 16 min 07 s y 12 min 59 s y quedan como registro histórico en `evidencias/`. La primera requirió
subir un arreglo a GitOps durante la ejecución (`ignoreDifferences` en los CRD de Kyverno); la segunda corrió sin intervención pero el
verificador marcó un fallo espurio (carrera de 1 s tras reactivar GitOps), corregido; la tercera es la corrida limpia.

## 4. Pérdida medida

- **Recuperado:** los 5 registros de control, idénticos (carnet + email) a los de antes del desastre, más el contenido de RabbitMQ.
- **No recuperado:** `DR-POST`, insertado 0 min 08 s después de terminar el respaldo (dato posterior al último respaldo).
- **RPO medido en la prueba: 1 min 03 s** (inicio del respaldo → inicio de la destrucción). **No es el RPO del sistema**: el respaldo se
  lanzó adrede minutos antes del desastre. El RPO **garantizado** es el intervalo del schedule más la duración del respaldo
  (~1 min): **≈ 6 h en el peor caso**, es decir, dentro del objetivo pero sin margen. Lo medido demuestra el mecanismo, no el peor caso.

## 5. Puntos únicos de fallo detectados (detalle en [docs/spofs-detectados.md](docs/spofs-detectados.md))

Lo que la prueba reveló que **no** estaba cubierto y se corrigió: (1) los respaldos y su estado vivían en el mismo resource group que
el clúster, así que `destroy` los borraba; (2) la llave de Sealed Secrets solo existía en el clúster; (3) la restauración de datos
«fallaba» por una causa mal diagnosticada: la política Kyverno `require-non-root` rechazaba el initContainer `restore-wait` de Velero;
(4) el bootstrap exigía instalar tres controladores y restaurar la llave a mano; (5) con 2 nodos, perder uno dejaba 6 pods `Pending`
por requests sobredimensionados; (6) CronJobs sin ServiceAccount llevaban un día sin ejecutarse; (7) un chart de Sealed Secrets
cambió de URL y dejó la app en `Unknown`; (8) apps de ArgoCD perpetuamente `OutOfSync` (CRD).
**Siguen abiertos:** PostgreSQL con una réplica (5xx ~60 s si cae su nodo), dependencias externas (charts, imágenes, GitHub) sin espejo,
capa persistente de una sola región y una sola copia, ArgoCD/Kyverno/Velero sin alta disponibilidad, y un operador único con `az login`.

## 6. Brecha y plan

| Indicador | Declarado | Medido | Brecha |
|---|---|---|---|
| RTO | 60 min | 14 min 44 s | Ninguna (holgura de 45 min) |
| RPO | 6 h | 1 min 03 s en la prueba; **≈ 6 h en el peor caso** | Ninguna en el papel, pero sin margen: cualquier respaldo fallido lo supera |
| Continuidad de la base durante pérdida de nodo | sin interrupción | ~60 s de 5xx en rutas con base de datos si cae el nodo de PostgreSQL | **Sí**: 1 réplica |
| Recuperación si se pierde la capa persistente | — | No recuperable | **Sí**: no está cubierto |

**Honestidad sobre los límites:** el RTO medido excluye la destrucción y supone que la capa persistente, Azure, GitHub y los registros de
charts/imágenes están disponibles; en un desastre real el RTO dependería también de ellos. El sistema tiene pocos datos (~63 MiB), por
lo que la restauración fue rápida: con más datos el RTO crecería. La cuota de la suscripción (4 vCPU) limita el clúster a 2 nodos.

**Plan para cerrar la brecha:** (1) PostgreSQL con réplica (CloudNativePG) y un tercer nodo al subir la cuota; (2) Blob GRS y copia cifrada de
las llaves fuera de Azure; (3) espejo de charts, imágenes y repositorios; (4) schedule cada hora + archivado de WAL para bajar el RPO
a minutos; (5) alertas sobre respaldos fallidos y sobre `argocd-application-controller`; (6) repetir esta prueba de forma programada.
