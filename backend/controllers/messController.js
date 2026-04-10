const Mess = require('../models/Mess');
const Membership = require('../models/Membership');
const Attendance = require('../models/Attendance');
const Leave = require('../models/Leave');
const { checkMealTiming, getStartAndEndOfDay, DEFAULT_TZ_OFFSET_MIN } = require('../utils/billCalculation');

function decorateWithIsOpen(doc) {
  const tz = DEFAULT_TZ_OFFSET_MIN; // 330 (IST)
  const now = new Date();
  const lunch = checkMealTiming(doc.timings, 'Lunch', tz, now);
  const dinner = checkMealTiming(doc.timings, 'Dinner', tz, now);
  const isOpen = (lunch.hasWindow && lunch.isWithin) || (dinner.hasWindow && dinner.isWithin);
  return { ...doc.toObject(), isOpen };
}

// @desc Create new mess
// @route POST /api/mess
// @access Private (Manager only)
exports.createMess = async (req, res, next) => {
  try {
    // controllers/messController.js — inside createMess before Mess.create
    let messData = { ...req.body, owner: req.user.id };
      
    // If upload middleware provided a Cloudinary URL
    if (req.file && req.file.cloudinaryUrl) {
      messData.messImage = req.file.cloudinaryUrl;
    }
    
    // Validate/normalize GeoJSON location shape
    if (!messData.location || messData.location.type !== 'Point' || !Array.isArray(messData.location.coordinates)) {
      return res.status(400).json({ success: false, message: 'location must be GeoJSON Point with coordinates [lng, lat]' });
    }
    messData.location.coordinates = messData.location.coordinates.map(Number);
    
    // Basic required strings
    ['messName','address','city','contactPhone'].forEach(f => {
      if (typeof messData[f] !== 'string' || !messData[f].trim()) {
        return res.status(400).json({ success: false, message: `Field '${f}' is required` });
      }
    });
    
    // Coerce tiffinService boolean
    if (typeof messData.tiffinService !== 'boolean') {
      if (typeof messData.tiffinService === 'string') {
        messData.tiffinService = messData.tiffinService.toLowerCase() === 'true';
      } else {
        messData.tiffinService = false;
      }
    }
    
    // Enforce HH:MM for timings if present
    const hhmm = /^([01]\d|2[0-3]):([0-5]\d)$/;
    const checkSlot = (slot) => slot && hhmm.test(slot.start) && hhmm.test(slot.end);
    if (messData.timings) {
      const { lunch, dinner } = messData.timings;
      if ((lunch && !checkSlot(lunch)) || (dinner && !checkSlot(dinner))) {
        return res.status(400).json({ success: false, message: 'timings must use HH:MM format (e.g., 12:30)' });
      }
    }
    
    // Ensure plans array shape and numeric rate
    if (!Array.isArray(messData.plans) || messData.plans.length === 0) {
      return res.status(400).json({ success: false, message: 'At least one plan is required' });
    }
    messData.plans = messData.plans.map(p => ({ name: String(p.name || '').trim(), rate: Number(p.rate || 0) }));


    const mess = await Mess.create(messData);
    return res.status(201).json({ success: true, data: mess });
  } catch (error) {
    if (error.name === 'ValidationError') {
      return res.status(400).json({ success: false, message: `Validation failed: ${error.message}`, errors: error.errors });
    }
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'A mess with this name and address already exists' });
    }
    return next(error);
  }
};

// @desc    Get manager's mess
// @route   GET /api/mess/my-mess
// @access  Private (Manager only)
exports.getMyMess = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }

    // Remove auto-apply scheduling (apply-now model)
    return res.status(200).json({ success: true, data: mess });
  } catch (error) {
    next(error);
  }
};


