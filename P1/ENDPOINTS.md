# Endpoints para Postman

Base URL:

```text
http://localhost:3000
```

## 1. Health

```text
GET http://localhost:3000/health
```

## 2. Obtener todos los requests

```text
GET http://localhost:3000/api/v1/requests
```

## 3. Obtener request por ID

```text
GET http://localhost:3000/api/v1/requests/1
```

## 4. Crear request

```text
POST http://localhost:3000/api/v1/requests
Content-Type: application/json

{
  "titulo": "Compra de laptop",
  "area_solicitante": "TI",
  "prioridad": 3,
  "costo_estimado": 2500,
  "estado": "registrada"
}
```

## 5. Actualizar request completo

```text
PUT http://localhost:3000/api/v1/requests/1
Content-Type: application/json

{
  "titulo": "Compra de laptop actualizada",
  "area_solicitante": "TI",
  "prioridad": 4,
  "costo_estimado": 2800,
  "estado": "en_proceso"
}
```

## 6. Cambiar solo el estado

```text
PATCH http://localhost:3000/api/v1/requests/1/estado
Content-Type: application/json

{
  "estado": "finalizada"
}
```

## 7. Eliminar request

```text
DELETE http://localhost:3000/api/v1/requests/1
```

## Valores permitidos

```text
estado: registrada | en_proceso | finalizada
prioridad: 1 a 5
costo_estimado: numero mayor o igual a 0
```