const Bill = require('../models/Bill');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Leave = require('../models/Leave');
const Attendance = require('../models/Attendance');
const { calculateDaysDifference, getStartAndEndOfMonth } = require('../utils/billCalculation');


// List all customer payment submissions awaiting approval for this manager
exports.getPendingApprovals = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }
    const pending = await Bill.find({ mess: mess._id, status: 'Pending Approval' })
      .sort({ updatedAt: -1 })
      .populate('user', 'name phone');
    return res.status(200).json({ success: true, count: pending.length, data: pending });
  } catch (err) { next(err); }
};

// Show a single payment (bill) details including proof, scoped to this manager’s mess
exports.getPaymentDetails = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }
    const bill = await Bill.findOne({ _id: req.params.billId, mess: mess._id })
      .populate('user', 'name phone');
    if (!bill) {
      return res.status(404).json({ success: false, message: 'Bill not found' });
    }
    return res.status(200).json({ success: true, data: bill });
  } catch (err) { next(err); }
};


// @desc    Generate monthly bills
// @route   POST /api/billing/generate-bills
// @access  Private (Manager only)
// billingController.js

exports.generateMonthlyBills = async (req, res, next) => {
  try {
    const { month, year } = req.body;

    // Manager's mess
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }

    // Determine billing window
    const billingMonth = month || new Date().getMonth() + 1;
    const billingYear = year || new Date().getFullYear();
    const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(billingMonth, billingYear);

    // Active monthly members
    const activeMembers = await Membership.find({ mess: mess._id, status: 'Active' });
    if (activeMembers.length === 0) {
      return res.status(400).json({ success: false, message: 'No active members to generate bills for' });
    }

    const generatedBills = [];
    for (const member of activeMembers) {
      // Avoid duplicate bill for this user/mess/month/year
      const exists = await Bill.exists({
        user: member.user, mess: mess._id, month: billingMonth, year: billingYear
      });
      if (exists) continue;

      // Base = membership billingRate snapshot
      const baseAmount = Number(member.billingRate || 0);

      // Skipped meals in the month (Monthly members only)
      const skippedMeals = await Attendance.countDocuments({
        user: member.user,
        mess: mess._id,
        memberType: 'Monthly',
        date: { $gte: startOfMonth, $lte: endOfMonth },
        status: 'Skipped'
      });

      // Leaves overlapping the month window (no status field)
      const leaves = await Leave.find({
        user: member.user,
        mess: mess._id,
        startDate: { $lte: endOfMonth },
        endDate: { $gte: startOfMonth }
      });

      // Sum eligible leave days by range; enforce minLeaveDaysForRebate per range
      let leaveRebateDays = 0;
      for (const lv of leaves) {
        const s = lv.startDate < startOfMonth ? startOfMonth : lv.startDate;
        const e = lv.endDate > endOfMonth ? endOfMonth : lv.endDate;
        const days = calculateDaysDifference(s, e);
        if (days >= (mess.rules?.minLeaveDaysForRebate || 0)) {
          leaveRebateDays += days;
        }
      }

      // Rebates
      const rebatePerThali = Number(mess.rules?.rebatePerThali || 0);
      const skipAllowancePercent = Number(mess.rules?.skipAllowancePercent || 0);
      const leaveRebate = leaveRebateDays * rebatePerThali;
      const skipRebate = skippedMeals * rebatePerThali * (skipAllowancePercent / 100);
      const rebateAmount = leaveRebate + skipRebate;

      // Total with minMonthlyCharge
      const minMonthlyCharge = Number(mess.rules?.minMonthlyCharge || 0);
      let totalAmount = Math.max(0, baseAmount - rebateAmount);
      if (minMonthlyCharge && totalAmount < minMonthlyCharge) {
        totalAmount = minMonthlyCharge;
      }

      // Create bill
      const bill = await Bill.create({
        user: member.user,
        mess: mess._id,
        month: billingMonth,
        year: billingYear,
        baseAmount,
        rebateAmount,
        totalAmount,
        status: 'Due'
      });
      generatedBills.push(bill);

      // Update membership rate from current Mess plan for next cycle (by planName)
      const currentPlan = mess.plans?.find(p => p.name?.toLowerCase() === member.planName?.toLowerCase());
      if (currentPlan && typeof currentPlan.rate === 'number') {
        member.billingRate = currentPlan.rate;
        await member.save();
      }
    }

    return res.status(201).json({
      success: true,
      count: generatedBills.length,
      data: generatedBills,
      message: `Successfully generated ${generatedBills.length} bills for ${billingMonth}/${billingYear}`
    });
  } catch (error) {
    next(error);
  }
};