// @desc Update manager's mess (apply changes immediately)
// @route PUT /api/mess/my-mess
// @access Private (Manager only)
exports.updateMyMess = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res
        .status(404)
        .json({ success: false, message: 'No mess found for this manager' });
    }

    // Only allow non-structural fields to be changed
    const allowedUpdates = [
      'address',
      'contactPhone',
      'maxCapacity',
      'timings',
      'plans',
      'dailyThaliRate',
      'rules',
      'tiffinService',
      'basicThaliDetails',
    ];

    const body = req.body || {};
    const updates = {};

    // Pick allowed top-level fields only
    for (const field of allowedUpdates) {
      if (Object.prototype.hasOwnProperty.call(body, field)) {
        updates[field] = body[field];
      }
    }

    // Coerce types and validate fields

    // Booleans
    if (Object.prototype.hasOwnProperty.call(updates, 'tiffinService')) {
      if (typeof updates.tiffinService === 'string') {
        updates.tiffinService = updates.tiffinService.toLowerCase() === 'true';
      } else {
        updates.tiffinService = !!updates.tiffinService;
      }
    }

    // Numbers
    if (Object.prototype.hasOwnProperty.call(updates, 'maxCapacity')) {
      const n = Number(updates.maxCapacity);
      if (!Number.isFinite(n) || n < 0) {
        return res.status(400).json({ success: false, message: 'maxCapacity must be a positive number' });
      }
      updates.maxCapacity = n;
    }
    if (Object.prototype.hasOwnProperty.call(updates, 'dailyThaliRate')) {
      const n = Number(updates.dailyThaliRate);
      if (!Number.isFinite(n) || n < 0) {
        return res.status(400).json({ success: false, message: 'dailyThaliRate must be a positive number' });
      }
      updates.dailyThaliRate = n;
    }

    // Timings: accept flat keys (lunchStart, lunchEnd, dinnerStart, dinnerEnd)
    // or nested { lunch: {start,end}, dinner: {start,end} } — persist in nested schema shape
    if (Object.prototype.hasOwnProperty.call(updates, 'timings')) {
      const t = updates.timings || {};
      const hhmm = /^([01]\d|2[0-3]):([0-5]\d)$/;

      let flat = {};
      if (t && typeof t === 'object') {
        if (typeof t.lunchStart === 'string') flat.lunchStart = t.lunchStart;
        if (typeof t.lunchEnd === 'string') flat.lunchEnd = t.lunchEnd;
        if (typeof t.dinnerStart === 'string') flat.dinnerStart = t.dinnerStart;
        if (typeof t.dinnerEnd === 'string') flat.dinnerEnd = t.dinnerEnd;

        // Support nested shape
        if (t.lunch && typeof t.lunch.start === 'string') flat.lunchStart = t.lunch.start;
        if (t.lunch && typeof t.lunch.end === 'string') flat.lunchEnd = t.lunch.end;
        if (t.dinner && typeof t.dinner.start === 'string') flat.dinnerStart = t.dinner.start;
        if (t.dinner && typeof t.dinner.end === 'string') flat.dinnerEnd = t.dinner.end;
      }

      for (const key of ['lunchStart', 'lunchEnd', 'dinnerStart', 'dinnerEnd']) {
        if (flat[key] != null && !hhmm.test(String(flat[key]))) {
          return res.status(400).json({ success: false, message: `timings.${key} must be HH:MM` });
        }
      }

      // Server-side constraints:
      // - lunch must be start < end
      // - dinner must be start < end
      // - lunch must start before dinner and end before (or at) dinner start (no overlap)
      const toMin = (s) => {
        if (!s || typeof s !== 'string' || !hhmm.test(s)) return null;
        const [h, m] = s.split(':').map(Number);
        return h * 60 + m;
      };

      const current = mess.timings?.toObject?.() ?? mess.timings ?? {};
      const next = {
        lunch: { ...(current.lunch || {}) },
        dinner: { ...(current.dinner || {}) },
      };

      if (flat.lunchStart != null) next.lunch.start = String(flat.lunchStart);
      if (flat.lunchEnd != null) next.lunch.end = String(flat.lunchEnd);
      if (flat.dinnerStart != null) next.dinner.start = String(flat.dinnerStart);
      if (flat.dinnerEnd != null) next.dinner.end = String(flat.dinnerEnd);

      const ls = toMin(next.lunch.start);
      const le = toMin(next.lunch.end);
      const ds = toMin(next.dinner.start);
      const de = toMin(next.dinner.end);

      if ([ls, le, ds, de].some((v) => v == null)) {
        return res.status(400).json({ success: false, message: 'timings.lunch and timings.dinner must include valid start/end times' });
      }
      if (!(ls < le)) {
        return res.status(400).json({ success: false, message: 'Lunch start must be before lunch end' });
      }
      if (!(ds < de)) {
        return res.status(400).json({ success: false, message: 'Dinner start must be before dinner end' });
      }
      if (!(ls < ds && le <= ds)) {
        return res.status(400).json({ success: false, message: 'Lunch must end before dinner starts (no overlap)' });
      }

      updates.timings = next;
    }

    // Rules object (coerce numeric where applicable)
    if (Object.prototype.hasOwnProperty.call(updates, 'rules')) {
      const r = updates.rules || {};
      const numKeys = [
        'minLeaveDaysForRebate',
        'rebatePerThali',
        'skipAllowancePercent',
        'minMonthlyCharge',
      ];
      const boolKeys = ['allowAbsentRebate'];
      const coerced = { ...(mess.rules?.toObject?.() ?? mess.rules ?? {}), ...r };
      for (const k of numKeys) {
        if (Object.prototype.hasOwnProperty.call(coerced, k)) {
          const n = Number(coerced[k]);
          if (!Number.isFinite(n) || n < 0) {
            return res.status(400).json({ success: false, message: `rules.${k} must be a positive number` });
          }
          coerced[k] = n;
        }
      }
      for (const k of boolKeys) {
        if (Object.prototype.hasOwnProperty.call(coerced, k)) {
          const v = coerced[k];
          coerced[k] = v === true || v === 'true';
        }
      }
      updates.rules = coerced;
    }

    // Plans array (objects with name/rate or _id/rate)
    if (Object.prototype.hasOwnProperty.call(updates, 'plans')) {
      if (!Array.isArray(updates.plans)) {
        return res.status(400).json({ success: false, message: 'plans must be an array' });
      }
      // If only rates updated, keep names; coerce rate number
      const byId = new Map((mess.plans || []).map(p => [String(p._id || ''), p]));
      const newPlans = updates.plans.map(p => {
        const id = p._id ? String(p._id) : null;
        const rateNum = Number(p.rate ?? 0);
        if (!Number.isFinite(rateNum) || rateNum < 0) {
          throw new Error('Plan rate must be a positive number');
        }
        if (id && byId.has(id)) {
          const existing = byId.get(id);
          return { ...existing.toObject?.() ?? existing, rate: rateNum, name: p.name ?? existing.name };
        }
        // If no id, accept name + rate
        return { name: String(p.name || '').trim(), rate: rateNum };
      });
      updates.plans = newPlans;
    }

    // Assign simple fields
    if (Object.prototype.hasOwnProperty.call(updates, 'address')) mess.address = String(updates.address || '').trim();
    if (Object.prototype.hasOwnProperty.call(updates, 'contactPhone')) mess.contactPhone = String(updates.contactPhone || '').trim();
    if (Object.prototype.hasOwnProperty.call(updates, 'maxCapacity')) mess.maxCapacity = updates.maxCapacity;
    if (Object.prototype.hasOwnProperty.call(updates, 'dailyThaliRate')) mess.dailyThaliRate = updates.dailyThaliRate;
    if (Object.prototype.hasOwnProperty.call(updates, 'basicThaliDetails')) mess.basicThaliDetails = String(updates.basicThaliDetails || '').trim();
    if (Object.prototype.hasOwnProperty.call(updates, 'tiffinService')) mess.tiffinService = updates.tiffinService;
    if (Object.prototype.hasOwnProperty.call(updates, 'timings')) mess.timings = updates.timings;
    if (Object.prototype.hasOwnProperty.call(updates, 'rules')) mess.rules = updates.rules;
    if (Object.prototype.hasOwnProperty.call(updates, 'plans')) mess.plans = updates.plans;

    // Image (Cloudinary URL) if uploaded
    if (req.file && req.file.cloudinaryUrl) {
      mess.messImage = req.file.cloudinaryUrl;
    }

    await mess.save();

    return res.status(200).json({
      success: true,
      data: mess,
      message: 'Changes saved successfully',
    });
  } catch (error) {
    if (error.message && error.message.includes('Plan rate')) {
      return res.status(400).json({ success: false, message: error.message });
    }
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'A mess with this name and address already exists' });
    }
    return next(error);
  }
};


