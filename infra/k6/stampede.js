import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 50,
  duration: '60s',
};

const baseUrl = __ENV.BASE_URL || 'http://localhost:8080';
const accountId = __ENV.ACCOUNT_ID || 'A-1';

export default function () {
  const res = http.get(`${baseUrl}/accounts/${accountId}/balance`);
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  sleep(0.1);
}
