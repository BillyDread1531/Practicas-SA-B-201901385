const pool = require('../config/db');

const findAll = async () => {
  const result = await pool.query(
    'SELECT id, titulo, area_solicitante, prioridad, costo_estimado, estado FROM solicitudes_operativas ORDER BY id ASC'
  );
  return result.rows;
};

const findById = async (id) => {
  const result = await pool.query(
    'SELECT id, titulo, area_solicitante, prioridad, costo_estimado, estado FROM solicitudes_operativas WHERE id = $1',
    [id]
  );
  return result.rows[0]; // undefined si no existe
};

const create = async (data) => {
  const { titulo, area_solicitante, prioridad, costo_estimado, estado } = data;
  const result = await pool.query(
    `INSERT INTO solicitudes_operativas
      (titulo, area_solicitante, prioridad, costo_estimado, estado)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, titulo, area_solicitante, prioridad, costo_estimado, estado`,
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
     RETURNING id, titulo, area_solicitante, prioridad, costo_estimado, estado`,
    [titulo, area_solicitante, prioridad, costo_estimado, estado, id]
  );
  return result.rows[0]; // undefined si ese id no existía
};

const updateEstado = async (id, estado) => {
  const result = await pool.query(
    `UPDATE solicitudes_operativas
     SET estado = $1
     WHERE id = $2
     RETURNING id, titulo, area_solicitante, prioridad, costo_estimado, estado`,
    [estado, id]
  );
  return result.rows[0];
};

const remove = async (id) => {
  const result = await pool.query(
    'DELETE FROM solicitudes_operativas WHERE id = $1 RETURNING id',
    [id]
  );
  return result.rows[0]; // undefined si no existía
};

module.exports = {
  findAll,
  findById,
  create,
  updateFull,
  updateEstado,
  remove,
};