const Mess = require('../models/Mess');
const Membership = require('../models/Membership');
const Attendance = require('../models/Attendance');
const Leave = require('../models/Leave');
const { checkMealTiming, getStartAndEndOfDay } = require('../utils/billCalculation');

// @desc    Create new mess
// @route   POST /api/mess
// @access  Private (Manager only)

exports.createMess = async (req, res, next) => {


  try {
    let messData = { ...req.body };

    // --- Manually Parse Nested Fields (Crucial Now) ---
    const fieldsToParse = ['location', 'timings', 'rules', 'plans'];
    for (const key of fieldsToParse) {
      if (messData[key] && typeof messData[key] === 'string') {
        try {
          messData[key] = JSON.parse(messData[key]);
        } catch (e) {
          console.error(`!!! Failed to JSON parse field '${key}':`, e);
          // If parsing fails here, Mongoose validation will fail later due to type mismatch
           return res.status(400).json({ success: false, message: `Invalid JSON format for field: ${key}` }); // Fail fast
        }
      }
       // Add checks for missing required nested fields if needed, although Mongoose will catch them
       else if (!messData[key] && ['location', 'timings', 'rules', 'plans'].includes(key)) {
         console.warn(`Required nested field '${key}' might be missing.`);
       }
    }

    // --- Explicitly Convert Boolean String ---
    if (messData.tiffinService === 'true') {
      messData.tiffinService = true;
    } else if (messData.tiffinService === 'false') {
      messData.tiffinService = false;
    } else {
        // Let Mongoose handle the 'required: true' validation if it's missing or invalid
        console.warn(`tiffinService value before Mongoose: ${messData.tiffinService}`);
    }

     // Log basicThaliDetails (Mongoose will validate 'required: true')
     console.warn(`basicThaliDetails value before Mongoose: ${messData.basicThaliDetails}`);


    // --- Add Owner and Image ---
    messData.owner = req.user.id;
    if (req.file) {
      messData.messImage = `/uploads/mess-images/${req.file.filename}`;
    }
    // --- Create Mess Document (Mongoose handles final validation) ---
    const mess = await Mess.create(messData);

    res.status(201).json({
      success: true,
      data: mess
    });
  } catch (error) {
    console.error("Error during Mess.create or data processing:", error);
    if (error.name === 'ValidationError') {
      return res.status(400).json({ success: false, message: `Validation failed: ${error.message}`, errors: error.errors });
    }
    if (error.code === 11000) { /* ... */ }
    next(error);
  }
};

// ... (rest of controller)

// ... (rest of controller)

// @desc    Get manager's mess
// @route   GET /api/mess/my-mess
// @access  Private (Manager only)
// controllers/messController.js
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


// @desc    Update manager's mess
// @route   PUT /api/mess/my-mess
// @access  Private (Manager only)
// controllers/messController.js
exports.updateMyMess = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }

    // Collect only allowed fields for scheduling
    const allowedUpdates = [
      'messName', 'address', 'city', 'contactPhone', 'serviceType',
      'cuisine', 'maxCapacity', 'timings', 'plans', 'dailyThaliRate', 'rules'
    ];

    const updates = {};
    for (const field of allowedUpdates) {
      if (Object.prototype.hasOwnProperty.call(req.body, field)) {
        updates[field] = req.body[field];
      }
    }
    if (req.file) {
      updates.messImage = `/uploads/mess-images/${req.file.filename}`;
    }

    // Nothing to schedule
    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ success: false, message: 'No valid fields provided to update' });
    }

    // Compute first day of next month at 00:00
    const now = new Date();
    const nextMonthStart = new Date(Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth() + 1,
      1, 0, 0, 0, 0
    ));

    // Merge with any existing scheduled updates
    const existing = mess.scheduledUpdates || {};
    mess.scheduledUpdates = { ...existing, ...updates };

    // If there is no schedule or existing date is before nextMonthStart, set to next month
    if (!mess.scheduledEffectiveFrom || mess.scheduledEffectiveFrom < nextMonthStart) {
      mess.scheduledEffectiveFrom = nextMonthStart;
    }

    await mess.save();

    return res.status(200).json({
      success: true,
      data: {
        current: mess,             // current live values
        scheduledUpdates: mess.scheduledUpdates,
        scheduledEffectiveFrom: mess.scheduledEffectiveFrom,
      },
      message: 'Changes scheduled and will take effect from the next billing cycle (next month).'
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'A mess with this name and address already exists'
      });
    }
    next(error);
  }
};


// @desc    Discover messes (sorted by distance)
// @route   GET /api/mess/discover
// @access  Private (Customer only)
exports.discoverMesses = async (req, res, next) => {
  try {
    const { cuisine, serviceType, page = 1, limit = 10 } = req.query;

    // Build match conditions
    const matchConditions = {};
    if (cuisine) matchConditions.cuisine = cuisine;
    if (serviceType) matchConditions.serviceType = serviceType;

    // Get user's location
    const userLocation = req.user.location.coordinates;

    // Perform geospatial query
    const messes = await Mess.aggregate([
      {
        $geoNear: {
          near: {
            type: 'Point',
            coordinates: userLocation
          },
          distanceField: 'distance',
          maxDistance: 500000000, // 50km radius
          spherical: true
        }
      },
      ...(Object.keys(matchConditions).length > 0 ? [{ $match: matchConditions }] : []),
      {
        $lookup: {
          from: 'reviews',
          localField: '_id',
          foreignField: 'mess',
          as: 'reviews'
        }
      },
      {
        $addFields: {
          averageRating: { $avg: '$reviews.rating' },
          reviewCount: { $size: '$reviews' }
        }
      },
      {
        $project: {
          reviews: 0
        }
      },
      { $skip: (parseInt(page) - 1) * parseInt(limit) },
      { $limit: parseInt(limit) }
    ]);

    // Get total count
    const totalCount = await Mess.countDocuments(matchConditions);

    res.status(200).json({
      success: true,
      count: messes.length,
      total: totalCount,
      data: messes
    });
  } catch (error) {
    next(error);
  }
};

// new: GET /api/mess/dashboard/members-skipped
exports.getMembersSkipped = async (req,res,next) => {
  const mess = await Mess.findOne({ owner: req.user.id });
  if (!mess) return res.status(404).json({ success:false, message:'No mess found for this manager' });
  const { currentMeal } = checkMealTiming(mess.timings);
  if (currentMeal === 'None') return res.status(200).json({ success:true, count:0, data:[] });
  const { startOfDay, endOfDay } = getStartAndEndOfDay();
  const skipped = await Attendance.find({
    mess: mess._id, date: { $gte: startOfDay, $lte: endOfDay }, mealType: currentMeal, status: 'Skipped'
  }).populate('user','name phone');
  return res.status(200).json({ success:true, count: skipped.length, data: skipped, meal: currentMeal });
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

    // Get average rating
    const Review = require('../models/Review');
    const reviews = await Review.find({ mess: mess._id });
    const averageRating = reviews.length > 0
      ? reviews.reduce((sum, review) => sum + review.rating, 0) / reviews.length
      : 0;

    const messData = mess.toObject();
    messData.averageRating = averageRating;
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

    // *** FIXED ***: Removed 'status' check.
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

// @desc    Get members eating now (clickable stat details)
// @route   GET /api/mess/dashboard/members-eating
// @access  Private (Manager only)
exports.getMembersEating = async (req, res, next) => {
  // ... (existing code, no changes)
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

    // *** FIXED ***: Removed 'status: Approved' check
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
exports.getMembersSkipped = async (req, res, next) => {
  // ... (existing code, no changes)
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