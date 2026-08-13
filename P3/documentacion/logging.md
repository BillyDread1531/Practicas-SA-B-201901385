# Estrategia de logging centralizado

## Herramienta seleccionada: ELK Stack (Elasticsearch, Logstash, Kibana)

- **Elasticsearch**: Almacena y permite consultar los logs.
- **Logstash**: Procesa y transforma los logs antes de enviarlos a Elasticsearch.
- **Kibana**: Interfaz web para visualizar y consultar los logs.

## Qué eventos se registran
- Inicios de sesión (éxito/fracaso).
- Acciones de los usuarios sobre lotes (carga, aprobación, rechazo).
- Cambios de estado en los lotes.
- Envíos al core bancario (éxito/fracaso).
- Errores de validación.
- Excepciones y errores del sistema.

## Formato de los logs
```json
{
  "timestamp": "2026-08-12T14:30:00Z",
  "servicio": "ServicioTransacciones",
  "nivel": "INFO",
  "usuario": "maker1",
  "accion": "APROBACION_LOTE",
  "idLote": "123e4567-e89b-12d3-a456-426614174000",
  "estado": "pendiente_authorizer",
  "ipOrigen": "192.168.1.100",
  "requestId": "abc-123"
}
```

## Retención
Logs de 7 días: almacenamiento en caliente (Elasticsearch).

Logs de 30 días: almacenamiento en frío (AWS S3).

Logs de >30 días: se archivan en S3 Glacier.

Consultas
Kibana permite consultas por:

Rango de fechas.

Usuario.

Servicio.

ID de lote o transacción.

Nivel de log (ERROR, WARN, INFO).
