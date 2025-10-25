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
    const messData = {
      ...req.body,
      owner: req.user.id
    };

    // Add image path if uploaded
    if (req.file) {
      messData.messImage = `/uploads/mess-images/${req.file.filename}`;
    }

    const mess = await Mess.create(messData);

    res.status(201).json({
      success: true,
      data: mess
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

// @desc    Get manager's mess
// @route   GET /api/mess/my-mess
// @access  Private (Manager only)
exports.getMyMess = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });

    if (!mess) {
      return res.status(404).json({
        success: false,
        message: 'No mess found for this manager'
      });
    }

    res.status(200).json({
      success: true,
      data: mess
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update manager's mess
// @route   PUT /api/mess/my-mess
// @access  Private (Manager only)
exports.updateMyMess = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });

    if (!mess) {
      return res.status(404).json({
        success: false,
        message: 'No mess found for this manager'
      });
    }

    // Update fields
    const allowedUpdates = [
      'messName', 'address', 'city', 'contactPhone', 'serviceType',
      'cuisine', 'maxCapacity', 'timings', 'plans', 'dailyThaliRate', 'rules'
    ];

    allowedUpdates.forEach(field => {
      if (req.body[field] !== undefined) {
        mess[field] = req.body[field];
      }
    });

    // Update image if uploaded
    if (req.file) {
      mess.messImage = `/uploads/mess-images/${req.file.filename}`;
    }

    await mess.save();

    res.status(200).json({
      success: true,
      data: mess,
      message: 'Mess updated successfully. Price changes will apply from next billing cycle.'
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
          maxDistance: 50000, // 50km radius
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
      return res.status(404).json({
        success: false,
        message: 'No mess found for this manager'
      });
    }

    // Get current meal and live status
    const { currentMeal, liveStatus } = checkMealTiming(mess.timings);

    // Get today's date range
    const { startOfDay, endOfDay } = getStartAndEndOfDay();

    // Count "Eating Now" - Present attendance for current meal
    const eatingNow = currentMeal !== 'None' 
      ? await Attendance.countDocuments({
          mess: mess._id,
          date: { $gte: startOfDay, $lte: endOfDay },
          mealType: currentMeal,
          status: 'Present'
        })
      : 0;

    // Count "On Leave" - Approved leaves for today
    const onLeave = await Leave.countDocuments({
      mess: mess._id,
      status: 'Approved',
      startDate: { $lte: endOfDay },
      endDate: { $gte: startOfDay }
    });

    // Count "Daily Members" - Daily walk-in meals today
    const dailyMembers = await Attendance.countDocuments({
      mess: mess._id,
      date: { $gte: startOfDay, $lte: endOfDay },
      status: 'Present',
      isDaily: true
    });

    // Count "Not Eating (Skipped)" - Skipped meals for current meal
    const notEating = currentMeal !== 'None'
      ? await Attendance.countDocuments({
          mess: mess._id,
          date: { $gte: startOfDay, $lte: endOfDay },
          mealType: currentMeal,
          status: 'Skipped'
        })
      : 0;

    // Get total active members count
    const totalActiveMembers = await Membership.countDocuments({
      mess: mess._id,
      status: 'Active'
    });

    res.status(200).json({
      success: true,
      data: {
        liveStatus,
        currentMeal,
        eatingNow,
        onLeave,
        dailyMembers,
        notEating,
        totalActiveMembers
      }
    });
  } catch (error) {
    next(error);
  }
};
