# Documentación de Prompts de IA

Este archivo documenta el uso de herramientas de Inteligencia Artificial generativa durante el desarrollo de la práctica: los prompts utilizados, la respuesta literal obtenida, y la revisión crítica que apliqué a cada una.

---

## Prompt 1: Generar la capa de repositorio (acceso a datos)

**Prompt utilizado:**
> "Tengo mi tabla solicitudes_operativas en PostgreSQL ya conectada con pg. Hazme el repositorio con las 5 operaciones: listar todas, crear, actualizar completo, actualizar solo el estado, y eliminar. Que use consultas parametrizadas para evitar inyección SQL, y que el código sea limpio, con nombres descriptivos y sin repetir lógica."

**Respuesta obtenida (código generado por la IA):**

```javascript
const pool = require('../config/db');

const findAll = async () => {
  const result = await pool.query('SELECT * FROM solicitudes_operativas ORDER BY id ASC');
  return result.rows;
};

const findById = async (id) => {
  const result = await pool.query(
    'SELECT * FROM solicitudes_operativas WHERE id = $1',
    [id]
  );
  return result.rows[0];
};

const create = async (data) => {
  const { titulo, area_solicitante, prioridad, costo_estimado, estado } = data;
  const result = await pool.query(
    `INSERT INTO solicitudes_operativas
      (titulo, area_solicitante, prioridad, costo_estimado, estado)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [titulo, area_solicitante, prioridad, costo_estimado, estado]
  );
  return result.rows[0];
};

const updateFull = async (id, data) => {
  const { titulo, area_solicitante, prioridad, costo_estimado, estado } = data;
  const result = await pool.query(
    `UPDATE solicitudes_operativas
     SET titulo = $1, area_solicitante = $2, prioridad = $3,
         costo_estimado = $4, estado = $5
     WHERE id = $6
     RETURNING *`,
    [titulo, area_solicitante, prioridad, costo_estimado, estado, id]
  );
  return result.rows[0];
};

const updateEstado = async (id, estado) => {
  const result = await pool.query(
    `UPDATE solicitudes_operativas SET estado = $1 WHERE id = $2 RETURNING *`,
    [estado, id]
  );
  return result.rows[0];
};

const remove = async (id) => {
  const result = await pool.query(
    'DELETE FROM solicitudes_operativas WHERE id = $1 RETURNING *',
    [id]
  );
  return result.rows[0];
};

module.exports = { findAll, findById, create, updateFull, updateEstado, remove };
```

**Ajustes que hice sobre esta respuesta:**

Cambié `SELECT *` por las columnas explícitas en `findAll` y `findById`, para controlar exactamente qué datos expone mi API en vez de depender de todas las columnas que tenga la tabla:

```javascript
const findAll = async () => {
  const result = await pool.query(
    'SELECT id, titulo, area_solicitante, prioridad, costo_estimado, estado FROM solicitudes_operativas ORDER BY id ASC'
  );
  return result.rows;
};
```

También renombré el archivo y mantuve mi convención de nombres en inglés (`requests.repository.js`) en vez de la que trae la respuesta por defecto, para que fuera consistente con el resto de carpetas que ya tenía creadas en el proyecto (`requests.controller.js`, `requests.service.js`, `requests.routes.js`).

---

## Prompt 2: Generar la capa de servicio (validaciones y reglas de negocio)

**Prompt utilizado:**
> "Ahora hazme la capa de servicio. Necesito que valide los datos antes de guardarlos: prioridad entera entre 1 y 5, costo estimado no negativo, y estado solo puede ser registrada, en_proceso o finalizada. Si el dato es inválido debe lanzar un error distinto a cuando algo no existe, y quiero manejo de errores claro, no que truene el programa."

**Respuesta obtenida (código generado por la IA):**

```javascript
class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ValidationError';
  }
}

class NotFoundError extends Error {
  constructor(message) {
    super(message);
    this.name = 'NotFoundError';
  }
}

