const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const pool = require("../config/db");
const logger = require("../telemetry/logger");
const { usuariosRegistradosTotal } = require("../telemetry/metrics");

const router = express.Router();

// ---------------------------------------------------------------------------
// Inyeccion de fallo para la Practica 10 (distinta a la de la Practica 8).
// Se activa SOLO poniendo FAULT_INJECTION=true en el ConfigMap del Helm
// chart; como eso cambia el checksum/config del pod template, Argo Rollouts
// lo despliega como una revision nueva (canary) sin tocar los pods estables
// de la revision anterior. Asi el fallo queda aislado al canary y el
// AnalysisTemplate por Prometheus lo mide SOLO ahi.
// ---------------------------------------------------------------------------
const FAULT_INJECTION = process.env.FAULT_INJECTION === "true";
const FAULT_ERROR_RATE = Number(process.env.FAULT_ERROR_RATE || 0.4);
const FAULT_EXTRA_LATENCY_MS = Number(process.env.FAULT_EXTRA_LATENCY_MS || 1500);

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

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

    usuariosRegistradosTotal.inc();

    logger.info({ email, msg: "usuario registrado" });

    res.status(201).json({
      mensaje: "Usuario registrado correctamente",
      usuario: resultado.rows[0],
    });
  } catch (error) {
    logger.error({ err: error.message, msg: "error en /auth/register" });

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

    if (FAULT_INJECTION) {
      await sleep(FAULT_EXTRA_LATENCY_MS);
      if (Math.random() < FAULT_ERROR_RATE) {
        logger.error({
          email,
          msg: "fallo inducido (FAULT_INJECTION) en /auth/login",
        });
        return res.status(500).json({
          mensaje: "Error interno del servidor",
        });
      }
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

    logger.info({ email, msg: "inicio de sesion correcto" });

    res.json({
      mensaje: "Inicio de sesión correcto",
      token,
    });
  } catch (error) {
    logger.error({ err: error.message, msg: "error en /auth/login" });

    res.status(500).json({
      mensaje: "Error interno del servidor",
    });
  }
});

module.exports = router;