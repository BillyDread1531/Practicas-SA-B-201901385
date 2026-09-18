# Evidencia de pruebas k6

Scripts disponibles:

- [Smoke](../tests/k6/smoke.js)
- [Integration](../tests/k6/integration.js)
- [Load](../tests/k6/load.js)

Los scripts definen las validaciones y umbrales usados por el AnalysisTemplate.

## Ejecución realizada

- Comando: `k6 run tests/k6/load.js`
- URL: `http://48.214.226.24:3000`
- Duración: 1 minuto
- VUs máximos: 10
- Iteraciones: 3,577
- Checks correctos: 100% (3,577 de 3,577)
- `http_req_failed`: 0.00%
- `http_req_duration` p95: 102.38 ms
- Umbral p95: menor que 1000 ms
- Resultado: PASS

Reporte completo: [06-k6-load.txt](06-k6-load.txt)
Resumen JSON: [k6-load-summary.json](k6-load-summary.json)