// @desc    Submit payment proof
// @route   POST /api/billing/submit-proof/:billId
// @access  Private (Customer only)
exports.submitPaymentProof = async (req, res, next) => {
  try {
    const bill = await Bill.findById(req.params.billId);

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found'
      });
    }

    // Verify bill belongs to user
    if (bill.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Please upload payment proof'
      });
    }

    bill.paymentProofUrl = `/uploads/payment-proofs/${req.file.filename}`;
    bill.status = 'Pending Approval';
    await bill.save();

    res.status(200).json({
      success: true,
      data: bill,
      message: 'Payment proof submitted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get pending payment approvals
// @route   GET /api/billing/pending-approvals
// @access  Private (Manager only)
exports.getPendingApprovals = async (req, res, next) => {
  try {
    // Find manager's mess
    const mess = await Mess.findOne({ owner: req.user.id });

    if (!mess) {
      return res.status(404).json({
        success: false,
        message: 'No mess found for this manager'
      });
    }

    const pendingBills = await Bill.find({
      mess: mess._id,
      status: 'Pending Approval'
    })
      .populate('user', 'name phone')
      .sort({ updatedAt: -1 });

    res.status(200).json({
      success: true,
      count: pendingBills.length,
      data: pendingBills
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Approve payment
// @route   PUT /api/billing/approve-payment/:billId
// @access  Private (Manager only)
exports.approvePayment = async (req, res, next) => {
  try {
    const bill = await Bill.findById(req.params.billId);

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found'
      });
    }

    // Verify manager owns the mess
    const mess = await Mess.findOne({ _id: bill.mess, owner: req.user.id });

    if (!mess) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to approve this payment'
      });
    }

    bill.status = 'Paid';
    await bill.save();

    res.status(200).json({
      success: true,
      data: bill,
      message: 'Payment approved successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Reject payment
// @route   PUT /api/billing/reject-payment/:billId
// @access  Private (Manager only)
exports.rejectPayment = async (req, res, next) => {
  try {
    const bill = await Bill.findById(req.params.billId);

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found'
      });
    }

    // Verify manager owns the mess
    const mess = await Mess.findOne({ _id: bill.mess, owner: req.user.id });

    if (!mess) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to reject this payment'
      });
    }

    bill.status = 'Due';
    bill.paymentProofUrl = undefined;
    await bill.save();

    res.status(200).json({
      success: true,
      data: bill,
      message: 'Payment rejected. Bill status reverted to Due.'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get customer's bills for a membership
// @route   GET /api/billing/my-bills/:membershipId
// @access  Private (Customer only)
exports.getMyBills = async (req, res, next) => {
  try {
    const { membershipId } = req.params;

    // Find membership
    const membership = await Membership.findById(membershipId);

    if (!membership) {
      return res.status(404).json({
        success: false,
        message: 'Membership not found'
      });
    }

    // Verify membership belongs to user
    if (membership.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    const bills = await Bill.find({
      user: req.user.id,
      mess: membership.mess
    })
      .sort({ year: -1, month: -1 });

    res.status(200).json({
      success: true,
      count: bills.length,
      data: bills
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all bills for a specific member
// @route   GET /api/billing/member/:membershipId
// @access  Private (Manager only)
exports.getMemberBills = async (req, res, next) => {
  try {
    const membership = await Membership.findById(req.params.membershipId);
    if (!membership) {
      return res.status(404).json({ success: false, message: 'Membership not found' });
    }

    // Verify manager owns the mess
    const mess = await Mess.findOne({ _id: membership.mess, owner: req.user.id });
    if (!mess) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const bills = await Bill.find({
      user: membership.user,
      mess: membership.mess
    }).sort({ year: -1, month: -1 });

    res.status(200).json({
      success: true,
      count: bills.length,
      data: bills
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all bills for the manager's mess (filterable)
// @route   GET /api/billing/all-bills
// @access  Private (Manager only)
exports.getAllMessBills = async (req, res, next) => {
  try {
    const { status, month, year } = req.query;

    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }

    const query = { mess: mess._id };
    if (status) query.status = status;
    if (month) query.month = parseInt(month);
    if (year) query.year = parseInt(year);

    const bills = await Bill.find(query)
      .populate('user', 'name phone')
      .sort({ year: -1, month: -1, updatedAt: -1 });

    res.status(200).json({
      success: true,
      count: bills.length,
      data: bills
    });
  } catch (error) {
    next(error);
  }
};
