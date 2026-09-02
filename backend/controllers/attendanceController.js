// new_backend/controllers/attendanceController.js
const attendanceService = require('../services/attendanceService');

// Customer: "I'm not eating lunch today."
async function skipMeal(req, res) {
  const attendance = await attendanceService.skipMeal(req.membership, req.body.meal);
  res.status(201).json({
    success: true,
    data: {
      serviceDate: attendance.service_date,
      meal: attendance.meal,
      status: attendance.status,
    },
  });
}

// Manager's kiosk device: member taps their name and enters their PIN.
async function markAtKiosk(req, res) {
  const attendance = await attendanceService.markAttendanceAtKiosk(req.mess.id, req.body);
  res.status(201).json({
    success: true,
    data: {
      membershipId: attendance.membership_id,
      serviceDate: attendance.service_date,
      meal: attendance.meal,
      status: attendance.status,
    },
  });
}

// The member is mid-leave but has turned up anyway. Explicit, separate action
// from markAtKiosk - see the service for what it does to the leave record.
async function overrideLeaveAtKiosk(req, res) {
  const result = await attendanceService.overrideLeaveAndMarkPresent(req.mess.id, req.body);
  res.status(201).json({
    success: true,
    data: {
      membershipId: result.attendance.membership_id,
      serviceDate: result.attendance.service_date,
      meal: result.attendance.meal,
      status: result.attendance.status,
      elapsedLeaveDays: result.elapsedLeaveDays,
      elapsedLeaveKept: result.elapsedLeaveKept,
      leaveEndedOn: result.leaveEndedOn,
    },
  });
}

// A walk-in customer buying a single thali (no membership involved).
async function recordWalkinSale(req, res) {
  const sale = await attendanceService.recordWalkinSale(req.mess, req.body, req.user.id);
  res.status(201).json({ success: true, data: sale });
}

// Month view. Works for both the customer looking at their own attendance and
// a manager looking at one of their members - loadMembership has already
// checked the caller is allowed to see this membership either way.
async function getCalendar(req, res) {
  const calendar = await attendanceService.getAttendanceCalendar(
    req.membership.id,
    req.validatedQuery || {}
  );
  res.json({ success: true, data: calendar });
}

module.exports = { skipMeal, markAtKiosk, overrideLeaveAtKiosk, recordWalkinSale, getCalendar };
