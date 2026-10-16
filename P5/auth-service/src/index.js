const express = require("express");
const cors = require("cors");
const pool = require("./config/db");
const authRoutes = require("./routes/auth.routes");
const logger = require("./telemetry/logger");
const { register, metricsMiddleware } = require("./telemetry/metrics");

const app = express();

app.use(cors());
app.use(express.json());
app.use(metricsMiddleware("auth-service"));

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "ok",
    service: "auth-service",
  });
});

app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

app.get("/", (req, res) => {
  res.json({
    servicio: "auth-service",
    estado: "funcionando",
  });
});

app.get("/db-test", async (req, res) => {
  try {
    const resultado = await pool.query("SELECT NOW() AS fecha");

    res.json({
      conexion: "correcta",
      fecha: resultado.rows[0].fecha,
    });
  } catch (error) {
    logger.error({ err: error.message, msg: "error en /db-test" });

    res.status(500).json({
      conexion: "error",
      mensaje: error.message || "Error sin mensaje",
      codigo: error.code || null,
      detalle: error.detail || null,
      nombre: error.name || null,
    });
  }
});

app.use("/auth", authRoutes);

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
  logger.info({ msg: `auth-service ejecutándose en puerto ${PORT}` });
});
