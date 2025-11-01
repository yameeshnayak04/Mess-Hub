const Attendance = require('../models/Attendance');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const User = require('../models/User');
const Leave = require('../models/Leave');
// FIX: Import from consolidated utility
const { checkMealTiming, getStartAndEndOfDay, getStartAndEndOfMonth, startOfDay, endOfDay } = require('../utils/billCalculation');

// @desc    Skip a meal
// @route   POST /api/attendance/skip
// @access  Private (Customer only)
exports.skipMeal = async (req, res, next) => {
  try {
    const { membershipId, mealType, date } = req.body;

    const membership = await Membership.findById(membershipId).populate('mess');
    if (!membership) return res.status(404).json({ success: false, message: 'Membership not found' });
    if (membership.user.toString() !== req.user.id) return res.status(403).json({ success: false, message: 'Not authorized' });
    if (membership.status !== 'Active') return res.status(400).json({ success: false, message: 'Membership is not active' });

    const timingCheck = checkMealTiming(membership.mess.timings, mealType);
    if (timingCheck.isPast) return res.status(403).json({ success: false, message: `${mealType} time has already passed. Cannot skip.` });

    const attendanceDate = date ? new Date(date) : new Date();
    const normalizedDate = startOfDay(attendanceDate);

    // Prevent over existing any status
    const exists = await Attendance.findOne({ membership: membership._id, date: normalizedDate, mealType });
    if (exists) return res.status(400).json({ success: false, message: 'Attendance already marked for this meal' });

    const attendance = await Attendance.create({
      user: req.user.id,
      membership: membership._id,
      mess: membership.mess._id,
      date: normalizedDate,
      mealType,
      status: 'Skipped',
      memberType: 'Monthly',
      planNameSnapshot: membership.planName,
      rateSnapshot: membership.billingRate,
      rebatePerThaliSnapshot: membership.mess.rules.rebatePerThali,
    });

    return res.status(201).json({ success: true, data: attendance, message: 'Meal skipped successfully' });
  } catch (error) {
    if (error?.code === 11000) {
      return res.status(400).json({ success: false, message: 'Attendance already marked for this meal' });
    }
    return next(error);
  }
};


// @desc    Mark attendance via kiosk (for monthly members)
// @route   POST /api/attendance/kiosk/mark
// @access  Private (Manager only)
exports.kioskMarkAttendance = async (req, res, next) => {
  try {
    const { userId, kioskPin, mealType } = req.body;

    // 1) Manager -> mess and timing
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) return res.status(404).json({ success: false, message: 'No mess found for this manager' });

    const timingCheck = checkMealTiming(mess.timings, mealType || null);
    const resolvedMeal = mealType || timingCheck.currentMeal;
    
    // Check if within time
    if (!resolvedMeal || resolvedMeal === 'None') {
      return res.status(403).json({ success: false, message: 'No meal is currently active.' });
    }
    if (!timingCheck.isWithin) {
       return res.status(403).json({ success: false, message: `${resolvedMeal} service time is over.` });
    }


    // 2) User + PIN
    const user = await User.findById(userId).select('+pin');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    if (!user.pin || String(user.pin) !== String(kioskPin)) {
      return res.status(401).json({ success: false, message: 'Invalid Kiosk PIN' });
    }

    // 3) Active membership in this mess
    const membership = await Membership.findOne({ user: userId, mess: mess._id, status: 'Active' });
    if (!membership) return res.status(403).json({ success: false, message: 'No active membership found for this user' });

    // 4) Plan coverage
    const planName = String(membership.planName || '').toLowerCase();
    if (resolvedMeal === 'Lunch' && !planName.includes('lunch') && !planName.includes('both')) {
      return res.status(403).json({ success: false, message: 'Your plan does not include lunch' });
    }
    if (resolvedMeal === 'Dinner' && !planName.includes('dinner') && !planName.includes('both')) {
      return res.status(403).json({ success: false, message: 'Your plan does not include dinner' });
    }

    // 5) Leave window block
    const dayStart = startOfDay();
    const dayEnd = endOfDay();
    const activeLeave = await Leave.findOne({
      user: userId,
      mess: mess._id,
      startDate: { $lte: dayEnd },
      endDate: { $gte: dayStart },
    });
    if (activeLeave) return res.status(403).json({ success: false, message: 'User is on leave' });

    // 6) No duplicates or skip prior
    const existing = await Attendance.findOne({ membership: membership._id, date: dayStart, mealType: resolvedMeal });
    if (existing) {
      const msg = existing.status === 'Present'
        ? 'Attendance already marked as Present'
        : existing.status === 'Skipped'
        ? 'User has already skipped this meal'
        : 'Already set (Leave/Absent)';
      return res.status(400).json({ success: false, message: msg });
    }

    // 7) Create Present (monthly) with normalized date
    const created = await Attendance.create({
      user: userId,
      membership: membership._id,
      mess: mess._id,
      date: dayStart,
      mealType: resolvedMeal,
      status: 'Present',
      memberType: 'Monthly',
      planNameSnapshot: membership.planName,
      rateSnapshot: membership.billingRate,
    });

    const populated = await Attendance.findById(created._id).populate('user', 'name phone');
    return res.status(201).json({ success: true, data: populated, message: 'Attendance marked successfully' });
  } catch (err) {
    if (err?.code === 11000) {
      return res.status(400).json({ success: false, message: 'Attendance already marked for this meal' });
    }
    return next(err);
  }
};



