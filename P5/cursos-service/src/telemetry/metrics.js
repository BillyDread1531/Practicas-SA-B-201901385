// Ver P5/auth-service/src/telemetry/metrics.js para la explicacion completa.
// Metrica de negocio de este servicio: cursos_creados_total.
const client = require("prom-client");

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestDuration = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "Duracion de las peticiones HTTP en segundos",
  labelNames: ["method", "route", "status_code", "service"],
  buckets: [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  registers: [register],
});

const httpRequestsTotal = new client.Counter({
  name: "http_requests_total",
  help: "Total de peticiones HTTP recibidas",
  labelNames: ["method", "route", "status_code", "service"],
  registers: [register],
});

// --- Metrica de negocio ---
const cursosCreadosTotal = new client.Counter({
  name: "cursos_creados_total",
  help: "Cursos nuevos creados correctamente (metrica de negocio)",
  registers: [register],
});

function metricsMiddleware(serviceName) {
  return (req, res, next) => {
    const start = process.hrtime.bigint();
    res.on("finish", () => {
      const durationSec = Number(process.hrtime.bigint() - start) / 1e9;
      const route = req.route?.path
        ? `${req.baseUrl || ""}${req.route.path}`
        : req.path;
      const labels = {
        method: req.method,
        route,
        status_code: String(res.statusCode),
        service: serviceName,
      };
      httpRequestDuration.observe(labels, durationSec);
      httpRequestsTotal.inc(labels);
    });
    next();
  };
}

module.exports = {
  register,
  metricsMiddleware,
  cursosCreadosTotal,
};
