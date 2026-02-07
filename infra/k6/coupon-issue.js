import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 300,
  duration: '30s',
};

const baseUrl = __ENV.BASE_URL || 'http://localhost:8080';
const promoCode = __ENV.PROMO_CODE || 'PROMO-E024';

export default function () {
  const userId = `user-${__VU}-${__ITER}`;
  const body = JSON.stringify({ userId });

  const res = http.post(`${baseUrl}/promotions/${promoCode}/coupons/issue`, body, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(res, {
    'status is 200/409': (r) => r.status === 200 || r.status === 409,
  });

  sleep(0.01);
}
