import { BASE_URL, API_PREFIX } from '../config/env.js';
import { jsonHeaders } from '../utils/headers.js';
import { get, expect2xx } from '../utils/http.js';

export function getMyAttendanceCalendar(customerToken, membershipId, opts = {}) {
	const { month, year, mealType } = opts;
	const query = [];
	if (month) query.push(`month=${encodeURIComponent(month)}`);
	if (year) query.push(`year=${encodeURIComponent(year)}`);
	if (mealType) query.push(`mealType=${encodeURIComponent(mealType)}`);
	const qs = query.length ? `?${query.join('&')}` : '';

	const url = `${BASE_URL}${API_PREFIX}/attendance/my-calendar/${membershipId}${qs}`;
	const params = { ...jsonHeaders(customerToken), tags: { name: 'GET /attendance/my-calendar/:membershipId' } };

	const { res, body } = get(url, params, 'attendance_my_calendar');
	expect2xx(res, 'attendance_my_calendar');
	return body;
}

export function getMemberAttendance(managerToken, membershipId, opts = {}) {
	const { month, year, mealType } = opts;
	const query = [];
	if (month) query.push(`month=${encodeURIComponent(month)}`);
	if (year) query.push(`year=${encodeURIComponent(year)}`);
	if (mealType) query.push(`mealType=${encodeURIComponent(mealType)}`);
	const qs = query.length ? `?${query.join('&')}` : '';

	const url = `${BASE_URL}${API_PREFIX}/attendance/member/${membershipId}${qs}`;
	const params = { ...jsonHeaders(managerToken), tags: { name: 'GET /attendance/member/:membershipId' } };

	const { res, body } = get(url, params, 'attendance_member_calendar');
	expect2xx(res, 'attendance_member_calendar');
	return body;
}

export function getMealDashboardStats(managerToken, mealType = null) {
	const qs = mealType ? `?mealType=${encodeURIComponent(mealType)}` : '';
	const url = `${BASE_URL}${API_PREFIX}/attendance/dashboard/meal-stats${qs}`;
	const params = { ...jsonHeaders(managerToken), tags: { name: 'GET /attendance/dashboard/meal-stats' } };

	const { res, body } = get(url, params, 'attendance_meal_stats');
	expect2xx(res, 'attendance_meal_stats');
	return body;
}
