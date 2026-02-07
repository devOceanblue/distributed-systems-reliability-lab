import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = { vus: 100, duration: '60s' };

const baseUrl = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  const res = http.get(`${baseUrl}/accounts/global/balance`);
  check(res, { 'status is 200': (r) => r.status === 200 });
  sleep(0.05);
}
