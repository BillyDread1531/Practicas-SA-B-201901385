# API REST - Solicitudes Operativas

Práctica del curso Software Avanzado, USAC. API REST para gestionar las solicitudes operativas de una academia ficticia, aplicando los principios SOLID y buenas prácticas de código limpio.

## Tecnologías utilizadas

- **Node.js** con **Express** para el servidor y las rutas
- **PostgreSQL** como base de datos, usando el cliente `pg`
- **nodemon** para desarrollo local (reinicia el servidor automáticamente al guardar cambios)

## Estructura del proyecto

```
P1/
├── db/
│   └── schema.sql
├── src/
│   ├── config/
│   │   └── db.js                  # conexión al pool de PostgreSQL
│   ├── controllers/
│   │   └── requests.controller.js # recibe la petición HTTP y responde
│   ├── middlewares/
│   │   └── error.middleware.js    # manejo centralizado de errores
│   ├── repositories/
│   │   └── requests.repository.js # consultas SQL puras
│   ├── routes/
│   │   ├── index.js
│   │   └── requests.routes.js
│   ├── services/
│   │   └── requests.service.js    # reglas de negocio y validaciones
│   ├── utils/
│   │   └── asyncHandler.js        # captura errores de funciones async
│   └── app.js
├── server.js
├── .env
└── .env.example
```

## Cómo levantar el proyecto

1. Instalar dependencias:
   ```bash
   npm install
   ```
2. Configurar el archivo `.env` en la raíz:
   ```dotenv
   PORT=3000
   DB_HOST=localhost
   DB_PORT=5432
   DB_USER=postgres
   DB_PASSWORD=<tu contraseña>
   DB_NAME=solicitudes_operativas
   ```
3. Crear la tabla en PostgreSQL con el script `db/schema.sql`.
4. Levantar el servidor:
   ```bash
   npm run dev
   ```
5. El servidor queda disponible en `http://localhost:3000`.

## Modelo de datos

Cada solicitud operativa tiene los siguientes campos:

| Campo | Tipo | Descripción |
|---|---|---|
| id | Entero | Identificador único, autogenerado |
| titulo | Texto | Nombre descriptivo de la solicitud |
| area_solicitante | Texto | Área o departamento que genera la solicitud |
| prioridad | Entero (1-5) | Nivel de urgencia |
| costo_estimado | Decimal | Costo aproximado de atender la solicitud |
| estado | Texto | `registrada`, `en_proceso` o `finalizada` |

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/v1/requests` | Obtiene todas las solicitudes |
| GET | `/api/v1/requests/:id` | Obtiene una solicitud por id |
| POST | `/api/v1/requests` | Registra una nueva solicitud |
| PUT | `/api/v1/requests/:id` | Actualiza completamente una solicitud existente |
| PATCH | `/api/v1/requests/:id/estado` | Actualiza únicamente el estado de una solicitud |
| DELETE | `/api/v1/requests/:id` | Elimina una solicitud |

---

## Aplicación de los principios SOLID

Cómo apliqué cada uno de los cinco principios SOLID en este proyecto, con fragmentos de código reales como evidencia.

### 1. Principio de responsabilidad única (S - Single Responsibility)

Este principio dice que una clase, función o módulo debe tener una sola razón para cambiar, es decir, debe encargarse de una única tarea. En este proyecto lo apliqué dividiendo el backend en capas, donde cada una tiene una única responsabilidad:

- **`requests.repository.js`** solo se encarga de hablar con la base de datos (ejecutar consultas SQL), sin saber nada de reglas de negocio ni de HTTP.
- **`requests.service.js`** solo se encarga de la lógica de negocio (validar datos, decidir si algo existe o no), sin saber cómo están escritas las consultas SQL.
- **`requests.controller.js`** solo se encarga de traducir entre HTTP y el servicio (leer `req`, devolver `res`), sin tener lógica de negocio ni SQL adentro.

Ejemplo, el repositorio solo ejecuta la consulta y devuelve el resultado, nada más:

```javascript
const findAll = async () => {
  const result = await pool.query(
    'SELECT id, titulo, area_solicitante, prioridad, costo_estimado, estado FROM solicitudes_operativas ORDER BY id ASC'
  );
  return result.rows;
};
```

Y el controlador solo se encarga de responder con el código HTTP correcto, sin meterse en cómo se obtuvieron los datos:

```javascript
const getAll = async (req, res) => {
  const solicitudes = await requestsService.getAll();
  res.status(200).json(solicitudes);
};
```

Si cambio una regla de validación, solo edito el service. Si cambio el motor de base de datos, solo edito el repository. Ningún cambio obliga a tocar las otras capas.

### 2. Principio de abierto/cerrado (O - Open/Closed)

Este principio dice que el código debe estar abierto a extensión pero cerrado a modificación, es decir, debería poder agregar comportamiento nuevo sin tener que reescribir el código que ya funciona.

En este proyecto lo apliqué en el middleware de manejo de errores. En vez de que cada controlador decida cómo responder ante un error, centralicé esa decisión en un único lugar que revisa el tipo de error:

```javascript
const errorMiddleware = (error, req, res, next) => {
  const statusCode = error.statusCode || 500;

  res.status(statusCode).json({
    message: error.message || 'Internal Server Error',
  });
};
```

Si en el futuro necesito agregar un nuevo tipo de error (por ejemplo, un error de autenticación), no tengo que modificar este middleware ni los controladores existentes: solo creo una nueva clase de error con su propio `statusCode`, y el middleware la va a manejar automáticamente porque lee esa propiedad de forma genérica, sin depender de una lista fija de tipos.

### 3. Principio de sustitución de Liskov (L - Liskov Substitution)

Este principio dice que si una parte del código espera un tipo de objeto, debería poder recibir cualquier variación de ese objeto sin que el programa se rompa o se comporte de forma inesperada.

En este proyecto lo apliqué en las clases de error personalizadas. Tanto `ValidationError` como `NotFoundError` extienden de la clase `Error` de JavaScript, y ambas se pueden usar en cualquier lugar donde el código espera un error normal, sin romper nada:

```javascript
class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ValidationError';
    this.statusCode = 400;
  }
}

