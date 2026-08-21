const express = require("express");
const pool = require("../config/db");

const router = express.Router();

router.get("/", async (req, res) => {
  try {
    const resultado = await pool.query(
      "SELECT * FROM cursos ORDER BY id"
    );

    res.json(resultado.rows);
  } catch (error) {
    console.error(error);

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

    res.status(201).json({
      mensaje: "Curso creado correctamente",
      curso: resultado.rows[0],
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      mensaje: "Error al crear el curso",
    });
  }
});

module.exports = router;