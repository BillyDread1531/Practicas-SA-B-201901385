

# Comunicación entre servicios

## Comunicación síncrona (REST)
**API Gateway** actúa como punto de entrada único y redirige las solicitudes a los servicios correspondientes.

- **Cliente → API Gateway → Servicio de Autenticación**: para login y verificación de tokens.
- **Cliente → API Gateway → Servicio de Transacciones**: para cargar CSV, consultar historial, etc.
- **Cliente → API Gateway → Servicio de Historial**: para consultar lotes anteriores.

## Comunicación asíncrona (mensajería)
Se utiliza **Apache Kafka** para desacoplar servicios y manejar picos de carga.

**Topología de eventos:**

| Evento | Publicador | Consumidor(es) | Propósito |
|--------|------------|----------------|-----------|
| `lote.aprobado` | Servicio Transacciones | Servicio Notificaciones, Servicio Historial | Notificar a clientes y guardar en historial |
| `lote.rechazado` | Servicio Transacciones | Servicio Notificaciones | Notificar a Maker/Checker |
| `core.confirmacion` | Sistema Core Bancario | Servicio Transacciones | Confirmar recepción del lote |

**Ventajas del enfoque asíncrono:**
- El Servicio de Transacciones no queda bloqueado esperando que se envíen los correos.
- Permite reintentos automáticos si el Servicio de Notificaciones falla.
- Escalabilidad: se pueden agregar más consumidores si hay alta demanda.