// @desc Discover messes (all, sorted by distance)
// @route GET /api/mess/discover
// @access Private (Customer only)
exports.discoverMesses = async (req, res, next) => {
  try {
    const { cuisine, serviceType, page = 1, limit = 10 } = req.query;
    const pageNum = Math.max(parseInt(page, 10) || 1, 1);
    const limitNum = Math.max(parseInt(limit, 10) || 10, 1);
    const skip = (pageNum - 1) * limitNum;

    // 1) Get user location or fallback
    let userLocation = req.user?.location?.coordinates;
    const hasValidPoint = Array.isArray(userLocation) && userLocation.length === 2 &&
      userLocation.every((v) => !Number.isNaN(Number(v)));

    if (!hasValidPoint) {
      userLocation = [73.8567, 18.5204]; // [lng, lat] - Pune center
    } else {
      userLocation = userLocation.map(Number);
    }

    // 2) Build optional filters
    const match = {};
    if (cuisine) match.cuisine = cuisine;
    if (serviceType) match.serviceType = serviceType;

    const messes = await Mess.aggregate([
      {
        $geoNear: {
          near: { type: 'Point', coordinates: userLocation },
          distanceField: 'distance',
          spherical: true,
          key: 'location',
          query: match,
        },
      },
      {
        $lookup: {
          from: 'reviews',
          let: { messId: '$_id' },
          pipeline: [
            { $match: { $expr: { $eq: ['$mess', '$$messId'] } } },
            { $group: { _id: null, avg: { $avg: '$rating' }, count: { $sum: 1 } } },
          ],
          as: 'reviewStats',
        },
      },
      {
        $addFields: {
          averageRating: { $ifNull: [{ $arrayElemAt: ['$reviewStats.avg', 0] }, 0] },
          reviewCount: { $ifNull: [{ $arrayElemAt: ['$reviewStats.count', 0] }, 0] },
        },
      },
      { $project: { reviewStats: 0, plans: 0, rules: 0 } },
      { $skip: skip },
      { $limit: limitNum },
    ]);

    // 4) Total count for pagination
    const total = await Mess.countDocuments(match);

    return res.status(200).json({ success: true, count: messes.length, total, data: messes });
  } catch (error) {
    next(error);
  }
};



