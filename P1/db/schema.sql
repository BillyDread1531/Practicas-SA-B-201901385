CREATE TABLE IF NOT EXISTS solicitudes_operativas (
  id SERIAL PRIMARY KEY,
  titulo VARCHAR(150) NOT NULL,
  area_solicitante VARCHAR(150) NOT NULL,
  prioridad SMALLINT NOT NULL CHECK (prioridad BETWEEN 1 AND 5),
  costo_estimado NUMERIC(12,2) NOT NULL CHECK (costo_estimado >= 0),
  estado VARCHAR(20) NOT NULL CHECK (estado IN ('registrada', 'en_proceso', 'finalizada'))
);