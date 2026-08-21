const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const jwt = require("jsonwebtoken");
const { createProxyMiddleware } = require("http-proxy-middleware");

dotenv.config();

const app = express();

app.use(cors());

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
  console.log(`API Gateway ejecutándose en puerto ${PORT}`);
});