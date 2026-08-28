import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "20s", target: 50 },
    { duration: "30s", target: 150 },
    { duration: "40s", target: 300 },
    { duration: "20s", target: 100 },
    { duration: "10s", target: 0 }
  ],

  thresholds: {
    http_req_failed: ["rate<0.05"],
    http_req_duration: ["p(95)<1000"]
  }
};

export default function () {
  const res = http.get(
    "http://host.docker.internal:8080/health",
    {
      headers: {
        Host: "academia.local"
      }
    }
  );

  check(res, {
    "status 200": (r) => r.status === 200
  });

  sleep(0.05);
}
