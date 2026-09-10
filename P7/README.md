
# Práctica 7 - Integración y Despliegue Continuo

## 1. Descripción

En esta práctica se implementó un flujo de integración y despliegue continuo utilizando GitHub Actions sobre la plataforma de microservicios desarrollada en las prácticas anteriores.

El objetivo fue automatizar el proceso que anteriormente se realizaba manualmente: validar el código, ejecutar pruebas, construir las imágenes Docker, publicarlas en un registro de contenedores y desplegar la aplicación en un clúster de Kubernetes.

Se reutilizó el clúster de Azure Kubernetes Service creado en la Práctica 6.

## 2. Tecnologías utilizadas

- GitHub Actions
- Docker
- GitHub Container Registry (GHCR)
- Microsoft Azure
- Azure Kubernetes Service (AKS)
- Kubernetes
- Helm
- Node.js
- Python
- PostgreSQL
- RabbitMQ

## 3. Microservicios utilizados

La plataforma contiene los siguientes componentes:

- auth-service
- cursos-service
- estudiantes-service
- inscripciones-service
- gateway
- cronjobs
- PostgreSQL
- RabbitMQ

Los servicios desarrollados en Node.js son:

- auth-service
- cursos-service
- gateway

Los servicios estudiantes e inscripciones utilizan Python.

## 4. Flujo CI/CD

El pipeline fue implementado en:


.github/workflows/p7-ci-cd.yml