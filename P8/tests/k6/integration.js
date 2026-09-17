import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export const options = {
  thresholds: {
    http_req_failed: ["rate<0.05"],
    http_req_duration: ["p(95)<1000"],
  },
  scenarios: {
    integration: {
      executor: "ramping-vus",
      startVUs: 1,
      stages: [
        { duration: "10s", target: 2 },
        { duration: "20s", target: 5 },
        { duration: "10s", target: 0 },
      ],
    },
  },
};

export default function () {
  const response = http.get(`${BASE_URL}/health`);

  check(response, {
    "gateway disponible": (r) => r.status === 200,
    "respuesta JSON valida": (r) => {
      try {
        JSON.parse(r.body);
        return true;
      } catch (_) {
        return false;
      }
    },
  });

  sleep(1);
}
