Universidad San Carlos de Guatemala
Facultad de Ingeniería
Ingeniería en Ciencias y Sistemas

# Práctica 10: Observabilidad y operación (del síntoma a la causa)

**PONDERACIÓN:** 3.75 pts
**Tiempo estimado:** 14 hrs

---

## Índice

1. Marco formativo
   1. Valor
   2. Competencia(s)
   3. Habilidad(es) blandas a formar
2. Resultado del aprendizaje
   1. Objetivo SMART
3. Enunciado de la práctica
   1. Descripción del problema a resolver
   2. Alcance de la práctica
   3. Requerimientos técnicos
4. Entregables
   1. Tabla de enlaces obligatoria
   2. Plantilla del informe de operación
5. Material de apoyo
6. Recursos y herramientas a utilizar
7. Cronograma
8. Rúbrica de calificación
   1. Requisitos para optar a la calificación
   2. Resumen de puntuaciones
   - Detalle de la calificación
   - Comentarios generales

---

## 1. MARCO FORMATIVO

### 1.1. Valor

| Nombre del valor | ¿Cómo se aplica en tu laboratorio? |
|---|---|
| Responsabilidad sobre el servicio en producción | El estudiante deberá poder responder, con evidencia y no con suposiciones, qué está ocurriendo dentro de un sistema que ya está en manos de usuarios, asumiendo que afirmar que algo funciona sin poder demostrarlo es una forma de negligencia profesional. |

### 1.2. Competencia(s)

Con la elaboración de esta práctica usted adquirirá las siguientes competencias:

- **Competencia General:** Operar un sistema distribuido a partir de evidencia medida, distinguiendo entre lo que el sistema reporta sobre sí mismo y lo que los usuarios realmente experimentan.
- **Competencia Específica:** Instrumentar un ecosistema de microservicios con métricas, trazas y registros correlacionados, y utilizarlos para gobernar tanto las decisiones automáticas de despliegue como las alertas que exigen intervención humana.

### 1.3. Habilidad(es) blandas a formar

La práctica le permitirá desarrollar las siguientes habilidades:

- **Priorización ante señal ruidosa:** Distinguir lo que exige una acción inmediata de lo que únicamente informa, y asumir que una alerta que nadie atiende es peor que ninguna alerta.
- **Honestidad en la medición:** Reportar los tiempos realmente medidos aunque incumplan el objetivo declarado, en lugar de ajustar el objetivo al resultado obtenido.
- **Comunicación con no especialistas:** Expresar la salud del sistema en términos que una persona ajena a la ingeniería pueda entender y utilizar para tomar decisiones.

---

## 2. RESULTADO DEL APRENDIZAJE

### 2.1. Objetivo SMART

| Específico (¿Qué?) | Medible (¿Cuánto?) | Alcanzable (¿Cómo?) | Realista (¿Para qué?) | A Tiempo (¿Cuándo?) |
|---|---|---|---|---|
| Instrumentar el ecosistema de microservicios con los tres pilares de la observabilidad y gobernar con ellos la entrega progresiva. | Declarar 2 SLO y demostrar 1 reversión del canary provocada por métricas reales, 1 recorrido de alerta a causa en menos de 3 minutos y 1 alerta por consumo del presupuesto de error. | Utilizando OpenTelemetry, Prometheus, Grafana, un almacén de registros y un backend de trazas, sobre el flujo de la Práctica 8. | Adquirir criterio para operar sistemas donde el usuario percibe el fallo antes que el equipo que lo construyó. | Antes del XX de noviembre de 2026 a las 23:59 hrs, entregando el repositorio vía UEDI. |

---

## 3. ENUNCIADO DE LA PRÁCTICA

### 3.1 Descripción del problema a resolver

El sistema entregado hasta ahora se construye, despliega, protege y recupera de forma automatizada, pero sigue siendo una caja negra. Al revisarlo con criterio de operación aparecen tres carencias:

