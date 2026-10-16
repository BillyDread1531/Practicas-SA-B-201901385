// Ver P5/auth-service/src/telemetry/logger.js para la explicacion completa.
const pino = require("pino");
const { trace } = require("@opentelemetry/api");

const logger = pino({
  level: process.env.LOG_LEVEL || "info",
  formatters: {
    level(label) {
      return { level: label };
    },
    log(obj) {
      const span = trace.getActiveSpan();
      if (!span) return obj;
      const ctx = span.spanContext();
      return { ...obj, trace_id: ctx.traceId, span_id: ctx.spanId };
    },
  },
  base: {
    service: process.env.OTEL_SERVICE_NAME || "service",
  },
  timestamp: pino.stdTimeFunctions.isoTime,
});

module.exports = logger;
