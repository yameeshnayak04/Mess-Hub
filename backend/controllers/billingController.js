const Bill = require('../models/Bill');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Leave = require('../models/Leave');
const Attendance = require('../models/Attendance');
const { calculateDaysDifference, getStartAndEndOfMonth } = require('../utils/billCalculation');

// @desc    Generate monthly bills
// @route   POST /api/billing/generate-bills
// @access  Private (Manager only)
exports.generateMonthlyBills = async (req, res, next) => {
  try {
    const { month, year } = req.body;

    // Find manager's mess
    const mess = await Mess.findOne({ owner: req.user.id });

    if (!mess) {
      return res.status(404).json({
        success: false,
        message: 'No mess found for this manager'
      });
    }

    // Use current month if not specified
    const billingMonth = month || new Date().getMonth() + 1;
    const billingYear = year || new Date().getFullYear();

    // Get all active members
    const activeMembers = await Membership.find({
      mess: mess._id,
      status: 'Active'
    });

    if (activeMembers.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No active members to generate bills for'
      });
    }

    const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(billingMonth, billingYear);

    const generatedBills = [];

    for (const member of activeMembers) {
      // Check if bill already exists
      const existingBill = await Bill.findOne({
        user: member.user,
        mess: mess._id,
        month: billingMonth,
        year: billingYear
      });

      if (existingBill) {
        continue; // Skip if bill already generated
      }

      // Get base amount from current billing rate
      const baseAmount = member.billingRate;

      // Find eligible leaves
      const eligibleLeaves = await Leave.find({
        user: member.user,
        mess: mess._id,
        status: 'Approved',
        isRebateEligible: true,
        startDate: { $gte: startOfMonth },
        endDate: { $lte: endOfMonth }
      });

      // Calculate leave days
      let totalLeaveDays = 0;
      eligibleLeaves.forEach(leave => {
        totalLeaveDays += calculateDaysDifference(leave.startDate, leave.endDate);
      });

      // Find skipped meals
      const skippedMeals = await Attendance.countDocuments({
        user: member.user,
        mess: mess._id,
        status: 'Skipped',
        date: { $gte: startOfMonth, $lte: endOfMonth }
      });

      // Calculate rebate
      const leaveRebate = totalLeaveDays * mess.rules.rebatePerThali;
      const skipRebate = skippedMeals * mess.rules.rebatePerThali * (mess.rules.skipAllowancePercent / 100);
      const rebateAmount = leaveRebate + skipRebate;

      // Calculate total
      let totalAmount = baseAmount - rebateAmount;
      
      // Apply minimum charge if exists
      if (mess.rules.minMonthlyCharge && totalAmount < mess.rules.minMonthlyCharge) {
        totalAmount = mess.rules.minMonthlyCharge;
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

      // Update billing rate for next month from current mess plans
      const currentPlan = mess.plans.find(plan => plan.name === member.planName);
      if (currentPlan) {
        member.billingRate = currentPlan.rate;
        await member.save();
      }
    }

    res.status(201).json({
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