- Cuando un usuario reporta lentitud, nadie puede decir qué servicio la provocó ni por qué: solo queda revisar los registros de cada servicio por separado y suponer.
- La promoción del canary depende de pruebas sintéticas que el propio estudiante escribió, no del comportamiento real del sistema bajo tráfico de usuarios.
- No existe forma de saber si el sistema cumple con lo que promete a sus usuarios, ni de decidir con criterio cuándo un fallo amerita despertar a alguien.

Se le solicita instrumentar el ecosistema para responder tres preguntas que hoy no puede responder: qué está fallando, por qué está fallando, y si vale la pena intervenir. La práctica cierra además un pendiente deliberado de la Práctica 8: el análisis del canary dejará de ejecutar pruebas sintéticas y pasará a decidir con métricas reales, que es como se gobierna un despliegue en producción.

### 3.2 Alcance de la práctica

El estudiante deberá cumplir con las siguientes actividades:

- **Instrumentación con OpenTelemetry:** en al menos tres microservicios, con propagación de contexto entre ellos. Una misma petición debe poder seguirse de extremo a extremo bajo un único identificador de traza.
- **Métricas técnicas y de negocio:** además de latencia, tasa de error y saturación, al menos dos métricas que signifiquen algo para alguien que no es ingeniero, como pedidos creados o pagos rechazados.
- **Registros estructurados:** en formato JSON y con el identificador de traza incluido, de modo que desde una traza se llegue a sus registros y desde un registro a su traza.
- **Recolección y almacenamiento:** Prometheus para métricas, un almacén de registros consultable y un backend de trazas, todos desplegados mediante el flujo GitOps de la Práctica 8 y no de forma manual.
- **Canary gobernado por métricas:** el AnalysisTemplate de Argo Rollouts deberá consultar Prometheus en lugar de ejecutar un Job de pruebas. La promoción dependerá de la tasa de error y del percentil 95 de latencia medidos sobre la versión candidata.
- **Objetivos de nivel de servicio:** dos SLO declarados y justificados, con sus reglas de registro calculando el indicador y el presupuesto de error consumido.
- **Alertas por consumo del presupuesto:** no por umbral instantáneo. Cada alerta deberá enlazar a un runbook y justificar por qué amerita intervención; las que no la ameriten deberán eliminarse.
- **Tablero de operación:** organizado según los cuatro señales de oro, pensado para responder preguntas concretas y no para exhibir todas las métricas disponibles.
- **Recorrido del síntoma a la causa:** ante un fallo inducido, demostrar el camino alerta, traza y registro del error, con el tiempo cronometrado.
- **Fallo inducido:** distinto al utilizado en la Práctica 8. Deberá demostrarse que el canary lo detecta por métricas y revierte sin intervención.
- **Conservación del flujo previo:** GitOps, entrega progresiva, políticas de admisión y la cadena de suministro deben seguir operando sin degradarse.

### 3.3 Requerimientos técnicos

El estudiante deberá utilizar o integrar las siguientes herramientas y tecnologías:

- OpenTelemetry: SDK de instrumentación y Collector.
- Prometheus y Alertmanager.
- Grafana para tableros.
- Loki o un almacén de registros equivalente.
- Jaeger o Tempo como backend de trazas.
- Argo Rollouts con analysis de tipo prometheus.
- Kubernetes y el flujo GitOps de la Práctica 8.
- El ecosistema de microservicios de las prácticas anteriores.

---

## 4. ENTREGABLES

| Tipo | Descripción |
|---|---|
| Repositorio de código | Carpeta `/P10` con la instrumentación, los tableros exportados y la documentación. |
| Repositorio GitOps | Manifiestos del stack de observabilidad y del AnalysisTemplate basado en métricas. |
| README de entrega | Ubicado en `/P10`, con la tabla de enlaces obligatoria de la sección 4.1. |
| Instrumentación | Código de los tres servicios con OpenTelemetry y propagación de contexto. |
| Definición de SLO | Los dos objetivos declarados, con sus reglas de registro y su justificación. |
| Reglas de alerta | Alertas por consumo del presupuesto de error, cada una enlazada a su runbook. |
| Runbooks | Procedimiento de atención por cada alerta definida. |
| Tablero | Archivo JSON exportado de Grafana y captura del tablero en operación. |
| Evidencia del canary | Reversión provocada por métricas, con el AnalysisRun que la originó. |
| Evidencia síntoma a causa | Recorrido de la alerta a la traza y al registro, con tiempos. |
| Informe de operación | Según la plantilla de la sección 4.2, con un máximo de dos páginas. |
| Diagrama del flujo de telemetría | Recorrido de la señal desde el servicio hasta el tablero y la alerta. |
| Video demostrativo | De 5 a 8 minutos, con minutaje indicado en el README. |

