import http from 'k6/http';
import { check, sleep } from 'k6';

const ENV = typeof __ENV !== 'undefined' ? __ENV : (globalThis.__ENV || {});
const USERS = parseInt(ENV.USERS || '50', 10);
const DURATION = parseInt(ENV.DURATION || '300', 10);
const SUSTAIN = Math.max(DURATION - 60, 10);

export const options = {
  stages: [
    { duration: '30s', target: USERS },
    { duration: `${SUSTAIN}s`, target: USERS },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<700'],
    http_req_failed: ['rate<0.05'],
  },
};

export default function () {
  const BASE = ENV.TARGET || 'http://localhost:4000';

  const resRoot = http.get(`${BASE}/`);
  const resHealth = http.get(`${BASE}/api/health`);

  check(resRoot, { 'frontend root 200': (r) => r && r.status === 200 });
  // Some Next frontends may not expose /api/health; tolerate non-200
  check(resHealth, { 'frontend health ok': (r) => r && (r.status === 200 || r.status === 404) });

  sleep(1);
}
