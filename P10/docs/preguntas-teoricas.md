# Preguntas teóricas — Práctica 10

**1. ¿Por qué dos SLO de disponibilidad/latencia del gateway y no, por ejemplo, de PostgreSQL?**
Porque el SLO debe expresar lo que el **usuario** experimenta, no lo que el sistema reporta sobre sí mismo. El
usuario nunca habla con PostgreSQL directamente; habla con el gateway. Un SLO de "CPU de PostgreSQL < 80%" es una
métrica de infraestructura que puede estar perfecta mientras el usuario ve errores (por ejemplo, por un bug en
`auth-service` que no toca la base de datos). Ver `informe-operacion.md` para la justificación de los números
elegidos.

**2. ¿Por qué el AnalysisTemplate filtra por `rollouts_pod_template_hash` y no mide el error-rate global del
servicio?**
Porque sin ese filtro, el canario heredaría el ruido (o la salud) de la versión estable: si el canario falla al
100% pero solo recibe el 20% del tráfico, el error-rate agregado del servicio completo podría seguir pareciendo
bajo y el `AnalysisTemplate` nunca lo detectaría a tiempo. Medir solo los pods de la revisión candidata es lo que
hace que la promoción dependa del comportamiento *real* de esa versión, no de un promedio que la diluye.

**3. ¿Qué pasa si el AnalysisTemplate consulta Prometheus y Prometheus no tiene datos todavía (canario recién
creado)?**
La consulta PromQL divide por `(... + 0.001)` precisamente para evitar un `NaN` por `0/0`; con cero tráfico real,
el resultado es `0` (sin error) y `successCondition` pasa de forma optimista. Esto es un límite real: con 5
mediciones de 15s por paso (75s de observación), si el tráfico real es muy bajo, el canario podría promoverse sin
haber sido verdaderamente puesto a prueba. En esta práctica se generó tráfico sintético deliberado durante la
prueba para que hubiera señal suficiente; en producción, la ventana de análisis debe calibrarse contra el volumen
real de tráfico esperado.

**4. ¿Por qué el fallo se activa cambiando un ConfigMap y no editando el código del Pod directamente?**
Porque cambiar el ConfigMap cambia el `checksum/config` del pod template, que Argo Rollouts interpreta como una
revisión nueva — exactamente el mecanismo que dispara el canario. Si se editara el Pod en ejecución directamente
(`kubectl exec` o `kubectl patch pod`), eso no generaría una revisión nueva: no habría canario que analizar, y el
cambio se perdería en el siguiente reconciliado de ArgoCD (GitOps revertiría el cambio no declarado en Git).

**5. ¿Por qué el registro usa pino/JSON y no simplemente `console.log`?**
`console.log` produce texto libre: para encontrar los registros de una traza específica habría que grepear texto
sin estructura, servicio por servicio. El JSON con `trace_id`/`span_id`/`service` como campos reales permite
consultar Loki con LogQL (`{namespace="sa-p8"} | json | trace_id="..."`) y que Grafana construya el enlace
automático desde una traza en Tempo a sus registros exactos — la correlación entre pilares depende de que el campo
exista de forma estructurada, no de que esté "en algún lado del texto".

**6. ¿Qué parte de esta instrumentación es más frágil y por qué?**
El filtro por `rollouts_pod_template_hash` depende de que Prometheus promueva TODAS las etiquetas del pod a
etiquetas de métrica (`action: labelmap` en el scrape config). Si alguien simplifica ese scrape config en el futuro
(por ejemplo, para reducir cardinalidad de métricas), el `AnalysisTemplate` dejaría de poder distinguir canario de
estable sin que nadie lo note hasta el primer despliegue fallido — un canario roto que "siempre se promueve" es
peor que no tener canario, porque da una falsa sensación de seguridad.

**7. ¿Por qué el runbook de `TasaErrorAuthServiceElevada` dice "requiere un paso manual adicional" en los límites?**
Porque la alerta no distingue si el 5xx vino del código de `auth-service` o de una dependencia caída (PostgreSQL).
Reconocer ese límite es más honesto que pretender que una sola métrica agregada basta para diagnosticar cualquier
causa — exactamente lo que exige la competencia de esta práctica: "distinguiendo entre lo que el sistema reporta
sobre sí mismo y lo que los usuarios realmente experimentan" no es solo detectar el síntoma, sino saber cuándo una
señal no alcanza para explicar la causa.

**8. Si tuviera que elegir una sola alerta para eliminar por ruido, ¿cuál sería y por qué?**
Ninguna de las tres declaradas es puro ruido (las tres están atadas a un SLO con ventana de 1h o a un servicio
crítico de autenticación, no a un umbral instantáneo). La que más cerca está de volverse ruido si se usara en
producción real es `TasaErrorAuthServiceElevada`: su ventana de evaluación es corta (1 minuto) comparada con las
de presupuesto de error (2 minutos sobre una ventana de 1h). Un pico aislado de 70 segundos la dispararía sin que
el SLO general se vea afectado. Se mantuvo así para esta práctica porque el servicio es crítico (sin login, nada
funciona), pero en producción debería evaluarse contra una ventana más larga o con un `for:` mayor.

**9. ¿Qué límite reconoce el sistema que todavía no resuelve?**
El `AnalysisTemplate` y las alertas dependen de que el nodo único del clúster (restricción de costo, no de diseño)
no esté saturado: si el nodo entero se queda sin CPU, TODAS las métricas (incluidas las del canario estable) se
degradan a la vez, y el `AnalysisTemplate` podría fallar por una causa que no tiene nada que ver con la versión
candidata. Esto no se resolvió en esta práctica por la restricción de presupuesto (1 nodo `Standard_B2ms`); con más
cuota, la mitigación sería un segundo nodo y límites de recursos más estrictos por pod.
