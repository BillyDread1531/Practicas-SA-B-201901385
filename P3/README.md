# Práctica 3 — Diseño de Arquitectura de Microservicios

## Contexto
El banco actualmente tiene un sistema monolítico que presenta problemas de rendimiento en épocas de alta demanda. Esta práctica propone una arquitectura basada en microservicios para reemplazarlo.

---

## 📐 Diagramas

### Arquitectura General
![Arquitectura General](./diagramas/Arquitectura_general.jpg)

### Diagrama de Componentes
![Diagrama de Componentes](./diagramas/Diagrama_Componentes.jpg)

---

### Diagramas ER

| Microservicio | Diagrama |
|---------------|----------|
| Autenticación | ![ER Autenticacion](./diagramas/ER%20Autenticacion.jpg) |
| Transacciones | ![ER Transacciones](./diagramas/ER%20Transacciones.jpg) |
| Notificaciones | ![ER Notificaciones](./diagramas/ER%20Notificaciones.jpg) |

---

### Diagramas de Clases UML

| Microservicio | Diagrama |
|---------------|----------|
| Autenticación | ![Clases Autenticacion](./diagramas/Clases%20Autenticacion.jpg) |
| Transacciones | ![Clases Transacciones](./diagramas/Clases%20Transacciones.jpg) |
| Notificaciones | ![Clases Notificaciones](./diagramas/Clases%20Notificaciones.jpg) |

---

### Diagramas de Secuencia UML

| Flujo | Diagrama |
|-------|----------|
| Aprobación 3 pasos | ![Secuencia Aprobacion](./diagramas/Secuencia%20Aprobacion%203%20pasos.jpg) |
| Envío al Core Bancario | ![Secuencia Core](./diagramas/Secuencia%20Envio%20Core.jpg) |
| Notificación a Clientes | ![Secuencia Notificacion](./diagramas/Secuencia%20Notificacion.jpg) |

---

## 📄 Documentación

- [Microservicios](./documentacion/microservicios.md)
- [Flujo de aprobación](./documentacion/flujo-aprobacion.md)
- [Estrategia de almacenamiento CSV](./documentacion/almacenamiento-csv.md)
- [Estrategia de logging centralizado](./documentacion/logging.md)
- [Comunicación entre servicios](./documentacion/comunicacion-servicios.md)
- [Propuesta de API Gateway](./documentacion/api-gateway.md)
- [Tecnologías y patrones](./documentacion/tecnologias-patrones.md)

---

## 🛠️ Tecnologías y patrones
Ver [`documentacion/tecnologias-patrones.md`](./documentacion/tecnologias-patrones.md)