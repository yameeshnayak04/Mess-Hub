const Membership = require('../models/Membership');
const Mess = require('../models/Mess');
const Bill = require('../models/Bill');
const Attendance = require('../models/Attendance'); // for summaries
const Menu = require('../models/Menu');             // today’s menu
const { getStartAndEndOfMonth } = require('../utils/billCalculation'); // month window
const Leave = require('../models/Leave');

// @desc   Get membership details for customer dashboard
// @route  GET /api/membership/details/:membershipId
// @access Private (Customer only)
exports.getMembershipDetails = async (req, res, next) => {
  try {
    const { membershipId } = req.params;

    // Load membership with mess and user
    const membership = await Membership.findById(membershipId)
  .populate(
    'mess',
    'messName messImage address city contactPhone serviceType cuisine timings plans rules' // add rules here
  )
  .populate('user', 'name phone');

    if (!membership) {
      return res.status(404).json({ success: false, message: 'Membership not found' });
    }

    // Ownership check
    if (membership.user._id.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    // Month-to-date attendance summary
    const now = new Date();
    const month = now.getMonth() + 1;
    const year = now.getFullYear();
    const { startOfMonth, endOfMonth } = getStartAndEndOfMonth(month, year);

    const [present, skipped, onLeave, absent] = await Promise.all([
      Attendance.countDocuments({
        user: membership.user._id,
        mess: membership.mess._id,
        date: { $gte: startOfMonth, $lte: endOfMonth },
        status: 'Present',
      }),
      Attendance.countDocuments({
        user: membership.user._id,
        mess: membership.mess._id,
        date: { $gte: startOfMonth, $lte: endOfMonth },
        status: 'Skipped',
      }),
      Attendance.countDocuments({
        user: membership.user._id,
        mess: membership.mess._id,
        date: { $gte: startOfMonth, $lte: endOfMonth },
        status: 'Leave',
      }),
      Attendance.countDocuments({
        user: membership.user._id,
        mess: membership.mess._id,
        date: { $gte: startOfMonth, $lte: endOfMonth },
        status: 'Absent',
      }),
    ]);

    // Recent bills
    const recentBills = await Bill.find({
      user: membership.user._id,
      mess: membership.mess._id,
    })
      .sort({ year: -1, month: -1, createdAt: -1 })
      .limit(6);

    // Today’s menu snapshot
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todaysMenu = await Menu.findOne({
      mess: membership.mess._id,
      date: today,
    });

    return res.status(200).json({
      success: true,
      data: {
        membership,
        attendanceSummary: { present, skipped, leave: onLeave, absent },
        recentBills,
        todaysMenu,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc Manager verifies member can leave (alias for approve-discontinue)
// @route PUT /api/membership/verify-leave/:membershipId
// @access Private (Manager only)
exports.verifyLeaveMembership = async (req, res, next) => {
  return exports.approveDiscontinueMembership(req, res, next);
};



// @desc    Join a mess
// @route   POST /api/membership/join/:messId
// @access  Private (Customer only)
exports.joinMess = async (req, res, next) => {
  try {
    const { messId } = req.params;
    const { planName } = req.body;

    // Check if mess exists
    const mess = await Mess.findById(messId);

    if (!mess) {
      return res.status(404).json({
        success: false,
        message: 'Mess not found'
      });
    }

    // Find the selected plan
    const selectedPlan = mess.plans.find(plan => plan.name === planName);

    if (!selectedPlan) {
      return res.status(400).json({
        success: false,
        message: 'Invalid plan selected'
      });
    }

    // Check if user already has a membership for this mess
    // Check if user already has a membership for this mess
const existingMembership = await Membership.findOne({
  user: req.user.id,
  mess: messId,
  status: { $in: ['Pending', 'Active'] },
});

if (existingMembership) {
  return res.status(400).json({
    success: false,
    message: 'You already have an active or pending membership for this mess',
  });
}

// Enforce max capacity at join time (based on active members only)
if (typeof mess.maxCapacity === 'number' && mess.maxCapacity > 0) {
  const activeCount = await Membership.countDocuments({
    mess: messId,
    status: 'Active',
  });

  if (activeCount >= mess.maxCapacity) {
    return res.status(400).json({
      success: false,
      message:
        'This mess has reached its maximum capacity and cannot accept new members.',
    });
  }
}

// Create membership (still Pending; final capacity guard also exists in approve)
const membership = await Membership.create({
  user: req.user.id,
  mess: messId,
  planName: selectedPlan.name,
  billingRate: selectedPlan.rate,
  status: 'Pending',
});


    const populatedMembership = await Membership.findById(membership._id)
      .populate('mess', 'messName address city contactPhone')
      .populate('user', 'name phone');

    res.status(201).json({
      success: true,
      data: populatedMembership
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all members of manager's mess
// @route   GET /api/membership/mess
// @access  Private (Manager only)
exports.getMessMembers = async (req, res, next) => {
  // ... (existing code, no changes)
  try {
    const { status } = req.query;
    const mess = await Mess.findOne({ owner: req.user.id });
    if (!mess) {
      return res.status(404).json({ success: false, message: 'No mess found for this manager' });
    }
    const query = { mess: mess._id };
    if (status) {
      query.status = status;
    }
    const members = await Membership.find(query)
      .populate('user', 'name phone location')
      .sort({ createdAt: -1 });
    const membersWithPaymentStatus = await Promise.all(
      members.map(async (member) => {
        const memberObj = member.toObject();
        if (member.status === 'Active') {
          const recentBill = await Bill.findOne({
            user: member.user._id,
            mess: mess._id
          }).sort({ year: -1, month: -1 });
          memberObj.paymentStatus = recentBill ? recentBill.status : 'No Bills';
        }
        return memberObj;
      })
    );
    res.status(200).json({ success: true, count: membersWithPaymentStatus.length, data: membersWithPaymentStatus });
  } catch (error) { next(error); }
};

// @desc    Approve membership
// @route   PUT /api/membership/approve/:membershipId
// @access  Private (Manager only)
exports.approveMembership = async (req, res, next) => {
  try {
    const membership = await Membership.findById(req.params.membershipId);

    if (!membership) {
      return res.status(404).json({
        success: false,
        message: 'Membership not found'
      });
    }

    // Verify manager owns the mess
    const mess = await Mess.findOne({ _id: membership.mess, owner: req.user.id });
    if (!mess) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to approve this membership',
      });
    }
    
    // Enforce max capacity on approval as the final gate
    if (typeof mess.maxCapacity === 'number' && mess.maxCapacity > 0) {
      const activeCount = await Membership.countDocuments({
        mess: mess._id,
        status: 'Active',
      });
    
      if (activeCount >= mess.maxCapacity) {
        return res.status(400).json({
          success: false,
          message:
            'Cannot approve this membership because the mess is already at maximum capacity.',
        });
      }
    }
    
    membership.status = 'Active';
    membership.joinedDate = new Date();
    await membership.save();


    const populatedMembership = await Membership.findById(membership._id)
      .populate('user', 'name phone')
      .populate('mess', 'messName');

    res.status(200).json({
      success: true,
      data: populatedMembership
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Reject membership
// @route   PUT /api/membership/reject/:membershipId
// @access  Private (Manager only)
exports.rejectMembership = async (req, res, next) => {
  try {
    const membership = await Membership.findById(req.params.membershipId);

    if (!membership) {
      return res.status(404).json({
        success: false,
        message: 'Membership not found'
      });
    }

    // Verify manager owns the mess
    const mess = await Mess.findOne({ _id: membership.mess, owner: req.user.id });

    if (!mess) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to reject this membership'
      });
    }

    // Delete the membership
    await Membership.findByIdAndDelete(req.params.membershipId);

    res.status(200).json({
      success: true,
      message: 'Membership rejected and removed'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get customer's memberships
// @route   GET /api/membership/my-memberships
// @access  Private (Customer only)
exports.getMyMemberships = async (req, res, next) => {
  try {
    const memberships = await Membership.find({
      user: req.user.id,
      // *** FIX: Also show 'Inactive' memberships so users can see their history ***
      // You can filter this on the frontend if needed
      status: { $in: ['Pending', 'Active', 'Inactive'] } 
    })
      // *** FIX: Populate *all* required fields from the Mess model ***
      .populate('mess', 'messName messImage address city contactPhone serviceType cuisine timings location plans rules tiffinService basicThaliDetails')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: memberships.length,
      data: memberships
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Leave a mess
// @route   PUT /api/membership/leave/:membershipId
// @access  Private (Customer only)
exports.leaveMess = async (req, res, next) => {
  try {
    const membership = await Membership.findById(req.params.membershipId);

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
        message: 'Not authorized to modify this membership'
      });
    }

    // Check for outstanding bills
    const outstandingBill = await Bill.findOne({
      user: req.user.id,
      mess: membership.mess,
      status: { $in: ['Due', 'Pending Approval'] }
    });

    if (outstandingBill) {
      return res.status(403).json({
        success: false,
        message: 'Please clear your outstanding dues before leaving.'
      });
    }

    // Set membership to inactive
    membership.status = 'Inactive';
    await membership.save();

    res.status(200).json({
      success: true,
      message: 'You have successfully left the mess'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get details for a single member (Manager's view)
// @route   GET /api/membership/member/:membershipId
// @access  Private (Manager only)
exports.getMemberDetails = async (req, res, next) => {
  try {
    const { membershipId } = req.params;

    const membership = await Membership.findById(membershipId)
      .populate('user', 'name phone location');
      
    if (!membership) {
      return res.status(404).json({ success: false, message: 'Membership not found' });
    }

    // Verify manager owns the mess
    const mess = await Mess.findOne({ _id: membership.mess, owner: req.user.id });
    if (!mess) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    // Get current payment status
    const recentBill = await Bill.findOne({
      user: membership.user,
      mess: membership.mess
    }).sort({ year: -1, month: -1 });
    
    const paymentStatus = recentBill ? recentBill.status : 'No Bills';
    
    // Get last 5 attendance records
    const recentAttendance = await Attendance.find({
      user: membership.user,
      mess: membership.mess
    }).sort({ date: -1, createdAt: -1 }).limit(5);

    // Get last 5 leave records
    const recentLeaves = await Leave.find({
      user: membership.user,
      mess: membership.mess
    }).sort({ startDate: -1 }).limit(5);

    res.status(200).json({
      success: true,
      data: {
        membership: {
          ...membership.toObject(),
          paymentStatus // Add payment status tag
        },
        recentAttendance,
        recentLeaves
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc Customer requests permanent discontinuation of a membership
// @route PUT /api/membership/request-discontinue/:membershipId
// @access Private (Customer only)
exports.requestDiscontinueMembership = async (req, res, next) => {
  try {
    const membership = await Membership.findById(req.params.membershipId);

    if (!membership) {
      return res.status(404).json({
        success: false,
        message: 'Membership not found',
      });
    }

    // Ensure membership belongs to this user
    if (membership.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to modify this membership',
      });
    }

    // Only active memberships can be discontinued
    if (membership.status !== 'Active') {
      return res.status(400).json({
        success: false,
        message: 'Only active memberships can be discontinued.',
      });
    }

    // Avoid duplicate requests
    if (membership.leaveRequested) {
      return res.status(400).json({
        success: false,
        message: 'You already have a pending discontinuation request for this membership.',
      });
    }

    // Block if any outstanding bills exist
    const outstandingBill = await Bill.findOne({
      user: req.user.id,
      mess: membership.mess,
      status: { $in: ['Due', 'Pending Approval'] },
    });

    if (outstandingBill) {
      return res.status(403).json({
        success: false,
        message: 'Please clear your outstanding dues before requesting discontinuation.',
      });
    }

    membership.leaveRequested = true;
    await membership.save();

    return res.status(200).json({
      success: true,
      message:
        'Your request to permanently discontinue this membership has been sent to the mess manager for approval.',
    });
  } catch (error) {
    next(error);
  }
};

// @desc Manager approves permanent discontinuation (sets Inactive)
// @route PUT /api/membership/approve-discontinue/:membershipId
// @access Private (Manager only)
exports.approveDiscontinueMembership = async (req, res, next) => {
  try {
    const { membershipId } = req.params;
    const membership = await Membership.findById(membershipId);

    if (!membership) {
      return res
        .status(404)
        .json({ success: false, message: 'Membership not found' });
    }

    // Ensure the manager owns this mess
    const mess = await Mess.findOne({ _id: membership.mess, owner: req.user.id });
    if (!mess) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to discontinue this membership',
      });
    }

    // Require a pending discontinuation request or an active membership
    if (!membership.leaveRequested && membership.status !== 'Active') {
      return res.status(400).json({
        success: false,
        message: 'No pending discontinuation request for this membership.',
      });
    }

    // Double-check for outstanding bills before deactivation
    const outstanding = await Bill.exists({
      user: membership.user,
      mess: membership.mess,
      status: { $in: ['Due', 'Pending Approval'] },
    });

    if (outstanding) {
      return res.status(400).json({
        success: false,
        message: 'Outstanding dues found; cannot deactivate membership.',
      });
    }

    membership.status = 'Inactive';
    membership.leaveRequested = false;
    await membership.save();

    const populated = await Membership.findById(membership._id)
      .populate('user', 'name phone')
      .populate('mess', 'messName');

    return res.status(200).json({
      success: true,
      message: 'Membership has been permanently discontinued.',
      data: populated,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Manager rejects a discontinuation request
// @route PUT /api/membership/reject-discontinue/:membershipId
// @access Private (Manager only)
exports.rejectDiscontinueMembership = async (req, res, next) => {
  try {
    const { membershipId } = req.params;
    const membership = await Membership.findById(membershipId);

    if (!membership) {
      return res
        .status(404)
        .json({ success: false, message: 'Membership not found' });
    }

    // Ensure the manager owns this mess
    const mess = await Mess.findOne({ _id: membership.mess, owner: req.user.id });
    if (!mess) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to reject discontinuation for this membership',
      });
    }

    if (!membership.leaveRequested) {
      return res.status(400).json({
        success: false,
        message: 'No pending discontinuation request to reject.',
      });
    }

    membership.leaveRequested = false;
    await membership.save();

    return res.status(200).json({
      success: true,
      message: 'Discontinuation request has been rejected. Membership remains active.',
    });
  } catch (error) {
    next(error);
  }
};
