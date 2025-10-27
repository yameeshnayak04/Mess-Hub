const Leave = require('../models/Leave');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const { calculateDaysDifference } = require('../utils/billCalculation');

// @desc    Apply for leave
// @route   POST /api/leave/apply/:membershipId
// @access  Private (Customer only)
// POST /api/leave/apply/:membershipId
exports.applyForLeave = async (req,res,next) => {
  const { membershipId } = req.params; const { startDate, endDate } = req.body;
  const m = await Membership.findById(membershipId);
  if (!m) return res.status(404).json({ success:false, message:'Membership not found' });
  if (m.user.toString() !== req.user.id) return res.status(403).json({ success:false, message:'Not authorized' });
  if (m.status !== 'Active') return res.status(400).json({ success:false, message:'Membership is not active' });
  const start = new Date(startDate), end = new Date(endDate);
  const tomorrow = new Date(); tomorrow.setDate(tomorrow.getDate()+1); tomorrow.setHours(0,0,0,0);
  if (start < tomorrow) return res.status(400).json({ success:false, message:'Start date must be at least tomorrow' });
  if (start.getMonth()!==end.getMonth() || start.getFullYear()!==end.getFullYear())
    return res.status(400).json({ success:false, message:'Start and end date must be in the same month' });
  const overlap = await Leave.findOne({ user:req.user.id, mess:m.mess, $or: [{ startDate:{ $lte:end }, endDate:{ $gte:start } }] });
  if (overlap) return res.status(400).json({ success:false, message:'Overlapping leave exists' });
  const leave = await Leave.create({ user:req.user.id, mess:m.mess, startDate:start, endDate:end });
  const populated = await Leave.findById(leave._id).populate('mess','messName');
  return res.status(201).json({ success:true, data: populated, message:'Leave added; rebate depends on rules at billing' });
};

// GET /api/leave/my/:membershipId
exports.getMyLeaves = async (req,res,next) => {
  const m = await Membership.findById(req.params.membershipId);
  if (!m) return res.status(404).json({ success:false, message:'Membership not found' });
  if (m.user.toString() !== req.user.id) return res.status(403).json({ success:false, message:'Not authorized' });
  const leaves = await Leave.find({ user:req.user.id, mess:m.mess }).sort({ startDate:-1 });
  return res.status(200).json({ success:true, count: leaves.length, data: leaves });
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

