import http from 'k6/http';
import { check, fail, sleep } from 'k6';

const ENV = typeof __ENV !== 'undefined' ? __ENV : (globalThis.__ENV || {});
const WEB_BASE = ENV.WEB_BASE || ENV.TARGET || 'http://localhost:4000';
const API_BASE = ENV.API_BASE || 'http://localhost:5001';
const EMAIL = ENV.EMAIL || 'student@thapar.edu';
const PASSWORD = ENV.PASSWORD || '123456';
const USERS = parseInt(ENV.USERS || '50', 10);
const DURATION = parseInt(ENV.DURATION || '300', 10);
const SUSTAIN = Math.max(DURATION - 60, 10);

export const options = {
  stages: [
    { duration: '45s', target: USERS },
    { duration: `${SUSTAIN}s`, target: USERS },
    { duration: '45s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<800'],
    http_req_failed: ['rate<0.05'],
  },
};

const session = {
  jar: http.cookieJar(),
  loggedIn: false,
  userId: null,
  accessToken: null,
  enrolledCourseId: null,
  teacherId: null,
  lectureId: null,
};

function postJson(url, body, params = {}) {
  return http.post(url, JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json', ...(params.headers || {}) },
    jar: session.jar,
    ...params,
  });
}

function get(url, params = {}) {
  return http.get(url, {
    jar: session.jar,
    ...params,
  });
}

function getJson(url, params = {}) {
  const response = get(url, params);
  return response;
}

function pickFirst(array) {
  return Array.isArray(array) && array.length > 0 ? array[0] : null;
}

function ensureLogin() {
  if (session.loggedIn) {
    return;
  }

  const response = postJson(`${WEB_BASE}/api/login`, {
    email: EMAIL,
    password: PASSWORD,
  });

  check(response, {
    'login request succeeded': (r) => r.status === 200,
  });

  const payload = response.json();
  if (!payload || !payload.success || !payload.accessToken) {
    fail(`login failed: ${response.body}`);
  }

  session.loggedIn = true;
  session.userId = payload.user?.id || null;
  session.accessToken = payload.accessToken;
}

function assertOk(response, label, acceptedStatuses = [200]) {
  check(response, {
    [label]: (r) => acceptedStatuses.includes(r.status),
  });
}

export default function () {
  // Anonymous entry points that a real student would hit before logging in.
  const publicResponses = http.batch([
    ['GET', `${WEB_BASE}/`],
    ['GET', `${WEB_BASE}/login`],
    ['GET', `${WEB_BASE}/teachers`],
    ['GET', `${WEB_BASE}/browse`],
  ].map(([method, url]) => ({ method, url, jar: session.jar })));

  assertOk(publicResponses[0], 'home page loads');
  assertOk(publicResponses[1], 'login page loads');
  assertOk(publicResponses[2], 'teachers page loads');
  assertOk(publicResponses[3], 'browse page loads');

  ensureLogin();

  const authResponses = http.batch([
    ['GET', `${WEB_BASE}/dashboard`],
    ['GET', `${WEB_BASE}/profile`],
    ['GET', `${WEB_BASE}/watchHistory`],
    ['GET', `${WEB_BASE}/api/verify-auth`],
    ['GET', `${WEB_BASE}/api/get-user-data`],
    ['GET', `${WEB_BASE}/api/courses/browse`],
    ['GET', `${WEB_BASE}/api/teachers?page=1&limit=12`],
    ['GET', `${WEB_BASE}/api/quick-search?q=thapar&limit=8`],
    ['GET', `${WEB_BASE}/api/search?q=thapar&type=teachers`],
    ['GET', `${WEB_BASE}/api/search?q=course&type=courses`],
    ['GET', `${WEB_BASE}/api/watch-history/recent?limit=5`],
  ].map(([method, url]) => ({ method, url, jar: session.jar })));

  assertOk(authResponses[0], 'dashboard loads');
  assertOk(authResponses[1], 'profile loads');
  assertOk(authResponses[2], 'watch history loads');
  assertOk(authResponses[3], 'auth verifies');
  assertOk(authResponses[4], 'user data loads');
  assertOk(authResponses[5], 'course browse loads');
  assertOk(authResponses[6], 'teachers list loads');
  assertOk(authResponses[7], 'quick search loads');
  assertOk(authResponses[8], 'teacher search loads');
  assertOk(authResponses[9], 'course search loads');
  assertOk(authResponses[10], 'recent activity loads');

  const verifiedAuth = authResponses[3].json();
  const authData = authResponses[4].json();
  const browseCourses = authResponses[5].json();
  const teachers = authResponses[6].json();

  session.userId = verifiedAuth?.id || authData?.id || session.userId;

  const enrolledCourse = pickFirst(authData?.enrolled_courses) || pickFirst(browseCourses);
  const teacherEntry = pickFirst(teachers?.teachers || teachers);

  const courseId = enrolledCourse?.course_instance_id || enrolledCourse?.id || null;
  if (courseId) {
    session.enrolledCourseId = courseId;

    const courseResponse = getJson(`${WEB_BASE}/api/courses/${courseId}`);
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
      const teacherResponse = getJson(`${WEB_BASE}/api/teachers/${session.teacherId}`);
      assertOk(teacherResponse, 'teacher details load');

      const teacherPage = getJson(`${WEB_BASE}/teacher/${session.teacherId}`);
      assertOk(teacherPage, 'teacher page loads');
    }

    const coursePage = getJson(`${WEB_BASE}/course_page/${courseId}`);
    assertOk(coursePage, 'course page loads');

    const enrollmentCheck = getJson(`${WEB_BASE}/api/enrollment/check/${courseId}`);
    assertOk(enrollmentCheck, 'enrollment check loads');

    const enrolledCoursesResponse = getJson(`${API_BASE}/api/student_enrolled_courses/${session.userId}`);
    assertOk(enrolledCoursesResponse, 'student enrolled courses loads', [200, 404]);

    if (firstLecture?.id) {
      session.lectureId = firstLecture.id;

      const progressResponse = getJson(`${WEB_BASE}/api/get-video-progress/${session.lectureId}`);
      assertOk(progressResponse, 'video progress loads');

      const watchWrite = postJson(`${WEB_BASE}/api/watch-history`, {
        lecture_id: session.lectureId,
        progress: 37,
        current_time: 420,
      });
      assertOk(watchWrite, 'watch history write succeeds');

      const watchList = getJson(`${WEB_BASE}/api/watch-history`);
      assertOk(watchList, 'watch history list loads');

      const watchRecent = getJson(`${WEB_BASE}/api/watch-history/recent?limit=3`);
      assertOk(watchRecent, 'watch history recent loads');
    }
  } else {
    // If the student has no enrolled courses yet, enroll into the first browsed course once.
    const fallbackCourse = pickFirst(browseCourses);
    if (fallbackCourse?.id) {
      session.enrolledCourseId = fallbackCourse.id;
      const enrollResponse = postJson(`${WEB_BASE}/api/enroll`, {
        course_instance_id: fallbackCourse.id,
      });
      assertOk(enrollResponse, 'course enrollment works', [200, 201, 400]);
    }
  }

  const advancedSearch = postJson(`${WEB_BASE}/api/advanced-search`, {
    query: 'thapar',
    type: 'all',
    page: 1,
    limit: 10,
    filters: {},
    sortBy: 'relevance',
    sortOrder: 'desc',
  });
  assertOk(advancedSearch, 'advanced search loads');

  sleep(1);
}
