const Attendance = require('../models/Attendance');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const User = require('../models/User');
const Leave = require('../models/Leave');
// FIX: Import from consolidated utility
const { checkMealTiming, getStartAndEndOfDay, getStartAndEndOfMonth, startOfDay, endOfDay } = require('../utils/billCalculation');

// helpers (add near the top of file)
const getMealsFromPlan = (planName) => {
  const plan = String(planName || '').toLowerCase();
  if (plan.includes('both')) return ['Lunch', 'Dinner'];
  if (plan.includes('lunch')) return ['Lunch'];
  if (plan.includes('dinner')) return ['Dinner'];
  return []; // unknown plan
};

const buildMealTypeFilterOrError = (membership, reqMealType) => {
  const allowed = getMealsFromPlan(membership.planName);
  if (allowed.length === 0) {
    return { error: 'Your plan does not permit any meals.' };
  }

  // Normalize request param
  const requested = reqMealType && ['Lunch', 'Dinner', 'Both', 'All'].includes(reqMealType)
    ? reqMealType
    : null;

  // If a specific meal is requested, enforce plan coverage
  if (requested === 'Lunch' || requested === 'Dinner') {
    if (!allowed.includes(requested)) {
      return { error: `Your plan does not include ${requested}.` };
    }
    return { filter: { mealType: requested }, resolvedMeals: [requested] };
  }

  // Both/All or not provided -> filter by all meals allowed by plan
  if (allowed.length === 1) {
    return { filter: { mealType: allowed[0] }, resolvedMeals: allowed };
  }
  return { filter: { mealType: { $in: allowed } }, resolvedMeals: allowed };
};


