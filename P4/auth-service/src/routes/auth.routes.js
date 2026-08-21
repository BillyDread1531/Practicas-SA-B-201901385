const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const pool = require("../config/db");

const router = express.Router();

router.post("/register", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        mensaje: "Email y password son obligatorios",
      });
    }

    const existe = await pool.query(
      "SELECT id FROM usuarios WHERE email = $1",
      [email]
    );

    if (existe.rows.length > 0) {
      return res.status(409).json({
        mensaje: "El usuario ya existe",
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const resultado = await pool.query(
      `INSERT INTO usuarios (email, password)
       VALUES ($1, $2)
       RETURNING id, email`,
      [email, passwordHash]
    );

    res.status(201).json({
      mensaje: "Usuario registrado correctamente",
      usuario: resultado.rows[0],
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      mensaje: "Error interno del servidor",
    });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        mensaje: "Email y password son obligatorios",
      });
    }

    const resultado = await pool.query(
      "SELECT * FROM usuarios WHERE email = $1",
      [email]
    );

    if (resultado.rows.length === 0) {
      return res.status(401).json({
        mensaje: "Credenciales incorrectas",
      });
    }

    const usuario = resultado.rows[0];

    const passwordValido = await bcrypt.compare(
      password,
      usuario.password
    );

    if (!passwordValido) {
      return res.status(401).json({
        mensaje: "Credenciales incorrectas",
      });
    }

    const token = jwt.sign(
      {
        id: usuario.id,
        email: usuario.email,
      },
      process.env.JWT_SECRET,
      {
        expiresIn: "2h",
      }
    );

    res.json({
      mensaje: "Inicio de sesión correcto",
      token,
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      mensaje: "Error interno del servidor",
    });
  }
});

module.exports = router;