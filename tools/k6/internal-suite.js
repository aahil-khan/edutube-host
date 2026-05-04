import http from 'k6/http';
import { check, fail, sleep } from 'k6';
import { SharedArray } from 'k6/data';

const ENV = typeof __ENV !== 'undefined' ? __ENV : (globalThis.__ENV || {});
const WEB_BASE = ENV.WEB_BASE || ENV.TARGET || 'http://localhost:4000';
const API_BASE = ENV.API_BASE || 'http://localhost:5001';
const TOTAL_VUS = Math.max(parseInt(ENV.USERS || '30', 10), 3);
const DURATION = parseInt(ENV.DURATION || '300', 10);

const CREDENTIALS = new SharedArray('credential pool', () => [
  { email: 'student@thapar.edu', password: '123456' },
  { email: 'loadtest1@edutube.com', password: '123456' },
  { email: 'loadtest2@edutube.com', password: '123456' },
  { email: 'loadtest3@edutube.com', password: '123456' },
  { email: 'loadtest4@edutube.com', password: '123456' },
  { email: 'loadtest5@edutube.com', password: '123456' },
]);

const DISTRIBUTION = allocateTraffic(TOTAL_VUS);

export const options = {
  scenarios: {
    browsing: {
      executor: 'constant-vus',
      vus: DISTRIBUTION.browsing,
      duration: `${DURATION}s`,
      exec: 'browsingScenario',
      tags: { traffic: 'browse' },
      gracefulStop: '20s',
    },
    watching: {
      executor: 'constant-vus',
      vus: DISTRIBUTION.watching,
      duration: `${DURATION}s`,
      exec: 'watchingScenario',
      tags: { traffic: 'watch' },
      gracefulStop: '20s',
    },
    writes: {
      executor: 'constant-vus',
      vus: DISTRIBUTION.writes,
      duration: `${DURATION}s`,
      exec: 'writeScenario',
      tags: { traffic: 'write' },
      gracefulStop: '20s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<800'],
    http_req_failed: ['rate<0.05'],
  },
};

function allocateTraffic(totalVus) {
  const browsing = Math.max(Math.floor(totalVus * 0.70), 1);
  const watching = Math.max(Math.floor(totalVus * 0.25), 1);
  let writes = Math.max(totalVus - browsing - watching, 1);

  let adjustedBrowsing = browsing;
  let adjustedWatching = watching;
  let adjustedWrites = writes;
  let sum = adjustedBrowsing + adjustedWatching + adjustedWrites;

  while (sum > totalVus) {
    if (adjustedBrowsing > adjustedWatching && adjustedBrowsing > 1) {
      adjustedBrowsing -= 1;
    } else if (adjustedWatching > 1) {
      adjustedWatching -= 1;
    } else if (adjustedWrites > 1) {
      adjustedWrites -= 1;
    } else {
      break;
    }
    sum = adjustedBrowsing + adjustedWatching + adjustedWrites;
  }

  while (sum < totalVus) {
    adjustedBrowsing += 1;
    sum += 1;
  }

  return {
    browsing: adjustedBrowsing,
    watching: adjustedWatching,
    writes: adjustedWrites,
  };
}

function createSession() {
  return {
    jar: http.cookieJar(),
    loggedIn: false,
    userId: null,
    accessToken: null,
    courseId: null,
    teacherId: null,
    lectureId: null,
    initialized: false,
  };
}

function pickFirst(array) {
  return Array.isArray(array) && array.length > 0 ? array[0] : null;
}

function pickCredential() {
  return CREDENTIALS[(__VU - 1) % CREDENTIALS.length];
}

function think(minSeconds = 0.7, maxSeconds = 2.7) {
  const delay = minSeconds + Math.random() * (maxSeconds - minSeconds);
  sleep(delay);
}

function requestJson(method, url, body, session, tags = {}) {
  const params = {
    jar: session.jar,
    headers: {},
    tags,
  };

  if (body !== undefined) {
    params.headers['Content-Type'] = 'application/json';
  }

  let response;
  switch (method) {
    case 'GET':
      response = http.get(url, params);
      break;
    case 'POST':
      response = http.post(url, JSON.stringify(body), params);
      break;
    case 'PUT':
      response = http.put(url, JSON.stringify(body), params);
      break;
    case 'DELETE':
      response = http.del(url, JSON.stringify(body), params);
      break;
    default:
      fail(`Unsupported method: ${method}`);
  }

  return response;
}

function getJson(url, session, tags = {}) {
  return requestJson('GET', url, undefined, session, tags);
}

function postJson(url, body, session, tags = {}) {
  return requestJson('POST', url, body, session, tags);
}

function assertOk(response, label, acceptedStatuses = [200]) {
  check(response, {
    [label]: (r) => acceptedStatuses.includes(r.status),
  });
}

