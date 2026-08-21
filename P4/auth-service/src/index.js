const express = require("express");
const cors = require("cors");
const pool = require("./config/db");
const authRoutes = require("./routes/auth.routes");

const app = express();

app.use(cors());
app.use(express.json());

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
    console.error("ERROR DB:");
    console.error(error);

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
  console.log(`auth-service ejecutándose en puerto ${PORT}`);
});