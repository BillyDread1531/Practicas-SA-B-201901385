// ---------------------------------------------------------------------------
// Bootstrap de OpenTelemetry. Debe cargarse ANTES de cualquier otro modulo
// (por eso el Dockerfile y "npm start" lo invocan con --require), para que
// la instrumentacion automatica pueda parchear http, express y pg antes de
// que esos modulos se importen en el resto del codigo.
//
// Traza: http + express + pg (con propagacion de contexto W3C automatica:
// el header "traceparent" viaja en cada llamada saliente y se continua en
// el servicio que la recibe). Exporta por OTLP/HTTP al Collector.
// ---------------------------------------------------------------------------
const { NodeSDK } = require("@opentelemetry/sdk-node");
const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const { resourceFromAttributes } = require("@opentelemetry/resources");
const {
  ATTR_SERVICE_NAME,
  ATTR_SERVICE_VERSION,
} = require("@opentelemetry/semantic-conventions");

const serviceName = process.env.OTEL_SERVICE_NAME || "auth-service";
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
      // Reduce ruido: no instrumentar el modulo fs (genera cientos de spans
      // irrelevantes por cada lectura de archivo del runtime de Node).
      "@opentelemetry/instrumentation-fs": { enabled: false },
    }),
  ],
});

sdk.start();

process.on("SIGTERM", () => {
  sdk.shutdown().finally(() => process.exit(0));
});

module.exports = sdk;
