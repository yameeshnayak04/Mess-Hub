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
    // or nested { lunch: {start,end}, dinner: {start,end} } — persist as flat for consistency
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

      updates.timings = { 
        ...mess.timings?.toObject?.() ?? mess.timings ?? {}, 
        ...flat 
      };
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

    // 1) Get user location or fallback
    let userLocation = req.user?.location?.coordinates;
    const hasValidPoint = Array.isArray(userLocation) && userLocation.length === 2 &&
                          userLocation.every(v => !Number.isNaN(Number(v)));
    
    if (!hasValidPoint) {
      userLocation = [73.8567, 18.5204]; // [lng, lat] - Pune center
    } else {
      userLocation = userLocation.map(Number);
    }

    // 2) Build optional filters
    const matchConditions = {};
    if (typeof cuisine === 'string' && cuisine.trim()) matchConditions.cuisine = cuisine.trim();
    if (typeof serviceType === 'string' && serviceType.trim()) matchConditions.serviceType = serviceType.trim();

    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const lim = parseInt(limit, 10);

    // *** FIX: Ensure all messes have valid location before geoNear ***
    // First check if there are any invalid locations
    const invalidCount = await Mess.countDocuments({
      $or: [
        { 'location.coordinates': { $exists: false } },
        { 'location.coordinates': { $not: { $size: 2 } } },
        { 'location.type': { $ne: 'Point' } }
      ]
    });

    // Add location validation to match conditions
    matchConditions['location.coordinates'] = { $exists: true, $size: 2 };
    matchConditions['location.type'] = 'Point';

    // 3) Aggregate: $geoNear with validated locations
    const messes = await Mess.aggregate([
      {
        $geoNear: {
          near: { type: 'Point', coordinates: userLocation },
          distanceField: 'distance',
          spherical: true,
          key: 'location'
          // no maxDistance so we list all messes
        }
      },
      { $match: matchConditions },
      { $lookup: { from: 'reviews', localField: '_id', foreignField: 'mess', as: 'reviews' } },
      { $addFields: { 
          averageRating: { $avg: '$reviews.rating' }, 
          reviewCount: { $size: '$reviews' } 
        } 
      },
      { $project: { reviews: 0 } },
      { $skip: skip },
      { $limit: lim }
    ]);

    // 4) Total count for pagination
    const total = await Mess.countDocuments(matchConditions);


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

    // Use configured timezone offset to decide current meal window
    const { currentMeal, liveStatus } = checkMealTiming(mess.timings, null, DEFAULT_TZ_OFFSET_MIN);
    const { startOfDay, endOfDay } = getStartAndEndOfDay(undefined, DEFAULT_TZ_OFFSET_MIN);

    // Default zeros (required: when no meal is active, show zeros)
    let eatingNow = 0;
    let onLeave = 0;
    let notEating = 0;
    let dailyMembers = 0;

    // Only compute attendance/leave/skipped counts while a meal window is active
    if (currentMeal !== 'None') {
      eatingNow = await Attendance.countDocuments({
        mess: mess._id,
        date: { $gte: startOfDay, $lte: endOfDay },
        mealType: currentMeal,
        status: 'Present',
        memberType: 'Monthly'
      });

      onLeave = await Leave.countDocuments({
        mess: mess._id,
        startDate: { $lte: endOfDay },
        endDate: { $gte: startOfDay }
      });

      notEating = await Attendance.countDocuments({
        mess: mess._id,
        date: { $gte: startOfDay, $lte: endOfDay },
        mealType: currentMeal,
        status: 'Skipped'
      });

      // dailyMembers only makes sense during an active meal window
      if (mess.serviceType === 'Both Daily & Monthly') {
        dailyMembers = await Attendance.countDocuments({
          mess: mess._id,
          date: { $gte: startOfDay, $lte: endOfDay },
          status: 'Present',
          memberType: 'Daily'
        });
      }
    }

    const totalActiveMembers = await Membership.countDocuments({
      mess: mess._id,
      status: 'Active'
    });

    const dashboardData = {
      liveStatus,
      currentMeal,
      eatingNow,
      onLeave,
      notEating,
      totalActiveMembers,
      dailyMembers
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