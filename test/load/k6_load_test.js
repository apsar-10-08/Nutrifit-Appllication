import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp-up to 20 users
    { duration: '1m', target: 100 },  // Load test with 100 VUs
    { duration: '30s', target: 200 }, // Stress test up to 200 VUs
    { duration: '15s', target: 500 }, // Spike test to 500 VUs
    { duration: '30s', target: 0 },   // Ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete within 500ms
    http_req_failed: ['rate<0.01'],    // Error rate must be less than 1%
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8081';

export default function () {
  // 1. Home / Catalog request
  const resCatalog = http.get(`${BASE_URL}/`);
  check(resCatalog, {
    'catalog status is 200': (r) => r.status === 200,
    'catalog response time < 300ms': (r) => r.timings.duration < 300,
  });

  sleep(1);

  // 2. Products query check
  const resProducts = http.get(`${BASE_URL}/assets/assets/images/shop/gnc/gnc_whey_protein.png`);
  check(resProducts, {
    'asset status is 200': (r) => r.status === 200 || r.status === 304,
  });

  sleep(1);
}
