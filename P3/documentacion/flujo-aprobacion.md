# Flujo de aprobación de 3 pasos (Maker-Checker-Authorizer)

## Roles

1. **Maker (Creador)**: Usuario que carga el archivo CSV con las transacciones. Es responsable de la carga inicial y de asegurar que los datos tengan el formato correcto.

2. **Checker (Revisor)**: Usuario que revisa el lote cargado por el Maker. Verifica que las transacciones cumplan con las reglas de negocio básicas (saldo, límites, cuentas válidas). Puede aprobar o rechazar el lote.

3. **Authorizer (Autorizador)**: Usuario con mayor nivel de autoridad que revisa el lote después del Checker. Realiza una validación final (prevención de fraude, límites superiores) y autoriza el envío al core bancario.

## Flujo

1. El Maker sube el archivo CSV → el sistema lo parsea y lo almacena.
2. El sistema valida automáticamente reglas básicas y cambia el estado a `pendiente_checker`.
3. El Checker revisa el lote. Si lo aprueba → pasa a `pendiente_authorizer`. Si lo rechaza → el lote vuelve a `rechazado` y se notifica al Maker.
4. El Authorizer revisa el lote. Si lo aprueba → pasa a `aprobado` y se dispara el evento de notificación. Si lo rechaza → el lote vuelve a `rechazado` y se notifica al Maker y al Checker.
5. Una vez aprobado, el lote se envía al sistema core bancario.

## Rechazo en cualquier etapa

Si el Checker o el Authorizer rechazan el lote, el sistema:
- Registra el motivo del rechazo.
- Notifica por correo al Maker y al Checker (si aplica).
- Permite que el Maker corrija el archivo y lo vuelva a subir como un nuevo lote.