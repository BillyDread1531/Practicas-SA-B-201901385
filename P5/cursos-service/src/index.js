const express = require("express");
const cors = require("cors");
const pool = require("./config/db");
const cursosRoutes = require("./routes/cursos.routes");
const logger = require("./telemetry/logger");
const { register, metricsMiddleware } = require("./telemetry/metrics");

const app = express();

app.use(cors());
app.use(express.json());
app.use(metricsMiddleware("cursos-service"));

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "ok",
    service: "cursos-service",
  });
});

app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

app.get("/", (req, res) => {
  res.json({
    servicio: "cursos-service",
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
    });
  }
});

app.use("/cursos", cursosRoutes);

const PORT = process.env.PORT || 3002;

app.listen(PORT, () => {
  logger.info({ msg: `cursos-service ejecutándose en puerto ${PORT}` });
});
