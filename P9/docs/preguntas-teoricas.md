# Preguntas teóricas — respuestas sobre el propio sistema

Cada respuesta se apoya en una evidencia medida en este repositorio y dice también dónde el sistema **no** llega.

**1. Si se pierde el clúster entero, ¿qué se reconstruye solo y qué se pierde para siempre?**
Se reconstruye solo: AKS, ArgoCD, Velero, las llaves de Sealed Secrets, los controladores (Rollouts, Sealed Secrets, Kyverno),
las políticas y los microservicios (Terraform + app-of-apps), y los datos hasta el último respaldo (Velero). Se pierde: lo escrito
después del último respaldo (hasta 6 h; en la prueba, la fila `DR-POST`). Y **no** se recupera nada si se pierde también la capa
persistente (Blob de respaldos, Key Vault) o los repositorios de GitHub. Evidencia: `evidencias/reconstruccion-cronometrada.md`.

**2. ¿Por qué el orden del bootstrap importa? ¿Qué pasa si el controlador de Sealed Secrets arranca antes que la llave?**
El controlador solo carga al arrancar las llaves que ya están en `kube-system`; si no hay ninguna, genera una nueva y el
`SealedSecret` del repositorio (cifrado con la anterior) queda ilegible: `no key could decrypt secret`. Por eso Terraform crea
las llaves antes de `p9-root-app` (`bootstrap.tf` → `depends_on`). La recuperación si igual ocurre está en el runbook §6.

**3. ¿Diferencia entre RTO y RPO en su sistema?**
RTO = cuánto tarda en volver a servir con datos (medido desde que el clúster ya no existe hasta que el SELECT devuelve las filas).
RPO = cuántos datos se pierden (intervalo entre respaldos). Declarados: 60 min y 6 h. El RPO **medido** en la prueba es pequeño
porque el respaldo se hizo minutos antes del desastre; el RPO **garantizado** por el diseño sigue siendo ~6 h (+ duración del
respaldo). Medir poco no cambia el peor caso.

**4. La primera prueba de restauración dejó el volumen vacío. ¿Cuál era la causa real?**
No era una limitación de Velero (como se escribió al principio). Velero repone datos con un initContainer `restore-wait` en el
*pod restaurado*; la política Kyverno `p8-require-non-root` rechazaba ese pod (el initContainer no declara `runAsNonRoot`), y además
solo se restauraban PVC. Sin pod no hay `PodVolumeRestore`. Se eximió solo a `restore-wait` y se restauran
`statefulsets + pods + PVC + PV`. Lección: una política de seguridad puede romper la recuperación en silencio.

**5. ¿Cómo sabe que lo restaurado es real y no un volumen vacío?**
Se comparan fila por fila (carnet + email) las 5 filas de control antes del desastre y después de restaurar, y se comprueba que
la fila posterior al respaldo **no** reaparece. Un volumen vacío haría que PostgreSQL ejecutara `initdb` y no habría filas
`DR-000x`. Además se listan las filas vivas por tabla. Evidencia: `evidencias/restauracion-datos.md`.

**6. ¿Qué pasa si cae el nodo donde está PostgreSQL?**
Medido: `/health` sigue al 100 % pero las rutas con base de datos devuelven 5xx unos ~60 s (reprogramación + re-adjuntar el disco +
recuperación de PostgreSQL). Los 5 microservicios sin estado no se interrumpen (PDB `minAvailable: 1`, 2 réplicas, anti-afinidad).
PostgreSQL con una sola réplica es un SPOF abierto (`docs/spofs-detectados.md`, B-1).

**7. ¿Por qué anti-afinidad *preferred* y no *required*?**
Con `required` y 2 nodos, durante un rolling update no cabe la réplica nueva junto a las viejas: deadlock de scheduling (visto en
pruebas previas). `preferred` reparte cuando puede y no bloquea. El costo: en un nodo caído las dos réplicas pueden acabar juntas.

**8. ¿Qué garantiza el estado remoto de Terraform y qué no?**
Bloqueo (lease del Blob) que impide dos `apply` simultáneos, y que la infraestructura la reconstruya cualquiera con acceso, no una
sola máquina. No protege contra la pérdida del Storage del estado (está en la capa persistente, LRS, sin réplica): límite declarado.

**9. ¿Por qué Velero con copia de sistema de archivos (Kopia) y no snapshots?**
Los snapshots de disco de Azure viven en el mismo resource group/región que el clúster y se pierden con él; Kopia sube los datos al
Blob persistente, fuera del clúster. Costo: la copia es *crash-consistent*; por eso PostgreSQL ejecuta `CHECKPOINT` en un hook
previo al respaldo.

**10. ¿Qué pasa si Kyverno no está disponible?**
Su webhook rechaza la creación de pods (falla cerrado). Con una sola réplica, perder su nodo bloquea nuevas creaciones de pods hasta
que reinicie. No se observó en las pruebas (su pod estuvo en el nodo que quedó), pero es un SPOF real que se declara en vez de
esconderlo.

**11. ¿Qué cambiaría con más tiempo o cuota?**
Un tercer nodo y PostgreSQL con réplica; espejo de charts, imágenes y repositorio (hoy un cambio de URL de un chart ya dejó
la app en `Unknown`); Blob GRS y copia de la llave fuera de Azure; respaldos más frecuentes con archivado de WAL para bajar el RPO.

**12. ¿Qué parte de su documentación estaba equivocada y cómo lo descubrió?**
La conclusión «limitación conocida de Velero» (pregunta 4) y la afirmación de que el bootstrap era automático cuando requería instalar
tres controladores y restaurar la llave a mano. Se descubrió al intentar el destroy real con un único comando y al mirar por qué el pod
restaurado no arrancaba. La prueba manda sobre la documentación previa.
