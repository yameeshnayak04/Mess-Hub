const Leave = require('../models/Leave');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const { calculateDaysDifference } = require('../utils/billCalculation');

// @desc    Apply for leave
// @route   POST /api/leave/apply/:membershipId
// @access  Private (Customer only)
exports.applyForLeave = async (req, res, next) => {
  try {
    const { membershipId } = req.params;
    const { startDate, endDate } = req.body;

    // Find membership
    const membership = await Membership.findById(membershipId);

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

    // Validate dates
    const start = new Date(startDate);
    const end = new Date(endDate);
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);

    if (start < tomorrow) {
      return res.status(400).json({
        success: false,
        message: 'Start date must be at least tomorrow'
      });
    }

    // Check if both dates are in same month
    if (start.getMonth() !== end.getMonth() || start.getFullYear() !== end.getFullYear()) {
      return res.status(400).json({
        success: false,
        message: 'Start and end date must be in the same month'
      });
    }

    // Check for overlapping leaves
    const overlappingLeave = await Leave.findOne({
      user: req.user.id,
      mess: membership.mess,
      status: { $in: ['Pending', 'Approved'] },
      $or: [
        { startDate: { $lte: end }, endDate: { $gte: start } }
      ]
    });

    if (overlappingLeave) {
      return res.status(400).json({
        success: false,
        message: 'You already have a leave request for overlapping dates'
      });
    }

    // Create leave request
    const leave = await Leave.create({
      user: req.user.id,
      mess: membership.mess,
      startDate: start,
      endDate: end,
      status: 'Pending'
    });

    const populatedLeave = await Leave.findById(leave._id)
      .populate('mess', 'messName');

    res.status(201).json({
      success: true,
      data: populatedLeave,
      message: 'Leave application submitted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get leave requests for manager's mess
// @route   GET /api/leave/requests/my-mess
// @access  Private (Manager only)
exports.getLeaveRequests = async (req, res, next) => {
  try {
    // Find manager's mess
    const mess = await Mess.findOne({ owner: req.user.id });

    if (!mess) {
      return res.status(404).json({
        success: false,
        message: 'No mess found for this manager'
      });
    }

    // Get pending leave requests
    const leaveRequests = await Leave.find({
      mess: mess._id,
      status: 'Pending'
    })
      .populate('user', 'name phone')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: leaveRequests.length,
      data: leaveRequests
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Approve leave
// @route   PUT /api/leave/approve/:leaveId
// @access  Private (Manager only)
exports.approveLeave = async (req, res, next) => {
  try {
    const leave = await Leave.findById(req.params.leaveId);

    if (!leave) {
      return res.status(404).json({
        success: false,
        message: 'Leave request not found'
      });
    }

    // Verify manager owns the mess
    const mess = await Mess.findOne({ _id: leave.mess, owner: req.user.id });

    if (!mess) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to approve this leave'
      });
    }

    // Calculate duration
    const duration = calculateDaysDifference(leave.startDate, leave.endDate);

    // Check if eligible for rebate
    const isEligible = duration >= mess.rules.minLeaveDaysForRebate;

    leave.status = 'Approved';
    leave.isRebateEligible = isEligible;
    await leave.save();

    const populatedLeave = await Leave.findById(leave._id)
      .populate('user', 'name phone');

    res.status(200).json({
      success: true,
      data: populatedLeave,
      message: isEligible 
        ? 'Leave approved. Rebate will be applied in billing.' 
        : 'Leave approved. Duration is less than minimum required for rebate.'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Reject leave
// @route   PUT /api/leave/reject/:leaveId
// @access  Private (Manager only)
exports.rejectLeave = async (req, res, next) => {
  try {
    const leave = await Leave.findById(req.params.leaveId);

    if (!leave) {
      return res.status(404).json({
        success: false,
        message: 'Leave request not found'
      });
    }

    // Verify manager owns the mess
    const mess = await Mess.findOne({ _id: leave.mess, owner: req.user.id });

    if (!mess) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to reject this leave'
      });
    }

    leave.status = 'Rejected';
    await leave.save();

    res.status(200).json({
      success: true,
      message: 'Leave request rejected'
    });
  } catch (error) {
    next(error);
  }
};
