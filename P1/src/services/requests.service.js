const requestsRepository = require('../repositories/requests.repository');

const ESTADOS_VALIDOS = ['registrada', 'en_proceso', 'finalizada'];

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

function validarDatosCompletos(data) {
  const { titulo, area_solicitante, prioridad, costo_estimado, estado } = data;

  if (!titulo || typeof titulo !== 'string' || titulo.trim() === '') {
    throw new ValidationError('El título es obligatorio y debe ser texto.');
  }
  if (!area_solicitante || typeof area_solicitante !== 'string' || area_solicitante.trim() === '') {
    throw new ValidationError('El área solicitante es obligatoria y debe ser texto.');
  }
  if (!Number.isInteger(prioridad) || prioridad < 1 || prioridad > 5) {
    throw new ValidationError('La prioridad debe ser un número entero entre 1 y 5.');
  }
  if (typeof costo_estimado !== 'number' || costo_estimado < 0) {
    throw new ValidationError('El costo estimado debe ser un número mayor o igual a 0.');
  }
  if (!ESTADOS_VALIDOS.includes(estado)) {
    throw new ValidationError(`El estado debe ser uno de: ${ESTADOS_VALIDOS.join(', ')}.`);
  }
}

const getAll = async () => {
  return requestsRepository.findAll();
};

const getById = async (id) => {
  const solicitud = await requestsRepository.findById(id);
  if (!solicitud) {
    throw new NotFoundError(`No existe una solicitud con id ${id}.`);
  }
  return solicitud;
};

const create = async (data) => {
  validarDatosCompletos(data);
  return requestsRepository.create(data);
};

const updateFull = async (id, data) => {
  validarDatosCompletos(data);
  const actualizada = await requestsRepository.updateFull(id, data);
  if (!actualizada) {
    throw new NotFoundError(`No existe una solicitud con id ${id}.`);
  }
  return actualizada;
};

const updateEstado = async (id, estado) => {
  if (!ESTADOS_VALIDOS.includes(estado)) {
    throw new ValidationError(`El estado debe ser uno de: ${ESTADOS_VALIDOS.join(', ')}.`);
  }
  const actualizada = await requestsRepository.updateEstado(id, estado);
  if (!actualizada) {
    throw new NotFoundError(`No existe una solicitud con id ${id}.`);
  }
  return actualizada;
};

const remove = async (id) => {
  const eliminada = await requestsRepository.remove(id);
  if (!eliminada) {
    throw new NotFoundError(`No existe una solicitud con id ${id}.`);
  }
  return eliminada;
};

module.exports = {
  getAll,
  getById,
  create,
  updateFull,
  updateEstado,
  remove,
  ValidationError,
  NotFoundError,
};