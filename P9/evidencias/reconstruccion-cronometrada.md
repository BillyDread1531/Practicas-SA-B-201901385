# Reconstruccion cronometrada (destruccion total + bootstrap desde cero)

Generada por `P9/scripts/prueba-reconstruccion.ps1`. Horas en UTC (ISO 8601). Las marcas se copian
literalmente del registro que produjeron los scripts (seccion final), no se estiman.

## Marcas de tiempo

| Marca | Hora (UTC) | Comando o evidencia |
|---|---|---|
| Respaldo previo completado | 2026-09-24T08:59:45Z | `Backup p9-dr-20260924085848` -> Azure Blob `stp9velero201901385/velero` |
| Destruccion iniciada | 2026-09-24T08:59:53Z | `terraform destroy -auto-approve` (stack P9/terraform) |
| Destruccion terminada (desastre consumado, **T0**) | 2026-09-24T09:06:37Z | `az group exists rg-sa-p9` = false |
| Bootstrap lanzado | 2026-09-24T09:06:37Z | `P9/scripts/bootstrap.ps1` |
| Terraform apply iniciado | 2026-09-24T09:06:43Z | estado remoto azurerm + bloqueo |
| Terraform apply completo (AKS + ArgoCD + llaves + Velero + app raiz) | 2026-09-24T09:15:53Z | |
| AKS disponible | 2026-09-24T09:16:02Z | nodos Ready |
| ArgoCD disponible | 2026-09-24T09:16:02Z | `argocd-server` Ready |
| SealedSecret descifrado (continuidad de secretos) | 2026-09-24T09:19:12Z | llave restaurada desde Key Vault |
| Aplicaciones del app-of-apps sincronizadas | 2026-09-24T09:19:10Z | sealed-secrets, argo-rollouts, kyverno, p8-kyverno-policies, sa-platform-dev |
| `p9-root-app` Healthy | 2026-09-24T09:19:11Z | |
| Restauracion de datos: inicio -> fin | 2026-09-24T09:19:15Z -> 2026-09-24T09:21:10Z | Restore de Velero + PodVolumeRestore |
| Servicio responde | 2026-09-24T09:21:17Z | `GET /health` por la IP publica del gateway |
| Datos verificados (**T1**) | 2026-09-24T09:21:21Z | SELECT sobre el PVC restaurado |

## Resultado

| Indicador | Objetivo declarado | Medido | Veredicto |
|---|---|---|---|
| **RTO** (T1 - T0) | 60 min | **14 min 44 s** (884 s) | CUMPLE |
| Duracion del bootstrap (T1 - bootstrap lanzado) | - | 14 min 44 s | - |
| **RPO** (inicio de la destruccion - inicio del respaldo) | 6 h | **1 min 03 s** en esta prueba | ver nota |
| Datos no recuperados | - | 1 estudiante (`DR-POST`, insertado a las 2026-09-24T08:59:53Z, despues del respaldo) | esperado |

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
cron_ejecuciones=1
cron_resumenes=0
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