function validarDatosCompletos(data) {
  const { titulo, area_solicitante, prioridad, costo_estimado, estado } = data;

  if (!Number.isInteger(prioridad) || prioridad < 1 || prioridad > 5) {
    throw new ValidationError('La prioridad debe ser un número entero entre 1 y 5.');
  }
  if (typeof costo_estimado !== 'number' || costo_estimado < 0) {
    throw new ValidationError('El costo estimado debe ser un número mayor o igual a 0.');
  }
  if (!['registrada', 'en_proceso', 'finalizada'].includes(estado)) {
    throw new ValidationError('Estado inválido.');
  }
}
```

**Ajustes que hice sobre esta respuesta:**

Le agregué la propiedad `statusCode` a ambas clases de error, porque mi middleware de errores (`error.middleware.js`), que ya tenía armado desde antes de pedir este prompt, lee `error.statusCode` directamente y la respuesta original no la incluía:

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

Sin este ajuste, mi middleware hubiera recibido el error pero sin saber qué código HTTP devolver, y todo hubiera respondido con 500 en vez del código correcto (400 o 404). Lo confirmé probando a propósito casos que debían fallar (prioridad 9, estado "cancelada", id inexistente) y viendo que el código de respuesta fuera el esperado.

---

## Prompt 3: Generar el controlador y conectar las rutas

**Prompt utilizado:**
> "Hazme el controlador que conecte el servicio con Express, y las rutas para los 5 endpoints: obtener todas, obtener por id, crear, actualizar completo, actualizar solo el estado, y eliminar. Usa códigos de estado HTTP correctos para cada caso."

**Respuesta obtenida (código generado por la IA):**

```javascript
// controlador
const requestsService = require('../services/requests.service');

const getAll = async (req, res) => {
  const solicitudes = await requestsService.getAll();
  res.status(200).json(solicitudes);
};

const create = async (req, res) => {
  const nueva = await requestsService.create(req.body);
  res.status(201).json(nueva);
};

const remove = async (req, res) => {
  const { id } = req.params;
  await requestsService.remove(id);
  res.status(204).send();
};
// ...(resto de funciones similares)

module.exports = { getAll, create, remove /* ...resto */ };
```

```javascript
// rutas
const { Router } = require('express');
const asyncHandler = require('../utils/asyncHandler');
const requestsController = require('../controllers/requests.controller');

const router = Router();
router.get('/', asyncHandler(requestsController.getAllRequests));

module.exports = router;
```

**Ajustes que hice sobre esta respuesta:**

Al conectar las rutas con mi controlador, me di cuenta de que había una inconsistencia entre ambos archivos: la ruta llamaba a `requestsController.getAllRequests`, pero mi controlador exportaba la función como `getAll`. Sin corregir esto, la ruta hubiera fallado en cuanto la ejecutara, porque `getAllRequests` sería `undefined`. Lo corregí así:

```javascript
router.get('/', asyncHandler(requestsController.getAll));
router.get('/:id', asyncHandler(requestsController.getById));
router.post('/', asyncHandler(requestsController.create));
router.put('/:id', asyncHandler(requestsController.updateFull));
router.patch('/:id/estado', asyncHandler(requestsController.updateEstado));
router.delete('/:id', asyncHandler(requestsController.remove));
```

También completé las rutas que faltaban, porque la respuesta original solo traía la de listar todas. Después de este ajuste, probé cada endpoint con peticiones HTTP reales en Postman, confirmando los códigos de estado: 200 en lecturas y actualizaciones, 201 al crear, 204 al eliminar, y 404 cuando pedí un id que ya había borrado.

---

## Reflexión general sobre el uso de IA

Usar IA me ayudó a avanzar más rápido con el código base de cada capa, pero en ningún caso la respuesta encajó al cien por ciento con lo que ya tenía armado en el proyecto: tuve que ajustar nombres de archivos y funciones, agregar propiedades que mi propio código ya esperaba (como el `statusCode`), completar partes que quedaron incompletas, y corregir al menos un error real (el de `getAllRequests`) que hubiera hecho fallar la aplicación si lo dejaba tal cual. En todos los casos probé el código con datos reales, incluyendo casos que debían fallar a propósito, antes de dar por terminada cada parte.
