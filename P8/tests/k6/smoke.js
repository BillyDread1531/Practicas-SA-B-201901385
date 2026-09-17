import http from "k6/http";
import { check, sleep } from "k6";

const BASE_URL = __ENV.BASE_URL || "http://localhost:3000";

export const options = {
  thresholds: {
    http_req_failed: ["rate<0.05"],
    http_req_duration: ["p(95)<1000"],
  },
  scenarios: {
    smoke: {
      executor: "constant-vus",
      vus: 1,
      duration: "10s",
    },
  },
};

export default function () {
  const response = http.get(`${BASE_URL}/health`);

  check(response, {
    "health responde HTTP 200": (r) => r.status === 200,
    "health contiene status": (r) =>
      r.body && r.body.includes("status"),
  });

  sleep(1);
}
