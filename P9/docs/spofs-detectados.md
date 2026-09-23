
# SPOFs detectados durante las pruebas de P9

**Fecha de las pruebas:** 2026-09-23
**Cluster:** aks-sa-p9
**Responsable:** Billy Dread (201901385)

---

## Introducción

Durante la ejecución de las pruebas de recuperación ante desastres (DR) de la Práctica 9, se detectaron 8 puntos únicos de fallo (SPOFs) en el ecosistema construido en las prácticas anteriores. Este documento los lista con su impacto y la mitigación aplicada.

---

## SPOF #1: ArgoCD application-controller con 0 réplicas

**Síntoma:** ArgoCD reportaba las aplicaciones como `Synced` pero no sincronizaba cambios nuevos. Las revisiones quedaban congeladas en commits antiguos.

**Causa raíz:** El StatefulSet `argocd-application-controller` tenía `replicas: 0`. El controller no estaba corriendo.

**Impacto:** Crítico. Todo el flujo GitOps estaba silenciosamente roto.

**Mitigación aplicada:** `kubectl scale statefulset argocd-application-controller -n argocd --replicas=1`.

**Lección:** Monitorear el estado del controller es esencial. Un simple `kubectl get pods -n argocd` lo habría detectado.

---

## SPOF #2: SealedSecret cifrado con llave obsoleta

**Síntoma:** El SealedSecret `sa-platform-secrets` estaba en estado `Status: False`. El controller no podía descifrarlo.

**Causa raíz:** El SealedSecret había sido cifrado con la llave del clúster anterior (`aks-sa-p6`), no con la llave del clúster actual (`aks-sa-p9`).

**Impacto:** Crítico. Los secretos no podían regenerarse tras un reinicio del clúster.

**Mitigación aplicada:** Re-cifrado de los secretos con `kubeseal` usando el certificado público del clúster actual.

**Lección:** El SealedSecret debe re-cifrarse cada vez que se cambia de clúster.

---

## SPOF #3: SealedSecret almacenado en el path incorrecto

**Síntoma:** El SealedSecret del repositorio GitOps no coincidía con el aplicado por ArgoCD.

**Causa raíz:** Existían dos archivos `sealed-secret.yaml`: uno en `P8-GitOps/security/` (huérfano) y otro en `P8/charts/sa-platform/templates/` (el que ArgoCD realmente aplicaba).

**Impacto:** Alto. Cualquier actualización al SealedSecret del repo GitOps no surtía efecto.

**Mitigación aplicada:** Copiar el SealedSecret correcto al chart `sa-platform`, que es el que ArgoCD lee.

**Lección:** Documentar cuál es el archivo fuente que ArgoCD lee realmente.

---

## SPOF #4: Imágenes con tag `:p6` incompatible con ARM64

**Síntoma:** Los pods nuevos aparecían con `ErrImagePull` o `ImagePullBackOff`.

**Causa raíz:** Las imágenes con tag `:p6` fueron construidas para arquitectura AMD64, pero los nodos del clúster son ARM64. Además, las imágenes ya no existían en ACR con ese tag.

**Impacto:** Alto. Los Deployments nuevos no podían arrancar.

**Mitigación aplicada:** Cambiar los tags a SHA inmutables (`51cfc6bb05adaad0fa541395046daf466f545821`) en los `values.yaml` del repo GitOps.

**Lección:** Nunca usar tags mutables (`latest`, `p6`). Siempre SHA o semánticos.

---

## SPOF #5: Anti-afinidad `required` causaba deadlock

**Síntoma:** Varios pods quedaban en `Pending` sin poder agendarse.

**Causa raíz:** La anti-afinidad `requiredDuringScheduling` obligaba a que cada réplica estuviera en un nodo distinto. Con 2 nodos y 2 réplicas por servicio, los nuevos pods no cabían.

**Impacto:** Alto. Deadlock de scheduling.

**Mitigación aplicada:** Cambiar a `preferredDuringScheduling` con `weight: 100`. Permite convivir réplicas en el mismo nodo si es necesario.

**Lección:** En clústeres pequeños, la anti-afinidad estricta es contraproducente.

---

## SPOF #6: `spec.selector` inmutable impedía actualizar Deployments

**Síntoma:** ArgoCD fallaba con `spec.selector: Invalid value: field is immutable`.

**Causa raíz:** Se intentó cambiar los labels del selector de los Deployments. Kubernetes no permite modificar `spec.selector` en un Deployment existente.

**Impacto:** Alto. Los Deployments no podían actualizarse.

**Mitigación aplicada:** Borrar los Deployments y dejar que ArgoCD los recree desde cero.

**Lección:** El `spec.selector` de un Deployment es inmutable. Si necesita cambiar, borrar y recrear.

---

## SPOF #7: Velero no restaura volúmenes automáticamente

**Síntoma:** Después de un `velero restore`, los PVCs se creaban pero estaban vacíos. PostgreSQL ejecutaba `initdb` y creaba una base de datos nueva.

**Causa raíz:** Velero con Kopia (FS backup) no crea automáticamente los recursos `PodVolumeRestore` cuando el namespace destino no tiene pods corriendo. Los datos están en Azure Blob pero no se aplican al PVC.

**Impacto:** Crítico. El restore de datos no funciona out-of-the-box.

**Mitigación aplicada:** Pendiente. Documentar como limitación conocida. Los datos permanecen en Azure Blob y pueden restaurarse manualmente.

**Lección:** El restore de datos con Velero requiere verificación explícita del contenido del PVC, no solo de su existencia.

---

## SPOF #8: Clave de Azure Storage expuesta en salida de comandos

**Síntoma:** Durante la verificación de Velero, la clave del storage account apareció en la salida de PowerShell.

**Causa raíz:** El comando `az storage account keys list` imprime la clave si no se filtra la salida.

**Impacto:** Alto. Riesgo de seguridad. La clave podría haber sido comprometida.

**Mitigación aplicada:** Rotación inmediata de la clave. Actualización del secret de Velero con la nueva clave.

**Lección:** Nunca imprimir claves. Usar variables y filtrar la salida.

---

## Conclusiones

Las pruebas de DR revelaron 8 SPOFs que no eran evidentes durante la operación normal del sistema. Los más críticos son:

1. El controller de ArgoCD detenido silenciosamente.
2. Los SealedSecrets cifrados con llaves obsoletas.
3. La ausencia de restauración automática de datos con Velero.

Todos ellos están documentados con su mitigación y se incluyen en el runbook de recuperación.

