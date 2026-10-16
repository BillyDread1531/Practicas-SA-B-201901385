const express = require("express");
const pool = require("../config/db");
const logger = require("../telemetry/logger");
const { cursosCreadosTotal } = require("../telemetry/metrics");

const router = express.Router();

router.get("/", async (req, res) => {
  try {
    const resultado = await pool.query(
      "SELECT * FROM cursos ORDER BY id"
    );

    res.json(resultado.rows);
  } catch (error) {
    logger.error({ err: error.message, msg: "error al obtener los cursos" });

    res.status(500).json({
      mensaje: "Error al obtener los cursos",
    });
  }
});

router.post("/", async (req, res) => {
  try {
    const { nombre, descripcion, creditos } = req.body;

    if (!nombre) {
      return res.status(400).json({
        mensaje: "El nombre del curso es obligatorio",
      });
    }

    const resultado = await pool.query(
      `INSERT INTO cursos (nombre, descripcion, creditos)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [nombre, descripcion || null, creditos || null]
    );

    cursosCreadosTotal.inc();

    logger.info({ curso: resultado.rows[0], msg: "curso creado" });

    res.status(201).json({
      mensaje: "Curso creado correctamente",
      curso: resultado.rows[0],
    });
  } catch (error) {
    logger.error({ err: error.message, msg: "error al crear el curso" });

    res.status(500).json({
      mensaje: "Error al crear el curso",
    });
  }
});

module.exports = router;
