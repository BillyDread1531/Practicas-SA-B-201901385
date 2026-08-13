# Tecnologías y patrones de diseño

## Tecnologías

| Componente | Tecnología | Justificación |
|------------|------------|---------------|
| API Gateway | AWS API Gateway | Administrada, escalable, integración nativa con AWS y IAM. |
| Servicios | Java + Spring Boot | Framework maduro, amplia adopción, integración con OAuth. |
| Bases de datos | PostgreSQL | ACID, soporte para JSON, fácil de escalar en la nube. |
| Mensajería | Apache Kafka | Alto rendimiento, particionado, durable, ideal para eventos. |
| Almacenamiento CSV | AWS S3 | Alta disponibilidad, integración con el resto de AWS. |
| Logging | ELK Stack | Potente para consultas y visualizaciones, open source. |
| Contenedores | Docker | Portabilidad y consistencia entre entornos (opcional). |
| Orquestación | Kubernetes | Escalabilidad y autogestión (opcional). |

## Patrones de diseño

1. **API Gateway Pattern**: Punto único de entrada para todos los clientes, centraliza autenticación, rate limiting y enrutamiento.

2. **Database per Service**: Cada microservicio tiene su propia base de datos. Permite independencia y evolución desacoplada.

3. **Event-Driven Architecture (EDA)**: Comunicación asíncrona mediante eventos (Kafka) para desacoplar servicios.

4. **Saga Pattern** (coreografía): Se utilizará para manejar transacciones distribuidas. Por ejemplo:
   - Paso 1: Validar lote.
   - Paso 2: Guardar en DB.
   - Paso 3: Publicar evento.
   - Paso 4: Si falla el envío al core, se publica evento de compensación.

5. **Circuit Breaker**: Para evitar fallos en cadena si el sistema core bancario no responde. Se implementará con Resilience4J o Hystrix.

6. **Strangler Pattern**: La migración del monolítico se hará de forma incremental, reemplazando funcionalidades una a una hasta que el monolítico quede obsoleto.