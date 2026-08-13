# Propuesta de API Gateway

## Herramienta seleccionada: AWS API Gateway

## Responsabilidades

1. **Enrutamiento (Routing)**: Redirige las solicitudes al microservicio correspondiente según la URL.

   | Ruta | Microservicio destino |
   |------|----------------------|
   | `/auth/*` | Servicio Autenticación |
   | `/transacciones/*` | Servicio Transacciones |
   | `/historial/*` | Servicio Historial |
   | `/notificaciones/*` | Servicio Notificaciones |

2. **Autenticación y autorización**:
   - Valida el token JWT de OAuth en cada solicitud.
   - Si el token expiró (12h), rechaza la solicitud con HTTP 401.
   - Se integra con el módulo de la Práctica 2 para validar roles (Admin/Cliente).

3. **Rate Limiting (Límite de solicitudes)**:
   - Cada cliente puede hacer hasta **100 solicitudes por minuto**.
   - Si se excede, se devuelve HTTP 429 (Too Many Requests).

4. **Logging y monitoreo**:
   - Registra cada solicitud entrante en CloudWatch.
   - Permite rastrear solicitudes por `requestId`.

5. **Transformación de respuestas**:
   - Convierte errores internos de los microservicios en respuestas HTTP estandarizadas.