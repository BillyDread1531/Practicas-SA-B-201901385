# Reconstruccion cronometrada (destruccion total + bootstrap desde cero)

> **Corrida 1 (registro historico).** Durante esta corrida hubo una intervencion: se subio a GitOps un arreglo (ignoreDifferences en los CRD de Kyverno) porque la app `kyverno` no llegaba a Synced. La corrida limpia, sin intervencion, esta en `reconstruccion-cronometrada.md`.

Generada por `P9/scripts/prueba-reconstruccion.ps1`. Horas en UTC (ISO 8601). Las marcas se copian
literalmente del registro que produjeron los scripts (seccion final), no se estiman.

## Marcas de tiempo

| Marca | Hora (UTC) | Comando o evidencia |
|---|---|---|
| Respaldo previo completado | 2026-09-24T08:12:13Z | `Backup p9-dr-20260924081100` -> Azure Blob `stp9velero201901385/velero` |
| Destruccion iniciada | 2026-09-24T08:12:21Z | `terraform destroy -auto-approve` (stack P9/terraform) |
| Destruccion terminada (desastre consumado, **T0**) | 2026-09-24T08:20:09Z | `az group exists rg-sa-p9` = false |
| Bootstrap lanzado | 2026-09-24T08:20:09Z | `P9/scripts/bootstrap.ps1` |
| Terraform apply iniciado | 2026-09-24T08:20:15Z | estado remoto azurerm + bloqueo |
| Terraform apply completo (AKS + ArgoCD + llaves + Velero + app raiz) | 2026-09-24T08:28:51Z | |
| AKS disponible | 2026-09-24T08:29:00Z | nodos Ready |
| ArgoCD disponible | 2026-09-24T08:29:00Z | `argocd-server` Ready |
| SealedSecret descifrado (continuidad de secretos) | 2026-09-24T08:33:51Z | llave restaurada desde Key Vault |
| Aplicaciones del app-of-apps sincronizadas | 2026-09-24T08:33:49Z | sealed-secrets, argo-rollouts, kyverno, p8-kyverno-policies, sa-platform-dev |
| `p9-root-app` Healthy | 2026-09-24T08:33:49Z | |
| Restauracion de datos: inicio -> fin | 2026-09-24T08:33:54Z -> 2026-09-24T08:36:06Z | Restore de Velero + PodVolumeRestore |
| Servicio responde | 2026-09-24T08:36:13Z | `GET /health` por la IP publica del gateway |
| Datos verificados (**T1**) | 2026-09-24T08:36:16Z | SELECT sobre el PVC restaurado |

## Resultado

| Indicador | Objetivo declarado | Medido | Veredicto |
|---|---|---|---|
| **RTO** (T1 - T0) | 60 min | **16 min 07 s** (967 s) | CUMPLE |
| Duracion del bootstrap (T1 - bootstrap lanzado) | - | 16 min 07 s | - |
| **RPO** (inicio de la destruccion - inicio del respaldo) | 6 h | **1 min 20 s** en esta prueba | ver nota |
| Datos no recuperados | - | 1 estudiante (`DR-POST`, insertado a las 2026-09-24T08:12:21Z, despues del respaldo) | esperado |

Nota sobre el RPO: aqui el respaldo se lanzo minutos antes del desastre, por lo que el valor medido es pequeno.
El RPO **garantizado** por el diseno es el intervalo del schedule (cada 6 h) mas la duracion del respaldo: el
peor caso real es ~6 h. Lo medido demuestra el mecanismo (el dato posterior al respaldo se pierde, el anterior
se recupera); no reemplaza al objetivo.

## Contenido verificado tras la reconstruccion

Antes del desastre (estudiantes de control):

```
DR-0001 dr1@p9.test
DR-0002 dr2@p9.test
DR-0003 dr3@p9.test
DR-0004 dr4@p9.test
DR-0005 dr5@p9.test
```

Despues de reconstruir y restaurar (SELECT real):

