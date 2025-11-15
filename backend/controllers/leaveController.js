const mongoose = require('mongoose'); // Required for transactions
const Leave = require('../models/Leave');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Attendance = require('../models/Attendance'); // Required for transaction
const { startOfDay } = require('../utils/billCalculation'); // Import from billCalculation
const { calculateDaysDifference } = require('../utils/billCalculation');

// @desc Apply for leave with eligibility checks
// @route POST /api/leave/apply/:membershipId
// @access Private (Customer only)
exports.applyForLeave = async (req, res, next) => {
  const { membershipId } = req.params;
  const { startDate, endDate } = req.body;
  const session = await mongoose.startSession();

  try {
    let populatedLeave;

    await session.withTransaction(async () => {
      const m = await Membership.findById(membershipId)
        .populate('mess')
        .session(session);

      if (!m) {
        return res.status(404).json({ success: false, message: 'Membership not found' });
      }
      if (m.user.toString() !== req.user.id) {
        return res.status(403).json({ success: false, message: 'Not authorized' });
      }
      if (m.status !== 'Active') {
        return res.status(400).json({ success: false, message: 'Membership is not active' });
      }

      const messRules = m.mess.rules;

      const dayMs = 24 * 60 * 60 * 1000;

      // Normalize requested range in IST
      const start = startOfDay(new Date(startDate));
      const end = startOfDay(new Date(endDate));

      // Compute today/tomorrow in IST
      const todayIst = startOfDay(new Date());
      const tomorrowIst = new Date(todayIst.getTime() + dayMs);

      if (start < tomorrowIst) {
        return res.status(400).json({
          success: false,
          message: 'Start date must be at least tomorrow',
        });
      }

      const minDays = messRules.minLeaveDaysForRebate || 1;
      const leaveDuration = Math.floor((end - start) / dayMs) + 1;


      if (leaveDuration < minDays) {
        return res.status(400).json({
          success: false,
          message: `Leave must be for at least ${minDays} continuous days to be eligible for rebate.`,
        });
      }

      // Overlap check
      const overlap = await Leave.findOne({
        user: req.user.id,
        mess: m.mess._id,
        $or: [
          { startDate: { $lte: end }, endDate: { $gte: start } },
        ],
      }).session(session);

      if (overlap) {
        return res.status(400).json({
          success: false,
          message: 'This leave request overlaps with an existing leave.',
        });
      }

      // --- ATOMIC OPERATION ---
      // 1. Create Leave record
      const leave = await Leave.create(
        [{ user: req.user.id, mess: m.mess._id, startDate: start, endDate: end }],
        { session }
      );

      // 2. Create corresponding Attendance records
      // --- FIXED: Respect plan restrictions ---
      const planName = String(m.planName).toLowerCase();
      const meals = [];

      // Only add meals that the member's plan actually includes
      if (planName.includes('both')) {
        meals.push('Lunch', 'Dinner');
      } else if (planName.includes('lunch')) {
        meals.push('Lunch');
      } else if (planName.includes('dinner')) {
        meals.push('Dinner');
      }

      if (meals.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Your plan does not allow marking leave for any meals.',
        });
      }

      const bulkOps = [];

      // Walk the already-normalized IST days using milliseconds
      for (let t = start.getTime(); t <= end.getTime(); t += dayMs) {
        const day = new Date(t);
      
        for (const meal of meals) {
          bulkOps.push({
            updateOne: {
              filter: { membership: m._id, date: day, mealType: meal },
              update: {
                $setOnInsert: {
                  user: req.user.id,
                  membership: m._id,
                  mess: m.mess._id,
                  date: day,
                  mealType: meal,
                  status: 'Leave',
                  memberType: 'Monthly',
                  planNameSnapshot: m.planName,
                  rateSnapshot: m.billingRate,
                  rebatePerThaliSnapshot: m.mess.rules.rebatePerThali,
                },
              },
              upsert: true,
            },
          });
        }
      }


      if (bulkOps.length > 0) {
        await Attendance.bulkWrite(bulkOps, { session });
      }
      // --- END ATOMIC OPERATION ---

      populatedLeave = await Leave.findById(leave[0]._id)
        .populate('mess', 'messName')
        .session(session);
    });

    return res.status(201).json({
      success: true,
      data: populatedLeave,
      message: 'Leave successfully recorded and attendance marked.',
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Attendance already marked for one of these dates.',
      });
    }
    console.error('Leave application transaction failed:', error);
    return next(error);
  } finally {
    session.endSession();
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

// @desc Delete a leave request (before start date)
// @route DELETE /api/leave/:leaveId
// @access Private (Customer only)
exports.cancelLeave = async (req, res, next) => {
  const { leaveId } = req.params;
  const session = await mongoose.startSession();

  try {
    await session.withTransaction(async () => {
      const leave = await Leave.findById(leaveId).populate('mess').session(session);

      if (!leave) {
        return res.status(404).json({ success: false, message: 'Leave not found' });
      }

      if (leave.user.toString() !== req.user.id) {
        return res.status(403).json({ success: false, message: 'Not authorized' });
      }

      const now = new Date();
      if (leave.startDate <= now) {
        return res.status(400).json({
          success: false,
          message: 'Cannot cancel leave that has already started',
        });
      }

      // Find membership to determine meals
      const membership = await Membership.findOne({
        user: req.user.id,
        mess: leave.mess._id,
      }).session(session);

      if (!membership) {
        return res.status(404).json({ success: false, message: 'Membership not found' });
      }

      const planName = String(membership.planName).toLowerCase();
      const meals = [];
      if (planName.includes('both')) {
        meals.push('Lunch', 'Dinner');
      } else if (planName.includes('lunch')) {
        meals.push('Lunch');
      } else if (planName.includes('dinner')) {
        meals.push('Dinner');
      }

      // Delete corresponding attendance records
      await Attendance.deleteMany({
        membership: membership._id,
        date: { $gte: leave.startDate, $lte: leave.endDate },
        status: 'Leave',
        mealType: { $in: meals }
      }).session(session);

      // Delete leave record
      await leave.deleteOne({ session });
    });

    return res.status(200).json({
      success: true,
      message: 'Leave cancelled successfully',
    });
  } catch (error) {
    console.error('Cancel leave transaction failed:', error);
    return next(error);
  } finally {
    session.endSession();
  }
};