class NotFoundError extends Error {
  constructor(message) {
    super(message);
    this.name = 'NotFoundError';
    this.statusCode = 404;
  }
}
```

### 4. Principio de segregación de interfaces (I - Interface Segregation)

Este principio dice que es mejor tener varias interfaces pequeñas y específicas, en vez de una sola interfaz grande que obligue a depender de cosas que no se necesitan.

En este proyecto lo apliqué exportando de cada módulo solo las funciones necesarias para ese contexto, en vez de un único objeto gigante con todo mezclado. Por ejemplo, el repositorio expone exactamente las operaciones necesarias para trabajar con solicitudes, ni más ni menos:

```javascript
module.exports = {
  findAll,
  findById,
  create,
  updateFull,
  updateEstado,
  remove,
};
```

El controlador solo importa el servicio (`requestsService`), y dentro de él solo usa las funciones puntuales que necesita en cada endpoint, sin depender de todo el módulo de golpe. Esto evita que un archivo dependa de funcionalidad que nunca va a usar.

### 5. Principio de inversión de dependencias (D - Dependency Inversion)

Este principio dice que los módulos de más alto nivel (la lógica de negocio) no deberían depender directamente de los módulos de bajo nivel (los detalles técnicos, como la base de datos), sino que ambos deberían depender de una abstracción.

En este proyecto lo apliqué haciendo que el service dependa únicamente de las funciones que expone el repository, sin conocer cómo están escritas las consultas SQL por dentro:

```javascript
const requestsRepository = require('../repositories/requests.repository');

const create = async (data) => {
  validarDatosCompletos(data);
  return requestsRepository.create(data);
};
```

El `service` no sabe si `requestsRepository.create` usa PostgreSQL, MySQL o cualquier otro motor — solo sabe que existe una función `create` que recibe datos y devuelve una solicitud creada. Si el día de mañana cambio la base de datos, solo tengo que reescribir el `repository` para que siga cumpliendo ese mismo contrato, sin tocar el `service` ni el `controller`.

---

## Manejo de errores y validaciones

Además de los principios SOLID, el proyecto valida los datos antes de guardarlos, evitando datos inconsistentes. Por ejemplo, la prioridad solo se acepta si es un número entero entre 1 y 5, y el estado solo se acepta si es uno de los tres valores permitidos:

```javascript
if (!Number.isInteger(prioridad) || prioridad < 1 || prioridad > 5) {
  throw new ValidationError('La prioridad debe ser un número entero entre 1 y 5.');
}
```

Esto se probó de forma explícita, confirmando que las peticiones inválidas responden con `400` (validación) o `404` (no encontrado) en vez de fallar de forma genérica con `500`.

## Seguridad

Todas las consultas a la base de datos usan parámetros (`$1, $2, $3...`) en vez de concatenar los valores directamente en el texto SQL. Esto evita inyección SQL, que es cuando alguien intenta enviar datos maliciosos disfrazados de texto normal para alterar la consulta:

```javascript
const result = await pool.query(
  'SELECT * FROM solicitudes_operativas WHERE id = $1',
  [id]
);
```

También se agregaron restricciones directamente en la base de datos (`CHECK`) para reforzar las reglas de negocio a nivel de PostgreSQL, no solo en el código de la aplicación:

```sql
prioridad SMALLINT NOT NULL CHECK (prioridad BETWEEN 1 AND 5),
costo_estimado NUMERIC(12,2) NOT NULL CHECK (costo_estimado >= 0),
estado VARCHAR(20) NOT NULL CHECK (estado IN ('registrada', 'en_proceso', 'finalizada'))
```

## Uso de Inteligencia Artificial

El detalle de los prompts utilizados durante el desarrollo, junto con las respuestas obtenidas y los ajustes aplicados, se encuentra documentado en [`PROMPTS.md`](./PROMPTS.md).