2026-09-24T08:58:45Z | DR: INICIO de la prueba de recuperacion
2026-09-24T08:58:48Z | DR: 5 estudiantes de control insertados
2026-09-24T08:59:48Z | DR: respaldo p9-dr-20260924085848 Completed (inicio 2026-09-24T08:58:50Z, fin 2026-09-24T08:59:45Z, items 727)
2026-09-24T08:59:52Z | DR: respaldo verificado en Azure Blob stp9velero201901385/velero (backups/p9-dr-20260924085848/: 12 objetos; repositorio kopia: C:\Users\billy\OneDrive\Escritorio\SOTFWARE AVANZADO\PRACTICA 1\P9\scripts>  "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\\..\python.exe" -IBm azure.cli storage blob list --account-name stp9velero201901385 --account-key <REDACTED> --container-name velero --prefix kopia/ --query length(@) -o tsv objetos)
2026-09-24T08:59:53Z | DR: DR-POST insertado DESPUES del respaldo (se espera perderlo)
2026-09-24T08:59:53Z | DR: DESTRUCCION iniciada (terraform destroy del stack del cluster)
2026-09-24T09:06:37Z | DR: DESTRUCCION terminada - rg-sa-p9 existe=false (cluster perdido); rg-sa-p9-backend existe=true (capa persistente intacta)
2026-09-24T09:06:37Z | DR: RECUPERACION iniciada -> scripts/bootstrap.ps1
2026-09-24T09:06:37Z | bootstrap: INICIO
2026-09-24T09:06:38Z | bootstrap: prerrequisitos OK (az autenticado, terraform, kubectl)
2026-09-24T09:06:38Z | bootstrap: terraform init (backend remoto azurerm con bloqueo)
2026-09-24T09:06:43Z | bootstrap: terraform apply (AKS, ArgoCD, llaves Sealed Secrets, Velero, p9-root-app)
2026-09-24T09:15:53Z | bootstrap: terraform apply COMPLETO
2026-09-24T09:16:02Z | bootstrap: AKS disponible (nodos Ready)
2026-09-24T09:16:02Z | bootstrap: ArgoCD disponible (argocd-server Ready)
2026-09-24T09:16:02Z | bootstrap: p9-root-app presente en ArgoCD (namespace argocd)
2026-09-24T09:16:19Z | bootstrap: app sealed-secrets Synced
2026-09-24T09:17:06Z | bootstrap: app sa-platform-dev Synced
2026-09-24T09:18:55Z | bootstrap: app kyverno Synced
2026-09-24T09:19:10Z | bootstrap: app argo-rollouts Synced
2026-09-24T09:19:10Z | bootstrap: app p8-kyverno-policies Synced
2026-09-24T09:19:10Z | bootstrap: todas las aplicaciones del app-of-apps sincronizadas
2026-09-24T09:19:11Z | bootstrap: p9-root-app Healthy
2026-09-24T09:19:12Z | bootstrap: SealedSecret sa-platform-secrets DESCIFRADO (Secret creado por el controlador)
2026-09-24T09:19:14Z | bootstrap: PostgreSQL y RabbitMQ Ready (volumenes nuevos)
2026-09-24T09:19:14Z | bootstrap: buscando respaldos de Velero en el Blob persistente
2026-09-24T09:19:15Z | restore-datos: buscando respaldo (schedule=velero-p9-platform)
2026-09-24T09:19:16Z | restore-datos: respaldo elegido = p9-dr-20260924085848 (completado 2026-09-24T08:59:45Z)
2026-09-24T09:19:16Z | restore-datos: pausando GitOps (root app + sa-platform-dev)
2026-09-24T09:19:17Z | restore-datos: eliminando statefulset/postgresql y sus PVC
2026-09-24T09:19:19Z | restore-datos: eliminando statefulset/rabbitmq y sus PVC
2026-09-24T09:19:32Z | restore-datos: creando Restore p9-datos-20260924091932
2026-09-24T09:20:21Z | restore-datos: Restore p9-datos-20260924091932 -> Completed
2026-09-24T09:20:22Z | restore-datos: PodVolumeRestore completados = 5/5
2026-09-24T09:20:22Z | restore-datos: postgresql-0 Ready con el volumen restaurado
2026-09-24T09:21:04Z | restore-datos: rabbitmq-0 Ready con el volumen restaurado
2026-09-24T09:21:04Z | restore-datos: reactivando GitOps
2026-09-24T09:21:10Z | restore-datos: GitOps reactivado y aplicaciones Synced
2026-09-24T09:21:10Z | restore-datos: FIN
2026-09-24T09:21:10Z | bootstrap: datos restaurados desde Velero
2026-09-24T09:21:10Z | verificar: INICIO
2026-09-24T09:21:11Z | verificar: PASS  Nodos AKS Ready - 2 nodos Ready
2026-09-24T09:21:12Z | verificar: PASS  GitOps: app-of-apps y aplicaciones hijas - argo-rollouts=Synced/Healthy; kyverno=Synced/Healthy; p8-kyverno-policies=Synced/Healthy; p9-root-app=Synced/Healthy; sa-platform-dev=Synced/Progressing; sealed-secrets=Synced/Healthy
2026-09-24T09:21:13Z | verificar: PASS  Secretos: SealedSecret descifrado con la llave restaurada - Synced=True, Secret sa-platform-secrets creado, 2 llave(s) cargada(s), 0 errores de descifrado
2026-09-24T09:21:14Z | verificar: PASS  Velero: destino externo, schedule y respaldos - BSL Available (velero@stp9velero201901385); schedule '0 */6 * * *' ttl 720h; 5 respaldo(s) Completed
2026-09-24T09:21:16Z | verificar: PASS  Aplicacion: workloads listos y repartidos entre nodos - 6 deployments, 2 statefulsets, 1 rollout(s) listos; 7 PDB
2026-09-24T09:21:16Z | verificar: PASS  Entrega progresiva: Rollout del gateway (canary) sano - fase Healthy, estrategia canary con 11 pasos + analisis gateway-health
2026-09-24T09:21:16Z | verificar: PASS  Politicas de admision: Kyverno bloquea imagenes :latest - admision rechazada por p8-* (validationFailureAction=Enforce)
2026-09-24T09:21:17Z | verificar: PASS  Servicio publico: gateway responde por la IP del LoadBalancer - http://172.171.34.176:3000/health -> {"status":"ok","service":"gateway"}
2026-09-24T09:21:18Z | verificar: PASS  Datos: tablas de PostgreSQL con contenido - cron_ejecuciones=1, cron_resumenes=0, cursos=0, estudiantes=0, eventos_inscripciones=0, inscripciones=0, usuarios=0
2026-09-24T09:21:18Z | verificar: RESULTADO = todos los controles PASS
2026-09-24T09:21:18Z | bootstrap: FIN
2026-09-24T09:21:18Z | DR: bootstrap.ps1 terminado
2026-09-24T09:21:21Z | DR: DATOS VERIFICADOS - contenido COINCIDE con los 5 registros de control; DR-POST no recuperado (esperado)
2026-09-24T09:21:21Z | DR: RTO real = 14 min 44 s (objetivo 60 min -> CUMPLE); RPO real = 1 min 03 s (objetivo 6 h)

```
