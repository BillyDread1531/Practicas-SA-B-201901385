# Microservicios de la solución

## 1. Servicio de Autenticación
Responsabilidad: gestionar el inicio de sesión, la emisión de tokens OAuth
corporativos (vida de 12 horas) y el control de permisos y accesos.
Se integra con el módulo de autenticación desarrollado en la Práctica 2,
reutilizando su lógica de roles (Admin/Cliente) para determinar qué puede
hacer cada usuario dentro del flujo de aprobación.

## 2. Servicio de Transacciones
Responsabilidad: recibir los archivos CSV con transferencias, pagos y
depósitos en lote; validar las reglas de negocio (saldo disponible, límites
de transacción, cuentas válidas, prevención de fraude); controlar el flujo
de aprobación de 3 pasos (maker-checker-authorizer); enviar los lotes
aprobados al sistema core bancario; y mantener el historial consultable
de los lotes procesados (incluye contenido y opción de descarga).

## 3. Servicio de Notificaciones
Responsabilidad: escuchar el evento de aprobación final de un lote y enviar
un correo electrónico a todos los clientes/beneficiarios incluidos en ese
lote, informando que su transacción está en proceso.

## Logging centralizado (componente transversal)
No es un microservicio de negocio: los tres servicios anteriores envían sus
eventos a una herramienta de logging centralizado (por ejemplo ELK Stack o
CloudWatch), que permite auditar todo lo que ocurre en el sistema sin
acoplar esa responsabilidad a ningún servicio en particular.