### 4.1 Tabla de enlaces obligatoria

El README de la carpeta `/P10` deberá incluir la siguiente tabla completamente llena. Un enlace ausente, roto o que requiera autenticación se calificará con cero en el criterio correspondiente, sin búsqueda adicional dentro del repositorio.

| Ítem | Enlace o dato requerido |
|---|---|
| Repositorio de código | URL pública |
| Repositorio GitOps | URL pública |
| Servicios instrumentados | Nombres de los tres servicios y namespace |
| AnalysisTemplate por métricas | Nombre exacto y ruta del manifiesto |
| Consultas del análisis | Las expresiones PromQL que deciden la promoción |
| SLO declarados | Objetivo y ventana de cada uno |
| Reglas de alerta | Ruta del manifiesto de PrometheusRule |
| Tablero | Ruta del JSON exportado |
| Reversión por métricas | Nombre del AnalysisRun fallido y del Rollout |
| Recorrido síntoma a causa | Ruta de la evidencia y tiempo medido |
| Video demostrativo | URL y minutaje por punto demostrado |

### 4.2 Plantilla del informe de operación

El informe no deberá exceder dos páginas y deberá responder exactamente estos seis campos:

- **SLO declarados:** objetivo, ventana y por qué ese número y no otro.
- **Fallo inducido:** qué se rompió deliberadamente y cómo se provocó.
- **Tiempo de detección:** minutos entre el inicio del fallo y la primera señal, con la marca de tiempo que lo respalda.
- **Recorrido hasta la causa:** los pasos exactos seguidos desde la alerta hasta el registro del error, y cuánto tomó.
- **Tiempo de recuperación:** minutos hasta el retorno al estado estable y quién o qué lo resolvió.
- **Alerta faltante o sobrante:** qué señal habría acortado la detección, o qué alerta resultó ruido.

---

## 5. MATERIAL DE APOYO

- Documentación oficial de OpenTelemetry: https://opentelemetry.io/docs/
- Documentación oficial de Prometheus: https://prometheus.io/docs/
- Análisis con Prometheus en Argo Rollouts: https://argo-rollouts.readthedocs.io
- Documentación oficial de Grafana y Loki: https://grafana.com/docs/
- Documentación oficial de Jaeger: https://www.jaegertracing.io/docs/
- Capítulos de SLO y presupuesto de error del libro *Site Reliability Engineering* de Google.
- Los cuatro señales de oro: latencia, tráfico, errores y saturación.

---

## 6. RECURSOS Y HERRAMIENTAS A UTILIZAR

- **Instrumentación:** OpenTelemetry SDK y Collector.
- **Métricas y alertas:** Prometheus y Alertmanager.
- **Visualización:** Grafana.
- **Registros:** Loki o equivalente consultable.
- **Trazas:** Jaeger o Tempo.
- **Entrega progresiva:** Argo Rollouts con analysis de tipo prometheus.
- **Orquestación y entrega:** K8s (Kubernetes), ArgoCD y GitHub Actions.

---

## 7. CRONOGRAMA

| Tipo | Fecha Inicio | Fecha Fin |
|---|---|---|
| Asignación de Práctica | 08/10/2026 | 08/10/2026 |
| Elaboración | 08/10/2026 | 15/10/2026 |
| Calificación | 17/10/2026 | 17/10/2026 |

---

## 8. RÚBRICA DE CALIFICACIÓN

### 8.1 Requisitos para optar a la calificación

Antes de la evaluación de la práctica, los estudiantes deben cumplir con los requisitos que se indiquen en esta sección.

