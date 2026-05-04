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
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.05'],
  },
};

export default function () {
  const BASE = ENV.TARGET || 'http://localhost:5001';

  const responses = http.batch([
    ['GET', `${BASE}/`],
    ['GET', `${BASE}/health`],
    ['GET', `${BASE}/api/quick-search?query=test`],
  ]);

  check(responses[0], { 'root is 200': (r) => r && r.status === 200 });
  check(responses[1], { 'health is 200': (r) => r && r.status === 200 });
  check(responses[2], { 'quick-search ok': (r) => r && (r.status === 200 || r.status === 204 || r.status === 404) });

  sleep(1);
}
