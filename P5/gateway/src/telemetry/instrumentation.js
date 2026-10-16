// Ver P5/auth-service/src/telemetry/instrumentation.js para la explicacion
// completa. En el gateway esto es lo que hace que el header "traceparent"
// se inyecte automaticamente en cada peticion que http-proxy-middleware
// reenvia a auth-service y cursos-service (instrumentacion automatica del
// modulo http de Node): la traza se continua de extremo a extremo bajo un
// unico trace_id sin tocar el codigo del proxy.
const { NodeSDK } = require("@opentelemetry/sdk-node");
const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const { resourceFromAttributes } = require("@opentelemetry/resources");
const {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
} = require("@opentelemetry/semantic-conventions");

const serviceName = process.env.OTEL_SERVICE_NAME || "gateway";
const collectorUrl =
  process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://otel-collector:4318";

const sdk = new NodeSDK({
  resource: resourceFromAttributes({
    [ATTR_SERVICE_NAME]: serviceName,
    [ATTR_SERVICE_VERSION]: process.env.IMAGE_VERSION || "dev",
    "deployment.environment": process.env.NODE_ENV || "development",
  }),
  traceExporter: new OTLPTraceExporter({
    url: `${collectorUrl}/v1/traces`,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      "@opentelemetry/instrumentation-fs": { enabled: false },
    }),
  ],
});

sdk.start();

process.on("SIGTERM", () => {
  sdk.shutdown().finally(() => process.exit(0));
});

module.exports = sdk;
