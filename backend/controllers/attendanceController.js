const Attendance = require('../models/Attendance');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const User = require('../models/User');
const Leave = require('../models/Leave');
const { checkMealTiming, getStartAndEndOfDay, getStartAndEndOfMonth } = require('../utils/billCalculation');

// @desc    Skip a meal
// @route   POST /api/attendance/skip
// @access  Private (Customer only)
exports.skipMeal = async (req, res, next) => {
  try {
    const { membershipId, mealType, date } = req.body;

    // Find membership
    const membership = await Membership.findById(membershipId).populate('mess');

    if (!membership) {
      return res.status(404).json({
        success: false,
        message: 'Membership not found'
      });
    }

    // Verify membership belongs to user and is active
    if (membership.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    if (membership.status !== 'Active') {
      return res.status(400).json({
        success: false,
        message: 'Membership is not active'
      });
    }

    // Check meal timing
    const timingCheck = checkMealTiming(membership.mess.timings, mealType);

    if (timingCheck.isPast) {
      return res.status(403).json({
        success: false,
        message: `${mealType} time has already passed. Cannot skip.`
      });
    }

    // Set attendance date
    const attendanceDate = date ? new Date(date) : new Date();
    attendanceDate.setHours(0, 0, 0, 0);

    // Check if attendance already exists
    const existingAttendance = await Attendance.findOne({
      user: req.user.id,
      mess: membership.mess._id,
      date: attendanceDate,
      mealType
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: 'Attendance already marked for this meal'
      });
    }

    // Create skipped attendance (for monthly members)
    const attendance = await Attendance.create({
      user: req.user.id,
      mess: membership.mess._id,
      date: attendanceDate,
      mealType,
      status: 'Skipped',
      memberType: 'Monthly'
    });

    res.status(201).json({
      success: true,
      data: attendance,
      message: 'Meal skipped successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Mark attendance via kiosk (for monthly members)
// @route   POST /api/attendance/kiosk/mark
// @access  Private (Manager only)
// attendanceController.js

exports.kioskMarkAttendance = async (req, res, next) => {
  try {
    const { userId, kioskPin, mealType } = req.body;

    // Manager's mess (kiosk runs under manager auth)
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }

    // 1) User + PIN validation
    const user = await User.findById(userId).select('+pin');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    if (!user.pin || String(user.pin) !== String(kioskPin)) {
      return res.status(401).json({ success: false, message: 'Invalid Kiosk PIN' });
    }

    // 2) Meal timing window
    const timingCheck = checkMealTiming(mess.timings, mealType || null);
    const resolvedMeal = mealType || timingCheck.currentMeal;
    if (!resolvedMeal || !timingCheck.isWithin) {
      return res.status(403).json({
        success: false,
        message: `${mealType || 'Current'} time has passed. Cannot mark attendance.`
      });
    }

    // 3) Active membership in this mess
    const membership = await Membership.findOne({
      user: userId,
      mess: mess._id,
      status: 'Active'
    });
    if (!membership) {
      return res.status(403).json({ success: false, message: 'No active membership found for this user' });
    }

    // Plan eligibility check via planName
    const planName = String(membership.planName || '').toLowerCase();
    if (resolvedMeal === 'Lunch' && !planName.includes('lunch')) {
      return res.status(403).json({ success: false, message: 'Your plan does not include lunch' });
    }
    if (resolvedMeal === 'Dinner' && !planName.includes('dinner')) {
      return res.status(403).json({ success: false, message: 'Your plan does not include dinner' });
    }

    // 4) Leave check (date-range only; no status)
    const { startOfDay, endOfDay } = getStartAndEndOfDay();
    const activeLeave = await Leave.findOne({
      user: userId,
      mess: mess._id,
      startDate: { $lte: endOfDay },
      endDate: { $gte: startOfDay }
    });
    if (activeLeave) {
      return res.status(403).json({ success: false, message: 'User is on leave' });
    }

    // 5) Existing attendance check
    const existingAttendance = await Attendance.findOne({
      user: userId,
      mess: mess._id,
      date: { $gte: startOfDay, $lte: endOfDay },
      mealType: resolvedMeal
    });
    if (existingAttendance) {
      if (existingAttendance.status === 'Present') {
        return res.status(400).json({ success: false, message: 'Attendance already marked as Present' });
      }
      if (existingAttendance.status === 'Skipped') {
        return res.status(400).json({ success: false, message: 'User has already skipped this meal' });
      }
    }

    // 6) Create Present attendance (Monthly)
    const attendance = await Attendance.create({
      user: userId,
      mess: mess._id,
      date: new Date(),
      mealType: resolvedMeal,
      status: 'Present',
      memberType: 'Monthly'
    });

    const populatedAttendance = await Attendance.findById(attendance._id)
      .populate('user', 'name phone');

    return res.status(201).json({
      success: true,
      data: populatedAttendance,
      message: 'Attendance marked successfully'
    });
  } catch (error) {
    next(error);
  }
};


// @desc    Mark daily/walk-in meal
// @route   POST /api/attendance/kiosk/daily
// @access  Private (Manager only)
exports.kioskMarkDaily = async (req, res, next) => {
  try {
    const { mealType } = req.body;

    // Find manager's mess
    const mess = await Mess.findOne({ owner: req.user.id });

    if (!mess) {
      return res.status(404).json({
        success: false,
        message: 'No mess found for this manager'
      });
    }

    // Check if mess supports daily service
    if (mess.serviceType !== 'Both Daily & Monthly') {
      return res.status(403).json({
        success: false,
        message: 'Your mess does not support daily/walk-in service'
      });
    }

    // Check meal timing
    const timingCheck = checkMealTiming(mess.timings, mealType);

    if (!timingCheck.isWithin) {
      return res.status(403).json({
        success: false,
        message: `${mealType} time has passed.`
      });
    }

    // Create daily attendance (no user associated, memberType: 'Daily')
    const attendance = await Attendance.create({
      user: null,
      mess: mess._id,
      date: new Date(),
      mealType,
      status: 'Present',
      memberType: 'Daily'
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

    // Find membership
    const membership = await Membership.findById(membershipId);

    if (!membership) {
      return res.status(404).json({
        success: false,
        message: 'Membership not found'
      });
    }

    // Verify membership belongs to user
    if (membership.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    // Get date range
    const targetMonth = month ? parseInt(month) : new Date().getMonth() + 1;
    const targetYear = year ? parseInt(year) : new Date().getFullYear();

    const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(targetMonth, targetYear);

    // Get attendance records (only monthly member records)
    const attendance = await Attendance.find({
      user: req.user.id,
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

    // Get date range
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