| Tema | Descripción | Cumple (Sí/No) |
|---|---|---|
| Práctica 8 | Contar con el desarrollo de la Práctica 8 previamente calificado. | |
| Stack operativo | Prometheus está recolectando métricas de los servicios al momento de la calificación. | |
| Canary por métricas | El AnalysisTemplate del Rollout consulta Prometheus y no ejecuta un Job de pruebas. | |
| SLO calculándose | Existe al menos una regla de registro que calcula el indicador y el presupuesto consumido. | |
| README de entrega | La tabla de enlaces obligatoria está completa y todos los enlaces son accesibles públicamente. | |

### 8.2 Resumen de puntuaciones

| Área | Puntos Totales (Base 100) | Puntos Obtenidos |
|---|---|---|
| **1. Habilidades (40%)** | | |
| Definición y justificación de los SLO | 10 | |
| Tablero de operación | 8 | |
| Informe de operación | 12 | |
| Preguntas teóricas | 10 | |
| **Sub-Total Habilidades** | **40** | |
| **2. Conocimiento (60%)** | | |
| Instrumentación y correlación de los tres pilares | 14 | |
| Canary gobernado por métricas | 16 | |
| SLO y alertas por presupuesto de error | 12 | |
| Recorrido del síntoma a la causa | 10 | |
| Registros estructurados y consultables | 8 | |
| **Sub-Total Conocimiento** | **60** | |
| **TOTAL (Escalable a 3.75 pts)** | **100** | |

### Detalle de la calificación

| No. | Criterio de evaluación | Punteo máximo | Satisfactorio (100% - 61%) | Necesita mejorar (60% - 0%) | Punteo Obtenido |
|---|---|---|---|---|---|
| **1** | **Habilidades** | **40** | | | |
| 1.1 | Definición y justificación de los SLO | 10 | Dos objetivos expresados desde la experiencia del usuario, con ventana definida y una justificación del número elegido. | Objetivos copiados del ejemplo, sin ventana o basados en métricas de infraestructura. | |
| 1.2 | Tablero de operación | 8 | Organizado por los cuatro señales de oro y pensado para responder preguntas concretas de operación. | Tablero con todas las métricas disponibles, sin jerarquía ni propósito. | |
| 1.3 | Informe de operación | 12 | Responde los seis campos con tiempos reales y propone una mejora concreta a su propia instrumentación. | Tiempos estimados en lugar de medidos, o sin análisis de las alertas faltantes o sobrantes. | |
| 1.4 | Preguntas teóricas | 10 | Analiza el comportamiento de su propia instrumentación y reconoce sus límites. | Respuestas memorizadas o contradictorias con lo que su sistema demuestra. | |
| **2** | **Conocimiento** | **60** | | | |
| 2.1 | Instrumentación y correlación | 14 | Tres servicios instrumentados con propagación de contexto; desde una traza se llega a sus registros y existen métricas de negocio. | Instrumentación parcial, sin propagación entre servicios o sin correlación entre señales. | |
| 2.2 | Canary gobernado por métricas | 16 | El análisis consulta Prometheus con expresiones propias y la reversión se produce por el comportamiento real de la versión candidata. | El análisis sigue ejecutando pruebas sintéticas o las consultas no reflejan el tráfico del canary. | |
| 2.3 | SLO y alertas por presupuesto | 12 | Reglas de registro calculando indicador y presupuesto; alertas por consumo, cada una con runbook y acción asociada. | Alertas por umbral instantáneo, sin runbook, o ruido que nadie atendería. | |
| 2.4 | Recorrido del síntoma a la causa | 10 | Llega desde la alerta hasta el registro del error en menos de tres minutos, usando las tres señales. | Depende de revisar registros servicio por servicio o no llega a la causa. | |
| 2.5 | Registros estructurados | 8 | Formato JSON con identificador de traza, consultables por campo desde el almacén de registros. | Registros en texto plano, sin identificador de traza o no centralizados. | |

### Comentarios generales

*(Espacio en blanco en el documento original.)*
