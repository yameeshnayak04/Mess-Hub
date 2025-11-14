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

// @desc Update manager's mess
// @route PUT /api/mess/my-mess
// @access Private (Manager only)
exports.updateMyMess = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) return res.status(404).json({ success: false, message: 'No mess found for this manager' });

    const allowedUpdates = [
      'messName', 'address', 'city', 'contactPhone', 'serviceType',
      'cuisine', 'maxCapacity', 'timings', 'plans', 'dailyThaliRate', 'rules',
      'tiffinService', 'basicThaliDetails'
    ];
    const updates = {};
    for (const field of allowedUpdates) {
      if (Object.prototype.hasOwnProperty.call(req.body, field)) updates[field] = req.body[field];
    }
    if (req.body.tiffinService === 'true') updates.tiffinService = true;
    else if (req.body.tiffinService === 'false') updates.tiffinService = false;

    // Use Cloudinary URL if a file was uploaded
    if (req.file && req.file.cloudinaryUrl) {
      updates.messImage = req.file.cloudinaryUrl;
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ success: false, message: 'No valid fields provided to update' });
    }

    // Schedule changes for next month as in your original logic
    const now = new Date();
    const nextMonthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1, 0, 0, 0, 0));
    const existing = mess.scheduledUpdates || {};
    mess.scheduledUpdates = { ...existing, ...updates };
    if (!mess.scheduledEffectiveFrom || mess.scheduledEffectiveFrom < nextMonthStart) {
      mess.scheduledEffectiveFrom = nextMonthStart;
    }
    await mess.save();

    return res.status(200).json({
      success: true,
      data: {
        current: mess,
        scheduledUpdates: mess.scheduledUpdates,
        scheduledEffectiveFrom: mess.scheduledEffectiveFrom,
      },
      message: 'Changes scheduled and will take effect from the next billing cycle (next month).'
    });
  } catch (error) {
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

    // Auto-apply scheduled updates if due
    if (mess.scheduledEffectiveFrom && new Date() >= mess.scheduledEffectiveFrom) {
      const updates = mess.scheduledUpdates || {};
      for (const [k, v] of Object.entries(updates)) mess[k] = v;
      mess.scheduledUpdates = {};
      mess.scheduledEffectiveFrom = undefined;
      await mess.save();
    }

    return res.status(200).json({ success: true, data: mess });
  } catch (error) {
    next(error);
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

    const { currentMeal, liveStatus } = checkMealTiming(mess.timings);
    const { startOfDay, endOfDay } = getStartAndEndOfDay();

    const eatingNow = currentMeal !== 'None' ? await Attendance.countDocuments({
      mess: mess._id,
      date: { $gte: startOfDay, $lte: endOfDay },
      mealType: currentMeal,
      status: 'Present',
      memberType: 'Monthly'
    }) : 0;

    const onLeave = await Leave.countDocuments({
      mess: mess._id,
      startDate: { $lte: endOfDay },
      endDate: { $gte: startOfDay }
    });

    const notEating = currentMeal !== 'None' ? await Attendance.countDocuments({
      mess: mess._id,
      date: { $gte: startOfDay, $lte: endOfDay },
      mealType: currentMeal,
      status: 'Skipped'
    }) : 0;

    const totalActiveMembers = await Membership.countDocuments({
      mess: mess._id,
      status: 'Active'
    });

    const dashboardData = {
      liveStatus, currentMeal, eatingNow, onLeave, notEating, totalActiveMembers
    };

    if (mess.serviceType === 'Both Daily & Monthly') {
      const dailyMembers = await Attendance.countDocuments({
        mess: mess._id,
        date: { $gte: startOfDay, $lte: endOfDay },
        status: 'Present',
        memberType: 'Daily'
      });
      dashboardData.dailyMembers = dailyMembers;
    }

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