// @desc    Get mess by ID
// @route   GET /api/mess/:messId
// @access  Private
exports.getMessById = async (req, res, next) => {
  try {
    const mess = await Mess.findById(req.params.messId);

    if (!mess) {
      return res.status(404).json({
        success: false,
        message: 'Mess not found'
      });
    }

    const Review = require('../models/Review');
    const reviews = await Review.find({ mess: mess._id });
    const averageRating = reviews.length > 0
      ? reviews.reduce((sum, review) => sum + review.rating, 0) / reviews.length
      : 0;

    const messData = mess.toObject();
    messData.averageRating = Number(averageRating.toFixed(1));
    messData.reviewCount = reviews.length;

    res.status(200).json({
      success: true,
      data: messData
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get manager dashboard stats
// @route   GET /api/mess/my-mess/dashboard
// @access  Private (Manager only)
exports.getDashboardStats = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }

    const tz = DEFAULT_TZ_OFFSET_MIN;
    const now = new Date();

    // Determine current meal window in configured timezone
    const timingCheck = checkMealTiming(mess.timings, null, tz, now);
    const currentMeal = timingCheck.currentMeal;

    // Determine the next meal when no meal is currently active.
    const parseHM = (s) => {
      if (!s || typeof s !== 'string') return null;
      const parts = s.split(':');
      if (parts.length < 2) return null;
      const hh = parseInt(parts[0], 10);
      const mm = parseInt(parts[1], 10);
      if (Number.isNaN(hh) || Number.isNaN(mm)) return null;
      return (hh % 24) * 60 + (mm % 60);
    };

    const localNow = Number.isFinite(timingCheck.nowMin) ? timingCheck.nowMin : null;
    const lunchStart = parseHM(mess.timings?.lunch?.start);
    const lunchEnd = parseHM(mess.timings?.lunch?.end);
    const dinnerStart = parseHM(mess.timings?.dinner?.start);
    const dinnerEnd = parseHM(mess.timings?.dinner?.end);

    const resolveNextMeal = () => {
      // Default to Lunch if timings are missing.
      if (!Number.isInteger(localNow)) return { meal: 'Lunch', dayOffset: 0 };

      // If both meals exist
      if (Number.isInteger(lunchStart) && Number.isInteger(dinnerStart)) {
        if (localNow < lunchStart) return { meal: 'Lunch', dayOffset: 0 };
        if (localNow < dinnerStart) return { meal: 'Dinner', dayOffset: 0 };
        // After dinner start: if dinnerEnd exists and we're after it, next is tomorrow's Lunch
        if (Number.isInteger(dinnerEnd) && localNow > dinnerEnd) {
          return { meal: 'Lunch', dayOffset: 1 };
        }
        // Otherwise (between dinnerStart and dinnerEnd) we'd be within dinner; fallback
        return { meal: 'Dinner', dayOffset: 0 };
      }

      // Only lunch configured
      if (Number.isInteger(lunchStart)) {
        if (localNow < lunchStart) return { meal: 'Lunch', dayOffset: 0 };
        if (Number.isInteger(lunchEnd) && localNow > lunchEnd) return { meal: 'Lunch', dayOffset: 1 };
        return { meal: 'Lunch', dayOffset: 0 };
      }

      // Only dinner configured
      if (Number.isInteger(dinnerStart)) {
        if (localNow < dinnerStart) return { meal: 'Dinner', dayOffset: 0 };
        if (Number.isInteger(dinnerEnd) && localNow > dinnerEnd) return { meal: 'Dinner', dayOffset: 1 };
        return { meal: 'Dinner', dayOffset: 0 };
      }

      return { meal: 'Lunch', dayOffset: 0 };
    };

    const nextMealInfo = currentMeal === 'None' ? resolveNextMeal() : null;
    const nextMeal = nextMealInfo?.meal;

    const statsMeal = currentMeal !== 'None' ? currentMeal : (nextMeal || 'Lunch');
    const statsDate = nextMealInfo?.dayOffset ? new Date(now.getTime() + nextMealInfo.dayOffset * 24 * 60 * 60 * 1000) : now;
    const { startOfDay, endOfDay } = getStartAndEndOfDay(statsDate, tz);

    // Eligible monthly members for this meal (plan-based)
    const allActiveMembers = await Membership.find({ mess: mess._id, status: 'Active' }).select('_id planName');
    const eligibleMembershipIds = allActiveMembers
      .filter((m) => {
        const plan = String(m.planName || '').toLowerCase();
        if (plan.includes('both')) return true;
        if (statsMeal === 'Lunch') return plan.includes('lunch');
        if (statsMeal === 'Dinner') return plan.includes('dinner');
        return false;
      })
      .map((m) => m._id);

    const totalActiveMembers = eligibleMembershipIds.length;

    // Counts (include pre-meal skips / leave that are already marked for the meal)
    const [eatingNow, notEating, onLeave] = await Promise.all([
      Attendance.countDocuments({
        mess: mess._id,
        date: startOfDay,
        mealType: statsMeal,
        status: 'Present',
        memberType: 'Monthly',
        membership: { $in: eligibleMembershipIds },
      }),
      Attendance.countDocuments({
        mess: mess._id,
        date: startOfDay,
        mealType: statsMeal,
        status: 'Skipped',
        memberType: 'Monthly',
        membership: { $in: eligibleMembershipIds },
      }),
      Attendance.countDocuments({
        mess: mess._id,
        date: startOfDay,
        mealType: statsMeal,
        status: 'Leave',
        memberType: 'Monthly',
        membership: { $in: eligibleMembershipIds },
      }),
    ]);

    // Daily members only makes sense during an active meal window
    let dailyMembers = 0;
    if (currentMeal !== 'None' && mess.serviceType === 'Both Daily & Monthly') {
      dailyMembers = await Attendance.countDocuments({
        mess: mess._id,
        date: startOfDay,
        mealType: currentMeal,
        status: 'Present',
        memberType: 'Daily',
      });
    }

    const liveStatus = currentMeal !== 'None' ? 'Open' : 'Closed';

    const dashboardData = {
      liveStatus,
      currentMeal,
      nextMeal,
      eatingNow,
      onLeave,
      notEating,
      totalActiveMembers,
      dailyMembers,
    };

    res.status(200).json({ success: true, data: dashboardData });
  } catch (error) {
    next(error);
  }
};

// @desc    Get members remaining (not eaten, not skipped, not on leave)
// @route   GET /api/mess/dashboard/members-remaining
// @access  Private (Manager only)
exports.getMembersRemaining = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }

    const { currentMeal } = checkMealTiming(mess.timings);
    if (currentMeal === 'None') {
      return res.status(200).json({ success: true, count: 0, data: [], message: 'No active meal at the moment' });
    }

    const { startOfDay, endOfDay } = getStartAndEndOfDay();

    // 1. Get IDs of users who have taken action
    const eating = await Attendance.find({
      mess: mess._id,
      date: { $gte: startOfDay, $lte: endOfDay },
      mealType: currentMeal,
      status: 'Present',
      memberType: 'Monthly'
    }).select('user');

    const skipped = await Attendance.find({
      mess: mess._id,
      date: { $gte: startOfDay, $lte: endOfDay },
      mealType: currentMeal,
      status: 'Skipped'
    }).select('user');

    const onLeave = await Leave.find({
      mess: mess._id,
      startDate: { $lte: endOfDay },
      endDate: { $gte: startOfDay }
    }).select('user');

    const actionTakenUserIds = new Set([
      ...eating.map(a => a.user.toString()),
      ...skipped.map(a => a.user.toString()),
      ...onLeave.map(l => l.user.toString())
    ]);

    // 2. Get all active members
    const allActiveMembers = await Membership.find({
      mess: mess._id,
      status: 'Active'
    }).populate('user', 'name phone');

    // 3. Filter out those who have taken action
    const remainingMembers = allActiveMembers.filter(member =>
      member.user && !actionTakenUserIds.has(member.user._id.toString())
    );

    // Format data to match other dialogs (user nested)
    const formattedData = remainingMembers.map(m => ({
        _id: m._id, // membership ID
        user: m.user  // populated user object
    }));

    res.status(200).json({
      success: true,
      count: formattedData.length,
      data: formattedData,
      meal: currentMeal
    });

  } catch (error) {
    next(error);
  }
};

