# Práctica 6 - Despliegue en Kubernetes administrado en la nube

## Datos generales

- Proveedor cloud: Microsoft Azure
- Servicio Kubernetes administrado: Azure Kubernetes Service (AKS)
- Registro de contenedores: Azure Container Registry (ACR)
- Nombre del clúster: aks-sa-p6
- Grupo de recursos: rg-sa-p6
- Región: Central US
- Cantidad de nodos: 2
- Namespace: sa-p6
- Dirección pública del Gateway: http://57.165.161.54:3000

---

## 1. Descripción

En esta práctica se desplegó en la nube la plataforma desarrollada previamente en la Práctica 5.

La solución está compuesta por:

- API Gateway
- Auth Service
- Cursos Service
- Estudiantes Service
- Inscripciones Service
- Consumer de inscripciones
- PostgreSQL
- RabbitMQ
- CronJobs
- Consumer de resúmenes

El despliegue se realizó utilizando Helm sobre un clúster administrado de Kubernetes en Azure.

---

## 2. Arquitectura utilizada

El flujo general es:

Internet
?
Azure Load Balancer
?
API Gateway
?
Microservicios internos
?
PostgreSQL / RabbitMQ

El Gateway se expone mediante un Service de tipo LoadBalancer.

Los demás servicios utilizan ClusterIP y solamente son accesibles dentro del clúster.

---

## 3. Azure Kubernetes Service

Se creó un clúster AKS llamado:

aks-sa-p6

El clúster cuenta con dos nodos de trabajo.

Durante las pruebas ambos nodos se encontraban en estado Ready.

Ejemplo:

aks-nodepool1-14305836-vmss000000
aks-nodepool1-14305836-vmss000001

La versión utilizada de Kubernetes fue:

v1.35.7

---

## 4. Azure Container Registry

Se utilizó Azure Container Registry para almacenar las imágenes de los componentes desarrollados.

Registro utilizado:

acrsa201901385.azurecr.io

Repositorios publicados:

- auth-service
- cursos-service
- estudiantes-service
- inscripciones-service
- gateway
- cronjobs

Tag utilizado:

p6

Debido a que los nodos de AKS utilizan arquitectura ARM64, las imágenes fueron construidas utilizando Docker Buildx con:

--platform linux/arm64

---

## 5. Helm

La aplicación se desplegó utilizando un chart principal llamado:

sa-platform

El chart contiene los subcharts de los diferentes microservicios y las dependencias de PostgreSQL y RabbitMQ.

El despliegue final fue realizado mediante:

helm upgrade --install sa-platform . --namespace sa-p6 -f values-secret.yaml

La release quedó en estado:

deployed

---

## 6. Exposición pública

El Gateway fue modificado para utilizar:

type: LoadBalancer

Azure asignó la siguiente dirección pública:

57.165.161.54

Puerto:

3000

Dirección:

http://57.165.161.54:3000

La prueba del endpoint de salud devolvió:

HTTP/1.1 200 OK

Respuesta:

{"status":"ok","service":"gateway"}

Esto demuestra que la plataforma puede ser consumida desde Internet.

---

## 7. Prueba autenticada

Se realizó una prueba completa mediante la dirección pública.

Primero se registró un usuario utilizando:

POST /auth/register

Posteriormente se inició sesión mediante:

POST /auth/login

El servicio generó correctamente un token JWT.

Finalmente se realizó una petición autenticada a:

GET /cursos

Resultado:

HTTP 200

Respuesta:

[]

Aunque no existían cursos almacenados, el código 200 demuestra que:

1. La solicitud llegó desde Internet.
2. El Azure Load Balancer direccionó la solicitud al Gateway.
3. El Gateway validó el JWT.
4. El Gateway se comunicó correctamente con el microservicio de cursos.
5. El microservicio respondió correctamente.

---

## 8. Persistencia

PostgreSQL y RabbitMQ utilizan almacenamiento persistente.

PVC utilizados:

data-postgresql-0
data-rabbitmq-0

Ambos PVC quedaron en estado:

Bound

Capacidad:

1Gi

StorageClass utilizada:

default

En AKS esta StorageClass utiliza:

disk.csi.azure.com

Por lo tanto, el almacenamiento persistente es administrado mediante el CSI Driver de Azure Disk.

---

## 9. RabbitMQ y comunicación asíncrona

RabbitMQ se desplegó dentro del clúster.

El microservicio de inscripciones utiliza RabbitMQ para comunicación asíncrona.

También existe un proceso que genera resúmenes periódicos y los publica en RabbitMQ.

El consumer correspondiente permanece ejecutándose dentro del clúster.

---

## 10. CronJobs

Se desplegaron dos CronJobs.

### cron-insert

Frecuencia:

Cada 2 minutos.

Función:

Inserta periódicamente registros en PostgreSQL.

### cron-resumen