function ensureLogin(session) {
  if (session.loggedIn) {
    return;
  }

  const credential = pickCredential();
  const response = postJson(`${WEB_BASE}/api/login`, {
    email: credential.email,
    password: credential.password,
  }, session, { endpoint: 'login' });

  assertOk(response, `login succeeds for ${credential.email}`);

  const payload = response.json();
  if (!payload || !payload.success || !payload.accessToken) {
    fail(`login failed for ${credential.email}: ${response.body}`);
  }

  session.loggedIn = true;
  session.userId = payload.user?.id || null;
  session.accessToken = payload.accessToken;
}

function loadPublicPages(session) {
  const responses = http.batch([
    { method: 'GET', url: `${WEB_BASE}/`, jar: session.jar, tags: { endpoint: 'home' } },
    { method: 'GET', url: `${WEB_BASE}/login`, jar: session.jar, tags: { endpoint: 'login-page' } },
    { method: 'GET', url: `${WEB_BASE}/teachers`, jar: session.jar, tags: { endpoint: 'teachers-page' } },
    { method: 'GET', url: `${WEB_BASE}/browse`, jar: session.jar, tags: { endpoint: 'browse-page' } },
  ]);

  assertOk(responses[0], 'home page loads');
  assertOk(responses[1], 'login page loads');
  assertOk(responses[2], 'teachers page loads');
  assertOk(responses[3], 'browse page loads');
}

function loadReadOnlyStudentFlow(session) {
  const responses = http.batch([
    { method: 'GET', url: `${WEB_BASE}/dashboard`, jar: session.jar, tags: { endpoint: 'dashboard-page' } },
    { method: 'GET', url: `${WEB_BASE}/profile`, jar: session.jar, tags: { endpoint: 'profile-page' } },
    { method: 'GET', url: `${WEB_BASE}/watchHistory`, jar: session.jar, tags: { endpoint: 'watch-history-page' } },
    { method: 'GET', url: `${WEB_BASE}/api/verify-auth`, jar: session.jar, tags: { endpoint: 'verify-auth' } },
    { method: 'GET', url: `${WEB_BASE}/api/get-user-data`, jar: session.jar, tags: { endpoint: 'get-user-data' } },
    { method: 'GET', url: `${WEB_BASE}/api/courses/browse`, jar: session.jar, tags: { endpoint: 'courses-browse' } },
    { method: 'GET', url: `${WEB_BASE}/api/teachers?page=1&limit=12`, jar: session.jar, tags: { endpoint: 'teachers-list' } },
    { method: 'GET', url: `${WEB_BASE}/api/quick-search?q=thapar&limit=8`, jar: session.jar, tags: { endpoint: 'quick-search' } },
    { method: 'POST', url: `${WEB_BASE}/api/search`, body: JSON.stringify({ query: 'thapar', type: 'teachers', page: 1, limit: 10 }), params: { headers: { 'Content-Type': 'application/json' } }, jar: session.jar, tags: { endpoint: 'search-teachers' } },
    { method: 'POST', url: `${WEB_BASE}/api/search`, body: JSON.stringify({ query: 'course', type: 'courses', page: 1, limit: 10 }), params: { headers: { 'Content-Type': 'application/json' } }, jar: session.jar, tags: { endpoint: 'search-courses' } },
    { method: 'GET', url: `${WEB_BASE}/api/watch-history/recent?limit=5`, jar: session.jar, tags: { endpoint: 'watch-recent' } },
  ]);

  assertOk(responses[0], 'dashboard loads');
  assertOk(responses[1], 'profile loads');
  assertOk(responses[2], 'watch history loads');
  assertOk(responses[3], 'auth verifies');
  assertOk(responses[4], 'user data loads');
  assertOk(responses[5], 'course browse loads');
  assertOk(responses[6], 'teachers list loads');
  assertOk(responses[7], 'quick search loads');
  assertOk(responses[8], 'teacher search loads');
  assertOk(responses[9], 'course search loads');
  assertOk(responses[10], 'recent activity loads');

  const verifiedAuth = responses[3].json();
  const userData = responses[4].json();
  const browseCourses = responses[5].json();
  const teachers = responses[6].json();

  session.userId = verifiedAuth?.id || userData?.id || session.userId;

  const enrolledCourse = pickFirst(userData?.enrolled_courses) || pickFirst(browseCourses);
  const teacherEntry = pickFirst(teachers?.teachers || teachers);
  const courseId = enrolledCourse?.course_instance_id || enrolledCourse?.id || null;

  if (!courseId) {
    return;
  }

  session.courseId = courseId;

  const courseResponse = getJson(`${WEB_BASE}/api/courses/${courseId}`, session, { endpoint: 'course-details' });
  assertOk(courseResponse, 'course details load');

  const courseData = courseResponse.json();
  const firstChapter = pickFirst(courseData);
  const firstLecture = pickFirst(firstChapter?.lectures);

  if (firstChapter?.teacher_id) {
    session.teacherId = firstChapter.teacher_id;
  } else if (teacherEntry?.id) {
    session.teacherId = teacherEntry.id;
  }

  if (session.teacherId) {
    const teacherResponse = getJson(`${WEB_BASE}/api/teachers/${session.teacherId}`, session, { endpoint: 'teacher-details' });
    assertOk(teacherResponse, 'teacher details load');

    const teacherPage = getJson(`${WEB_BASE}/teacher/${session.teacherId}`, session, { endpoint: 'teacher-page' });
    assertOk(teacherPage, 'teacher page loads');
  }

  const coursePage = getJson(`${WEB_BASE}/course_page/${courseId}`, session, { endpoint: 'course-page' });
  assertOk(coursePage, 'course page loads');

  const enrollmentCheck = getJson(`${WEB_BASE}/api/enrollment/check/${courseId}`, session, { endpoint: 'enrollment-check' });
  assertOk(enrollmentCheck, 'enrollment check loads');

  const enrolledCoursesResponse = getJson(`${API_BASE}/api/student_enrolled_courses/${session.userId}`, session, { endpoint: 'student-enrolled-courses' });
  assertOk(enrolledCoursesResponse, 'student enrolled courses loads', [200, 404]);

  if (firstLecture?.id) {
    session.lectureId = firstLecture.id;

    const progressResponse = getJson(`${WEB_BASE}/api/get-video-progress/${session.lectureId}`, session, { endpoint: 'video-progress' });
    assertOk(progressResponse, 'video progress loads');
  }
}

