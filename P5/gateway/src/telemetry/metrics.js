// Ver P5/auth-service/src/telemetry/metrics.js. El gateway no agrega una
// metrica de negocio propia (ya hay 2: usuarios_registrados_total en
// auth-service y cursos_creados_total en cursos-service); aqui solo van las
// 4 senales de oro tecnicas, que es lo que el canary del gateway consulta.
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

function metricsMiddleware(serviceName) {
  return (req, res, next) => {
    const start = process.hrtime.bigint();
    res.on("finish", () => {
      const durationSec = Number(process.hrtime.bigint() - start) / 1e9;
      // En el gateway la ruta util es el primer segmento (/auth, /cursos, ...),
      // no el path completo reenviado, para no explotar la cardinalidad.
      const route = "/" + (req.path.split("/")[1] || "");
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
};