// @desc    Get members eating now (clickable stat details)
// @route   GET /api/mess/dashboard/members-eating
// @access  Private (Manager only)
exports.getMembersEating = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }
    const { currentMeal } = checkMealTiming(mess.timings);
    if (currentMeal === 'None') {
      return res.status(200).json({ success: true, count: 0, data: [], message: 'No active meal at the moment' });
    }
    const { startOfDay, endOfDay } = getStartAndEndOfDay();
    const attendanceRecords = await Attendance.find({
      mess: mess._id,
      date: { $gte: startOfDay, $lte: endOfDay },
      mealType: currentMeal,
      status: 'Present',
      memberType: 'Monthly'
    }).populate('user', 'name phone');
    res.status(200).json({ success: true, count: attendanceRecords.length, data: attendanceRecords, meal: currentMeal });
  } catch (error) { next(error); }
};

// @desc    Get members on leave (clickable stat details)
// @route   GET /api/mess/dashboard/members-on-leave
// @access  Private (Manager only)
exports.getMembersOnLeave = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }

    const { startOfDay, endOfDay } = getStartAndEndOfDay();

    const leaveRecords = await Leave.find({
      mess: mess._id,
      startDate: { $lte: endOfDay },
      endDate: { $gte: startOfDay }
    }).populate('user', 'name phone');

    res.status(200).json({
      success: true,
      count: leaveRecords.length,
      data: leaveRecords
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get members who skipped current meal (clickable stat details)
// @route   GET /api/mess/dashboard/members-skipped
// @access  Private (Manager only)
// NOTE: This function was duplicated. Removing the first instance.
exports.getMembersSkipped = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }
    const { currentMeal } = checkMealTiming(mess.timings);
    if (currentMeal === 'None') {
      return res.status(200).json({ success: true, count: 0, data: [], message: 'No active meal at the moment' });
    }
    const { startOfDay, endOfDay } = getStartAndEndOfDay();
    const attendanceRecords = await Attendance.find({
      mess: mess._id,
      date: { $gte: startOfDay, $lte: endOfDay },
      mealType: currentMeal,
      status: 'Skipped'
    }).populate('user', 'name phone');
    res.status(200).json({ success: true, count: attendanceRecords.length, data: attendanceRecords, meal: currentMeal });
  } catch (error) { next(error); }
};