Frecuencia:

Cada 10 minutos.

Función:

Consulta información almacenada, genera un resumen y lo publica en RabbitMQ.

El CronJob cron-insert fue verificado mediante un Job que finalizó correctamente con estado Completed.

---

## 11. Secrets

Las credenciales sensibles fueron almacenadas mediante Kubernetes Secrets.

Se utilizaron variables para:

- DB_USER
- DB_PASSWORD
- JWT_SECRET
- RABBITMQ_USERNAME
- RABBITMQ_PASSWORD
- RABBITMQ_ERLANG_COOKIE

El archivo local:

charts/sa-platform/values-secret.yaml

fue agregado al archivo .gitignore para evitar versionar credenciales dentro del repositorio.

---

## 12. Diferencia entre Kubernetes local y Kubernetes administrado

En un clúster local, como Minikube o Docker Desktop, el estudiante debe encargarse directamente de ejecutar y administrar buena parte de la infraestructura.

En AKS, Azure administra principalmente el plano de control de Kubernetes.

Azure proporciona funcionalidades como:

- administración del control plane;
- integración con redes;
- almacenamiento administrado;
- balanceadores de carga;
- actualización del clúster;
- integración con Azure Container Registry.

El usuario continúa siendo responsable de los workloads, manifiestos, imágenes, configuraciones, Secrets y recursos utilizados.

---

## 13. Service LoadBalancer

Un Service de tipo LoadBalancer permite exponer una aplicación de Kubernetes hacia Internet.

Cuando Kubernetes detecta este tipo de Service en AKS, solicita al proveedor cloud la creación de un balanceador de carga.

En esta práctica Azure asignó automáticamente la dirección:

57.165.161.54

El tráfico recibido en esa dirección es enviado hacia los pods del Gateway.

---

## 14. Registry de imágenes

Un registry permite almacenar y distribuir imágenes de contenedores.

En esta práctica se utilizó Azure Container Registry porque el clúster AKS necesita descargar las imágenes desde una ubicación accesible en la nube.

AKS fue asociado al ACR para permitir que los nodos descargaran las imágenes privadas.

---

## 15. Responsabilidad del proveedor y del estudiante

### Azure administra

- Plano de control de Kubernetes.
- Infraestructura del servicio AKS.
- Integración con Load Balancer.
- Azure Disk CSI.
- Azure Container Registry.
- Componentes de red administrados.

### El estudiante administra

- Microservicios.
- Dockerfiles.
- Imágenes.
- Helm Charts.
- ConfigMaps.
- Secrets.
- Deployments.
- Services.
- CronJobs.
- RabbitMQ.
- PostgreSQL.
- Configuración de recursos.

---

## 16. Costos

El tier utilizado para el control plane de AKS fue Free.

Sin embargo, esto no significa que toda la infraestructura sea gratuita.

Los principales recursos que pueden generar costo son:

- máquinas virtuales de los nodos;
- Azure Container Registry;
- discos persistentes;
- Load Balancer;
- dirección IP pública;
- transferencia de datos.

Para minimizar el costo se utilizaron únicamente dos nodos pequeños y recursos limitados para cada pod.

Después de obtener las evidencias necesarias se deben eliminar los recursos creados para evitar cargos innecesarios.

---


### Estimación aproximada

Para esta práctica se utilizó el plan gratuito del control plane de AKS y una infraestructura pequeña de dos nodos. Considerando que los recursos estuvieron activos únicamente durante unas pocas horas, el costo generado se estima en menos de USD 1 para el período utilizado.

La cuenta utilizada dispone de créditos educativos de Azure, por lo que el consumo de la práctica puede ser cubierto por dichos créditos.

La estimación puede variar según el tiempo exacto de ejecución, almacenamiento, transferencia de datos y precios vigentes de Azure. Para reducir costos, el clúster fue detenido después de obtener las evidencias y será eliminado definitivamente después de la evaluación.

## 17. Limpieza de recursos

Después de finalizar la práctica se debe eliminar el grupo de recursos completo.

Comando:

az group delete --name rg-sa-p6 --yes --no-wait

Al eliminar el grupo de recursos también se eliminan:

- AKS
- nodos
- Azure Container Registry
- Load Balancer
- IP pública
- discos
- recursos de red relacionados

Posteriormente se debe verificar que el grupo de recursos ya no exista.

---

## 18. Evidencias

Las evidencias de la práctica se encuentran en la carpeta:

evidencias/

Se incluyen capturas de:

- Release de Helm en estado deployed.
- Pods en ejecución.
- Dos nodos AKS en estado Ready.
- Gateway con IP pública.
- Prueba HTTP 200 del endpoint /health.
- Prueba autenticada con JWT.
- PVC en estado Bound.
- StorageClasses de Azure.
- CronJobs.
- Azure Container Registry.
- Eliminación de los recursos.