```
DR-0001 dr1@p9.test
DR-0002 dr2@p9.test
DR-0003 dr3@p9.test
DR-0004 dr4@p9.test
DR-0005 dr5@p9.test
```

Filas vivas por tabla ANTES del desastre / DESPUES de la recuperacion:

```
cron_ejecuciones=5
cron_resumenes=1
cursos=0
estudiantes=5
eventos_inscripciones=0
inscripciones=0
usuarios=0
--- despues ---
cron_ejecuciones=1
cron_resumenes=0
cursos=0
estudiantes=0
eventos_inscripciones=0
inscripciones=0
usuarios=0
```

## Registro completo con marcas de tiempo

```

2026-09-24T08:10:56Z | DR: INICIO de la prueba de recuperacion
2026-09-24T08:11:00Z | DR: 5 estudiantes de control insertados
2026-09-24T08:12:16Z | DR: respaldo p9-dr-20260924081100 Completed (inicio 2026-09-24T08:11:01Z, fin 2026-09-24T08:12:13Z, items 1215)
2026-09-24T08:12:21Z | DR: respaldo verificado en Azure Blob stp9velero201901385/velero (backups/p9-dr-20260924081100/: 12 objetos; repositorio kopia: C:\Users\billy\OneDrive\Escritorio\SOTFWARE AVANZADO\PRACTICA 1\P9\scripts>  "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\\..\python.exe" -IBm azure.cli storage blob list --account-name stp9velero201901385 --account-key <REDACTED> --container-name velero --prefix kopia/ --query length(@) -o tsv objetos)
2026-09-24T08:12:21Z | DR: DR-POST insertado DESPUES del respaldo (se espera perderlo)
2026-09-24T08:12:21Z | DR: DESTRUCCION iniciada (terraform destroy del stack del cluster)
2026-09-24T08:20:09Z | DR: DESTRUCCION terminada - rg-sa-p9 existe=false (cluster perdido); rg-sa-p9-backend existe=true (capa persistente intacta)
2026-09-24T08:20:09Z | DR: RECUPERACION iniciada -> scripts/bootstrap.ps1
2026-09-24T08:20:09Z | bootstrap: INICIO
2026-09-24T08:20:10Z | bootstrap: prerrequisitos OK (az autenticado, terraform, kubectl)
2026-09-24T08:20:10Z | bootstrap: terraform init (backend remoto azurerm con bloqueo)
2026-09-24T08:20:15Z | bootstrap: terraform apply (AKS, ArgoCD, llaves Sealed Secrets, Velero, p9-root-app)
2026-09-24T08:28:51Z | bootstrap: terraform apply COMPLETO
2026-09-24T08:29:00Z | bootstrap: AKS disponible (nodos Ready)
2026-09-24T08:29:00Z | bootstrap: ArgoCD disponible (argocd-server Ready)
2026-09-24T08:29:01Z | bootstrap: p9-root-app presente en ArgoCD (namespace argocd)
2026-09-24T08:29:02Z | bootstrap: app sealed-secrets Synced
2026-09-24T08:29:48Z | bootstrap: app sa-platform-dev Synced
2026-09-24T08:30:04Z | bootstrap: app p8-kyverno-policies Synced
2026-09-24T08:33:01Z | bootstrap: app argo-rollouts Synced
2026-09-24T08:33:49Z | bootstrap: app kyverno Synced
2026-09-24T08:33:49Z | bootstrap: todas las aplicaciones del app-of-apps sincronizadas
2026-09-24T08:33:49Z | bootstrap: p9-root-app Healthy
2026-09-24T08:33:51Z | bootstrap: SealedSecret sa-platform-secrets DESCIFRADO (Secret creado por el controlador)
2026-09-24T08:33:54Z | bootstrap: PostgreSQL y RabbitMQ Ready (volumenes nuevos)
2026-09-24T08:33:54Z | bootstrap: buscando respaldos de Velero en el Blob persistente
2026-09-24T08:33:54Z | restore-datos: buscando respaldo (schedule=velero-p9-platform)
2026-09-24T08:33:56Z | restore-datos: respaldo elegido = p9-dr-20260924081100 (completado 2026-09-24T08:12:13Z)
2026-09-24T08:33:56Z | restore-datos: pausando GitOps (root app + sa-platform-dev)
2026-09-24T08:33:57Z | restore-datos: eliminando statefulset/postgresql y sus PVC
2026-09-24T08:33:59Z | restore-datos: eliminando statefulset/rabbitmq y sus PVC
2026-09-24T08:34:11Z | restore-datos: creando Restore p9-datos-20260924083411
2026-09-24T08:35:19Z | restore-datos: Restore p9-datos-20260924083411 -> Completed
2026-09-24T08:35:20Z | restore-datos: PodVolumeRestore completados = 5/5
2026-09-24T08:35:20Z | restore-datos: postgresql-0 Ready con el volumen restaurado
2026-09-24T08:36:05Z | restore-datos: rabbitmq-0 Ready con el volumen restaurado
2026-09-24T08:36:05Z | restore-datos: reactivando GitOps
2026-09-24T08:36:06Z | restore-datos: FIN
2026-09-24T08:36:06Z | bootstrap: datos restaurados desde Velero
2026-09-24T08:36:06Z | verificar: INICIO
2026-09-24T08:36:07Z | verificar: PASS  Nodos AKS Ready - 2 nodos Ready
2026-09-24T08:36:08Z | verificar: PASS  GitOps: app-of-apps y aplicaciones hijas - argo-rollouts=Synced/Healthy; kyverno=Synced/Healthy; p8-kyverno-policies=Synced/Healthy; p9-root-app=Synced/Healthy; sa-platform-dev=Synced/Progressing; sealed-secrets=Synced/Healthy
2026-09-24T08:36:09Z | verificar: PASS  Secretos: SealedSecret descifrado con la llave restaurada - Synced=True, Secret sa-platform-secrets creado, 2 llave(s) cargada(s), 0 errores de descifrado
2026-09-24T08:36:10Z | verificar: PASS  Velero: destino externo, schedule y respaldos - BSL Available (velero@stp9velero201901385); schedule '0 */6 * * *' ttl 720h; 3 respaldo(s) Completed
2026-09-24T08:36:12Z | verificar: PASS  Aplicacion: workloads listos y repartidos entre nodos - 6 deployments, 2 statefulsets, 1 rollout(s) listos; 7 PDB
2026-09-24T08:36:12Z | verificar: PASS  Entrega progresiva: Rollout del gateway (canary) sano - fase Healthy, estrategia canary con 11 pasos + analisis gateway-health
2026-09-24T08:36:12Z | verificar: PASS  Politicas de admision: Kyverno bloquea imagenes :latest - admision rechazada por p8-* (validationFailureAction=Enforce)
2026-09-24T08:36:13Z | verificar: PASS  Servicio publico: gateway responde por la IP del LoadBalancer - http://20.120.48.173:3000/health -> {"status":"ok","service":"gateway"}
2026-09-24T08:36:14Z | verificar: PASS  Datos: tablas de PostgreSQL con contenido - cron_ejecuciones=1, cron_resumenes=0, cursos=0, estudiantes=0, eventos_inscripciones=0, inscripciones=0, usuarios=0
2026-09-24T08:36:14Z | verificar: RESULTADO = todos los controles PASS
2026-09-24T08:36:14Z | bootstrap: FIN
2026-09-24T08:36:14Z | DR: bootstrap.ps1 terminado
2026-09-24T08:36:16Z | DR: DATOS VERIFICADOS - contenido COINCIDE con los 5 registros de control; DR-POST no recuperado (esperado)
2026-09-24T08:36:16Z | DR: RTO real = 16 min 07 s (objetivo 60 min -> CUMPLE); RPO real = 1 min 20 s (objetivo 6 h)

```
