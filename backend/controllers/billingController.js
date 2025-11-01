const Bill = require('../models/Bill');
const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Leave = require('../models/Leave');
const Attendance = require('../models/Attendance');
const { calculateDaysDifference, getStartAndEndOfMonth } = require('../utils/billCalculation');

// @desc    Get all bills with 'Due' status for manager's mess
// @route   GET /api/billing/due-bills
// @access  Private (Manager only)
exports.getDueBills = async (req, res, next) => {
  try {
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }

    const dueBills = await Bill.find({
      mess: mess._id,
      status: 'Due'
    })
      .populate('user', 'name phone')
      .sort({ year: -1, month: -1, updatedAt: -1 });

    res.status(200).json({
      success: true,
      count: dueBills.length,
      data: dueBills
    });
  } catch (error) {
    next(error);
  }
};

// @desc    List all customer payment submissions awaiting approval
// @route   GET /api/billing/pending-approvals
// @access  Private (Manager only)
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

// @desc    Show a single payment (bill) details including proof
// @route   GET /api/billing/payment/:billId
// @access  Private (Manager only)
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
