// Ver P5/auth-service/src/telemetry/instrumentation.js para la explicacion
// completa. Mismo patron en los tres servicios instrumentados.
const { NodeSDK } = require("@opentelemetry/sdk-node");
const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const { resourceFromAttributes } = require("@opentelemetry/resources");
const {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
} = require("@opentelemetry/semantic-conventions");

const serviceName = process.env.OTEL_SERVICE_NAME || "cursos-service";
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