// @desc Skip a meal
// @route POST /api/attendance/skip
// @access Private (Customer only)
exports.skipMeal = async (req, res, next) => {
  try {
    const { membershipId, mealType, date } = req.body;

    const membership = await Membership.findById(membershipId).populate('mess');
    if (!membership) {
      return res.status(404).json({ success: false, message: 'Membership not found' });
    }
    if (membership.user.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    if (membership.status !== 'Active') {
      return res.status(400).json({ success: false, message: 'Membership is not active' });
    }

    // --- FIX: Check if member's plan covers this meal ---
    const planName = String(membership.planName).toLowerCase();
    if (mealType === 'Lunch' && !planName.includes('lunch') && !planName.includes('both')) {
      return res.status(403).json({
        success: false,
        message: 'Your plan does not include lunch. You cannot skip this meal.',
      });
    }
    if (mealType === 'Dinner' && !planName.includes('dinner') && !planName.includes('both')) {
      return res.status(403).json({
        success: false,
        message: 'Your plan does not include dinner. You cannot skip this meal.',
      });
    }

    // Timing check
    const timingCheck = checkMealTiming(membership.mess.timings, mealType);
    if (timingCheck.isPast) {
      return res.status(403).json({
        success: false,
        message: `${mealType} time has already passed. Cannot skip.`,
      });
    }

    const attendanceDate = date ? new Date(date) : new Date();
    const normalizedDate = startOfDay(attendanceDate);

    // Prevent overwriting existing attendance
    const exists = await Attendance.findOne({
      membership: membership._id,
      date: normalizedDate,
      mealType,
    });
    if (exists) {
      return res.status(400).json({
        success: false,
        message: 'Attendance already marked for this meal',
      });
    }

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

    return res.status(201).json({
      success: true,
      data: attendance,
      message: 'Meal skipped successfully',
    });
  } catch (error) {
    if (error?.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Attendance already marked for this meal',
      });
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

// @desc Get customer's attendance calendar (with day-level grouping to avoid duplicate dots)
// @route GET /api/attendance/my-calendar/:membershipId
// @access Private (Customer only)
exports.getMyAttendance = async (req, res, next) => {
  try {
    const { membershipId } = req.params;
    const { month, year, mealType } = req.query;

    const membership = await Membership.findById(membershipId);
    if (!membership) {
      return res.status(404).json({ success: false, message: 'Membership not found' });
    }
    if (membership.user.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const targetMonth = month ? parseInt(month) : new Date().getMonth() + 1;
    const targetYear = year ? parseInt(year) : new Date().getFullYear();
    const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(targetMonth, targetYear);

    // Enforce plan-aware meal filtering (same guard used by manager endpoint)
    const mealGuard = buildMealTypeFilterOrError(membership, mealType);
    if (mealGuard.error) {
      return res.status(400).json({ success: false, message: mealGuard.error });
    }

    const query = {
      membership: membership._id,
      memberType: 'Monthly',
      date: { $gte: startOfMonth, $lte: endOfMonth },
      ...(mealGuard.filter || {}),
    };

    // Raw records (kept for compatibility)
    const records = await Attendance.find(query).sort({ date: 1, mealType: 1 });

    // Day-level grouping to avoid duplicate dots for one-day leave spanning multiple meals
    const dayMap = new Map();
    for (const r of records) {
      const key = r.date.toISOString().slice(0, 10); // YYYY-MM-DD
      if (!dayMap.has(key)) {
        dayMap.set(key, {
          date: r.date,
          hasLeave: false,
          hasSkipped: false,
          hasPresent: false,
          meals: [],
        });
      }
      const d = dayMap.get(key);
      d.meals.push({ mealType: r.mealType, status: r.status, attendanceId: r._id });
      if (r.status === 'Leave') d.hasLeave = true;
      if (r.status === 'Skipped') d.hasSkipped = true;
      if (r.status === 'Present') d.hasPresent = true;
    }

    const calendarDays = Array.from(dayMap.values()).sort(
      (a, b) => a.date.getTime() - b.date.getTime()
    );

    return res.status(200).json({
      success: true,
      meta: {
        month: targetMonth,
        year: targetYear,
        meals: mealGuard.resolvedMeals || [],
      },
      // raw, unchanged list (per-meal)
      count: records.length,
      data: records,
      // new, day-level grouping (use this to render one leave dot per day)
      calendarDays,
    });
  } catch (error) {
    return next(error);
  }
};



// @desc Get a specific member's attendance calendar (dedup leave for single-meal plans + day-level view)
// @route GET /api/attendance/member/:membershipId
// @access Private (Manager only)
exports.getMemberAttendance = async (req, res, next) => {
  try {
    const { membershipId } = req.params;
    const { month, year, mealType } = req.query;

    const membership = await Membership.findById(membershipId);
    if (!membership) {
      return res.status(404).json({ success: false, message: 'Membership not found' });
    }

    // Verify the manager owns the membership's mess
    const mess = await Mess.findOne({ _id: membership.mess, owner: req.user.id });
    if (!mess) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const targetMonth = month ? parseInt(month) : new Date().getMonth() + 1;
    const targetYear = year ? parseInt(year) : new Date().getFullYear();
    const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(targetMonth, targetYear);

    // Same plan-aware meal guard used by getMyAttendance
    const mealGuard = buildMealTypeFilterOrError(membership, mealType);
    if (mealGuard.error) {
      return res.status(400).json({ success: false, message: mealGuard.error });
    }

    const query = {
      membership: membership._id,
      memberType: 'Monthly',
      date: { $gte: startOfMonth, $lte: endOfMonth },
      ...(mealGuard.filter || {}),
    };

    // Raw records from DB
    const raw = await Attendance.find(query).sort({ date: 1, mealType: 1 });

    // Deduplicate:
    // - For single-meal plans, collapse multiple Leave records on the same day into one
    // - Also guard against accidental duplicates for same day+meal+status
    const allowedMeals = getMealsFromPlan(membership.planName);
    const seen = new Set();
    const attendance = [];
    for (const r of raw) {
      const day = r.date.toISOString().slice(0, 10); // YYYY-MM-DD
      let key;
      if (allowedMeals.length === 1 && r.status === 'Leave') {
        key = `${day}:Leave`; // collapse per-day leave for single-meal plan
      } else {
        key = `${day}:${r.mealType}:${r.status}`;
      }
      if (seen.has(key)) continue;
      seen.add(key);
      attendance.push(r);
    }

    // Day-level calendar view (one leave dot per day)
    const dayMap = new Map();
    for (const r of attendance) {
      const key = r.date.toISOString().slice(0, 10);
      if (!dayMap.has(key)) {
        dayMap.set(key, {
          date: r.date,
          hasLeave: false,
          hasSkipped: false,
          hasPresent: false,
          meals: [],
        });
      }
      const d = dayMap.get(key);
      d.meals.push({ mealType: r.mealType, status: r.status, attendanceId: r._id });
      if (r.status === 'Leave') d.hasLeave = true;
      if (r.status === 'Skipped') d.hasSkipped = true;
      if (r.status === 'Present') d.hasPresent = true;
    }
    const calendarDays = Array.from(dayMap.values()).sort(
      (a, b) => a.date.getTime() - b.date.getTime()
    );

    return res.status(200).json({
      success: true,
      meta: {
        month: targetMonth,
        year: targetYear,
        meals: mealGuard.resolvedMeals || [],
      },
      count: attendance.length,
      data: attendance,        // deduplicated list
      calendarDays,            // day-level grouping for single-dot rendering
    });
  } catch (error) {
    return next(error);
  }
};



exports.getMealDashboardStats = async (req, res, next) => {
  try {
    // 1) Resolve manager's mess
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }

    // 2) Resolve current meal (timing-driven), allow override
    const queryMeal = req.query.mealType;
    const timingCheck = checkMealTiming(mess.timings, queryMeal || null);
    const mealType =
      queryMeal === 'Lunch' || queryMeal === 'Dinner'
        ? queryMeal
        : timingCheck.currentMeal === 'Lunch' || timingCheck.currentMeal === 'Dinner'
        ? timingCheck.currentMeal
        : 'Lunch'; // default fallback

    const todayStart = startOfDay(new Date());

    // 3) Load eligible active monthly members for this meal (plan-based)
    const allMembers = await Membership.find({
      mess: mess._id,
      status: 'Active',
    })
      .select('_id user planName')
      .populate('user', 'name phone');

    const eligible = allMembers.filter((m) => {
      const plan = String(m.planName || '').toLowerCase();
      if (plan.includes('both')) return true;
      if (mealType === 'Lunch') return plan.includes('lunch');
      if (mealType === 'Dinner') return plan.includes('dinner');
      return false;
    });
    const eligibleIds = eligible.map((m) => m._id.toString());

    // 4) Today’s attendance for the resolved meal (monthly)
    const todays = await Attendance.find({
      mess: mess._id,
      date: todayStart,
      mealType,
      memberType: 'Monthly',
      membership: { $in: eligibleIds },
    })
      .select('user membership status')
      .populate('user', 'name phone')
      .populate('membership', '_id');

    const eaten = todays.filter((r) => r.status === 'Present');
    const skipped = todays.filter((r) => r.status === 'Skipped');
    const onLeave = todays.filter((r) => r.status === 'Leave');

    const eatenSet = new Set(eaten.map((r) => String(r.membership?._id || r.membership)));
    const skippedSet = new Set(skipped.map((r) => String(r.membership?._id || r.membership)));
    const leaveSet = new Set(onLeave.map((r) => String(r.membership?._id || r.membership)));
    const anyMarked = new Set([...eatenSet, ...skippedSet, ...leaveSet]);

    // 5) Remaining = eligible - anyMarked
    const remaining = eligible.filter((m) => !anyMarked.has(m._id.toString()));

    // 6) Daily members count (depending on mess service type)
    let dailyMembersCount = 0;
    if (String(mess.serviceType || '').toLowerCase().includes('daily')) {
      dailyMembersCount = await Attendance.countDocuments({
        mess: mess._id,
        date: todayStart,
        mealType,
        memberType: 'Daily',
        status: 'Present',
      });
    }

    // 7) Build lists for pop-ups (except Daily Members)
    const toMemberLite = (item) => ({
      _id: item.user?._id,
      name: item.user?.name,
      phone: item.user?.phone,
      membershipId: item.membership?._id || item.membership,
    });

    const eatenList = eaten.map(toMemberLite);
    const skippedList = skipped.map(toMemberLite);
    const leaveList = onLeave.map(toMemberLite);
    const remainingList = remaining.map((m) => ({
      _id: m.user?._id,
      name: m.user?.name,
      phone: m.user?.phone,
      membershipId: m._id,
    }));

    return res.status(200).json({
      success: true,
      mealType,
      data: {
        remaining: { count: remainingList.length, members: remainingList },
        eaten: { count: eatenList.length, members: eatenList },
        onLeave: { count: leaveList.length, members: leaveList },
        skipped: { count: skippedList.length, members: skippedList },
        dailyMembers: { count: dailyMembersCount }, // No pop-up
      },
    });
  } catch (error) {
    return next(error);
  }
};