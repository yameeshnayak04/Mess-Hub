const Leave = require('../models/Leave');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const { calculateDaysDifference } = require('../utils/billCalculation');

// @desc    Apply for leave (with eligibility checks)
// @route   POST /api/leave/apply/:membershipId
// @access  Private (Customer only)
exports.applyForLeave = async (req, res, next) => {
  try {
    const { membershipId } = req.params;
    const { startDate, endDate } = req.body;

    // 1. Check membership
    const m = await Membership.findById(membershipId).populate('mess');
    if (!m) return res.status(404).json({ success: false, message: 'Membership not found' });
    if (m.user.toString() !== req.user.id) return res.status(403).json({ success: false, message: 'Not authorized' });
    if (m.status !== 'Active') return res.status(400).json({ success: false, message: 'Membership is not active' });

    const messRules = m.mess.rules;

    // 2. Validate dates (Rule 3: Next day onwards)
    const start = new Date(startDate);
    const end = new Date(endDate);
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);

    if (start < tomorrow) {
      return res.status(400).json({ success: false, message: 'Start date must be at least tomorrow' });
    }

    // 3. Validate dates (Rule 1: Within same month)
    if (start.getMonth() !== end.getMonth() || start.getFullYear() !== end.getFullYear()) {
      return res.status(400).json({ success: false, message: 'Start and end date must be in the same month' });
    }

    // 4. Validate duration (Rule 2: Min continuous days)
    const minDays = messRules.minLeaveDaysForRebate || 1;
    const leaveDuration = calculateDaysDifference(start, end);

    if (leaveDuration < minDays) {
      return res.status(400).json({
        success: false,
        message: `Leave must be for at least ${minDays} continuous days to be eligible for rebate.`,
      });
    }

    // 5. Validate overlap (Rule 4: Other constraints)
    const overlap = await Leave.findOne({
      user: req.user.id,
      mess: m.mess._id,
      $or: [{ startDate: { $lte: end }, endDate: { $gte: start } }],
    });

    if (overlap) {
      return res.status(400).json({ success: false, message: 'This leave request overlaps with an existing leave.' });
    }

    // All checks passed, create the leave
    const leave = await Leave.create({
      user: req.user.id,
      mess: m.mess._id,
      startDate: start,
      endDate: end,
    });
    
    const populated = await Leave.findById(leave._id).populate('mess', 'messName');
    
    return res.status(201).json({
      success: true,
      data: populated,
      message: 'Leave successfully recorded.'
    });

  } catch (error) {
    next(error);
  }
};

// @desc    Get customer's own leaves
// @route   GET /api/leave/my/:membershipId
// @access  Private (Customer only)
exports.getMyLeaves = async (req, res, next) => {
  const m = await Membership.findById(req.params.membershipId);
  if (!m) return res.status(404).json({ success: false, message: 'Membership not found' });
  if (m.user.toString() !== req.user.id) return res.status(403).json({ success: false, message: 'Not authorized' });
  
  const leaves = await Leave.find({ user: req.user.id, mess: m.mess }).sort({ startDate: -1 });
  return res.status(200).json({ success: true, count: leaves.length, data: leaves });
};

// @desc    Get all leave records for manager's mess
// @route   GET /api/leave/mess-leaves
// @access  Private (Manager only)
exports.getMessLeaves = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }

    const leaves = await Leave.find({ mess: mess._id })
      .populate('user', 'name phone')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: leaves.length,
      data: leaves
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get leave history for a specific member
// @route   GET /api/leave/member/:membershipId
// @access  Private (Manager only)
exports.getMemberLeaves = async (req, res, next) => {
  try {
    const membership = await Membership.findById(req.params.membershipId);
    if (!membership) {
      return res.status(404).json({ success: false, message: 'Membership not found' });
    }

    const mess = await Mess.findOne({ owner: req.user.id, _id: membership.mess });
    if (!mess) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const leaves = await Leave.find({
      user: membership.user,
      mess: membership.mess
    }).sort({ startDate: -1 });

    res.status(200).json({ success: true, count: leaves.length, data: leaves });
  } catch (error) {
    next(error);
  }
};