function maybeWriteWatchHistory(session) {
  if (!session.lectureId) {
    return;
  }

  const watchWrite = postJson(`${WEB_BASE}/api/watch-history`, {
    lecture_id: session.lectureId,
    progress: Math.floor(20 + Math.random() * 70),
    current_time: Math.floor(90 + Math.random() * 900),
  }, session, { endpoint: 'watch-write' });

  assertOk(watchWrite, 'watch history write succeeds');
}

export function browsingScenario() {
  const session = createSession();
  loadPublicPages(session);
  ensureLogin(session);

  const browseResponse = getJson(`${WEB_BASE}/api/courses/browse`, session, { endpoint: 'browse-feed' });
  assertOk(browseResponse, 'browse feed loads');

  const teacherList = getJson(`${WEB_BASE}/api/teachers?page=1&limit=6`, session, { endpoint: 'teacher-list-light' });
  assertOk(teacherList, 'teacher list loads');

  const searchResponse = getJson(`${WEB_BASE}/api/quick-search?q=${encodeURIComponent(randomSearchTerm())}&limit=5`, session, { endpoint: 'quick-search-light' });
  assertOk(searchResponse, 'quick search loads');

  think(0.5, 2.0);
}

export function watchingScenario() {
  const session = createSession();
  ensureLogin(session);
  loadReadOnlyStudentFlow(session);

  const watchList = getJson(`${WEB_BASE}/api/watch-history/recent?limit=3`, session, { endpoint: 'watch-recent-light' });
  assertOk(watchList, 'recent watch history loads');

  if (session.lectureId) {
    const progressResponse = getJson(`${WEB_BASE}/api/get-video-progress/${session.lectureId}`, session, { endpoint: 'video-progress-light' });
    assertOk(progressResponse, 'video progress loads');
  }

  think(1.0, 3.5);
}

export function writeScenario() {
  const session = createSession();
  ensureLogin(session);
  loadReadOnlyStudentFlow(session);

  if (session.courseId && Math.random() < 0.35) {
    const enrollResponse = postJson(`${WEB_BASE}/api/enroll`, {
      course_instance_id: session.courseId,
    }, session, { endpoint: 'enroll' });
    assertOk(enrollResponse, 'enrollment write loads', [200, 201, 400]);
  }

  maybeWriteWatchHistory(session);

  const recentResponse = getJson(`${WEB_BASE}/api/watch-history/recent?limit=3`, session, { endpoint: 'watch-recent-write' });
  assertOk(recentResponse, 'recent activity loads');

  const searchResponse = postJson(`${WEB_BASE}/api/advanced-search`, {
    query: randomSearchTerm(),
    type: 'all',
    page: 1,
    limit: 5,
    filters: {},
    sortBy: 'relevance',
    sortOrder: 'desc',
  }, session, { endpoint: 'advanced-search' });
  assertOk(searchResponse, 'advanced search loads');

  think(1.5, 4.0);
}

function randomSearchTerm() {
  const terms = ['thapar', 'course', 'lecture', 'teacher', 'student'];
  return terms[Math.floor(Math.random() * terms.length)];
}
