const requestsService = require('../services/requests.service');

const getAll = async (req, res) => {
  const solicitudes = await requestsService.getAll();
  res.status(200).json(solicitudes);
};

const getById = async (req, res) => {
  const { id } = req.params;
  const solicitud = await requestsService.getById(id);
  res.status(200).json(solicitud);
};

const create = async (req, res) => {
  const nueva = await requestsService.create(req.body);
  res.status(201).json(nueva);
};

const updateFull = async (req, res) => {
  const { id } = req.params;
  const actualizada = await requestsService.updateFull(id, req.body);
  res.status(200).json(actualizada);
};

const updateEstado = async (req, res) => {
  const { id } = req.params;
  const { estado } = req.body;
  const actualizada = await requestsService.updateEstado(id, estado);
  res.status(200).json(actualizada);
};

const remove = async (req, res) => {
  const { id } = req.params;
  await requestsService.remove(id);
  res.status(204).send();
};

module.exports = {
  getAll,
  getById,
  create,
  updateFull,
  updateEstado,
  remove,
};