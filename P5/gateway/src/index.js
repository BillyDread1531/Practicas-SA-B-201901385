const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const jwt = require("jsonwebtoken");
const { createProxyMiddleware } = require("http-proxy-middleware");
const logger = require("./telemetry/logger");
const { register, metricsMiddleware } = require("./telemetry/metrics");

dotenv.config();

const app = express();

// ---------------------------------------------------------------------------
// Inyeccion de fallo para la Practica 10 (distinta a la de P8 y a la del
// toggle de auth-service: esta es la que gobierna la demo del CANARY, porque
// el gateway es el unico Rollout con analysis de Argo Rollouts).
//
// Se activa SOLO cambiando CANARY_FAULT_INJECTION=true en el ConfigMap del
// chart del gateway. Eso cambia el checksum/config del pod template, Argo
// Rollouts lo trata como una revision nueva (canary) y SOLO esos pods nuevos
// quedan con el fallo activo; los pods estables de la revision anterior
// conservan su configuracion original. El AnalysisTemplate mide error-rate
// y p95 de latencia filtrando por el hash de esa revision (canary), asi que
// detecta el fallo sin tocar el trafico estable.
// ---------------------------------------------------------------------------
const CANARY_FAULT_INJECTION = process.env.CANARY_FAULT_INJECTION === "true";
const CANARY_FAULT_ERROR_RATE = Number(process.env.CANARY_FAULT_ERROR_RATE || 0.5);
const CANARY_FAULT_LATENCY_MS = Number(process.env.CANARY_FAULT_LATENCY_MS || 2000);

function chaosMiddleware(req, res, next) {
  if (!CANARY_FAULT_INJECTION || req.path === "/health" || req.path === "/metrics") {
    return next();
  }
  setTimeout(() => {
    if (Math.random() < CANARY_FAULT_ERROR_RATE) {
      logger.error({
        path: req.path,
        msg: "fallo inducido (CANARY_FAULT_INJECTION) en el gateway",
      });
      return res.status(503).json({ mensaje: "Servicio no disponible" });
    }
    next();
  }, CANARY_FAULT_LATENCY_MS);
}

app.use(cors());
app.use(metricsMiddleware("gateway"));
app.use(chaosMiddleware);

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "ok",
    service: "gateway",
  });
});

app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

// Ruta pública del Gateway
app.get("/", (req, res) => {
  res.json({
    servicio: "api-gateway",
    estado: "funcionando",
  });
});

// Middleware para validar JWT
function verificarToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({
      mensaje: "Token requerido",
    });
  }

  const partes = authHeader.split(" ");

  if (partes.length !== 2 || partes[0] !== "Bearer") {
    return res.status(401).json({
      mensaje: "Formato de token inválido",
    });
  }

  const token = partes[1];

  try {
    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET
    );

    req.usuario = decoded;

    next();
  } catch (error) {
    return res.status(401).json({
      mensaje: "Token inválido o expirado",
    });
  }
}

// AUTH: público
app.use(
  "/auth",
  createProxyMiddleware({
    target: process.env.AUTH_SERVICE,
    changeOrigin: true,
    pathRewrite: (path) => `/auth${path}`,
  })
);

// CURSOS: protegido
app.use(
  "/cursos",
  verificarToken,
  createProxyMiddleware({
    target: process.env.CURSOS_SERVICE,
    changeOrigin: true,
    pathRewrite: (path) => `/cursos${path}`,
  })
);

// INSCRIPCIONES: protegido
app.use(
  "/inscripciones",
  verificarToken,
  createProxyMiddleware({
    target: process.env.INSCRIPCIONES_SERVICE,
    changeOrigin: true,
    pathRewrite: () => "/graphql",
  })
);

// ESTUDIANTES: protegido
app.use(
  "/estudiantes",
  verificarToken,
  createProxyMiddleware({
    target: process.env.ESTUDIANTES_SERVICE,
    changeOrigin: true,
    pathRewrite: () => "/graphql",
  })
);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  logger.info({ msg: `API Gateway ejecutándose en puerto ${PORT}` });
});
