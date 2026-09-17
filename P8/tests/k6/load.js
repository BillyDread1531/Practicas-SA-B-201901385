import http from "k6/http";
import { check } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export const options = {
  thresholds: {
    http_req_failed: ["rate<0.05"],
    http_req_duration: ["p(95)<1000"],
  },
  scenarios: {
    load: {
      executor: "ramping-vus",
      startVUs: 1,
      stages: [
        { duration: "15s", target: 5 },
        { duration: "30s", target: 10 },
        { duration: "15s", target: 0 },
      ],
    },
  },
};

export default function () {
  const response = http.get(`${BASE_URL}/health`);

  check(response, {
    "health HTTP 200 bajo carga": (r) => r.status === 200,
  });
}