// @desc    Mark daily/walk-in meal
// @route   POST /api/attendance/kiosk/daily
// @access  Private (Manager only)
exports.kioskMarkDaily = async (req, res, next) => {
  try {
    const { mealType } = req.body;

    const mess = await Mess.findOne({ owner: req.user.id });

    if (!mess) {
      return res.status(404).json({
        success: false,
        message: 'No mess found for this manager'
      });
    }

    if (mess.serviceType !== 'Both Daily & Monthly') {
      return res.status(403).json({
        success: false,
        message: 'Your mess does not support daily/walk-in service'
      });
    }

    const timingCheck = checkMealTiming(mess.timings, mealType);

    if (!timingCheck.isWithin) {
      return res.status(403).json({
        success: false,
        message: `${mealType} time has passed.`
      });
    }

    const attendance = await Attendance.create({
      user: null, // No user for daily
      membership: null, // No membership for daily
      mess: mess._id,
      date: startOfDay(), // Normalized date
      mealType,
      status: 'Present',
      memberType: 'Daily',
      rateSnapshot: mess.dailyThaliRate, // Snapshot the daily rate
    });

    res.status(201).json({
      success: true,
      data: attendance,
      message: 'Daily meal logged successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get customer's attendance calendar
// @route   GET /api/attendance/my-calendar/:membershipId
// @access  Private (Customer only)
exports.getMyAttendance = async (req, res, next) => {
  try {
    const { membershipId } = req.params;
    const { month, year } = req.query;
    const membership = await Membership.findById(membershipId);
    if (!membership) return res.status(404).json({ success: false, message: 'Membership not found' });
    if (membership.user.toString() !== req.user.id) return res.status(403).json({ success: false, message: 'Not authorized' });

    const targetMonth = month ? parseInt(month) : new Date().getMonth() + 1;
    const targetYear = year ? parseInt(year) : new Date().getFullYear();
    const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(targetMonth, targetYear);

    const attendance = await Attendance.find({
      membership: membershipId,
      date: { $gte: startOfMonth, $lte: endOfMonth },
      memberType: 'Monthly',
    }).sort({ date: 1, mealType: 1 });

    return res.status(200).json({ success: true, count: attendance.length, data: attendance });
  } catch (error) {
    return next(error);
  }
};


// @desc    Get a specific member's attendance calendar
// @route   GET /api/attendance/member/:membershipId
// @access  Private (Manager only)
exports.getMemberAttendance = async (req, res, next) => {
  try {
    const { membershipId } = req.params;
    const { month, year } = req.query;

    const membership = await Membership.findById(membershipId);
    if (!membership) {
      return res.status(404).json({ success: false, message: 'Membership not found' });
    }

    // Verify manager owns the mess
    const mess = await Mess.findOne({ _id: membership.mess, owner: req.user.id });
    if (!mess) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const targetMonth = month ? parseInt(month) : new Date().getMonth() + 1;
    const targetYear = year ? parseInt(year) : new Date().getFullYear();
    const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(targetMonth, targetYear);

    const attendance = await Attendance.find({
      user: membership.user,
      mess: membership.mess,
      date: { $gte: startOfMonth, $lte: endOfMonth },
      memberType: 'Monthly'
    }).sort({ date: 1, mealType: 1 });

    res.status(200).json({
      success: true,
      count: attendance.length,
      data: attendance
    });
  } catch (error) {
    next(error);
  }
};