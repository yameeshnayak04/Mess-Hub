// This file contains the final logic for all customer-specific actions.

const Membership = require('../models/membership.model.js');
const Mess = require('../models/mess.model.js');
const Leave = require('../models/leave.model.js');
const MealSkip = require('../models/mealSkip.model.js');
const Invoice = require('../models/invoice.model.js');
const User = require('../models/user.model.js');

// @desc    Customer joins a mess by creating a new membership.
const joinMess = async (req, res) => {
    const { messId, mealPlanId } = req.body;
    try {
        const mess = await Mess.findById(messId);
        if (!mess) return res.status(404).json({ message: "Mess not found" });

        // Loophole Resolution: Check mess capacity before allowing a join.
        const memberCount = await Membership.countDocuments({ mess: messId, status: 'active' });
        if (memberCount >= mess.maxMembers) {
            return res.status(400).json({ message: "This mess is currently at full capacity." });
        }

        const mealPlan = mess.mealPlans.id(mealPlanId);
        if (!mealPlan) return res.status(404).json({ message: "Meal plan not found" });

        const existingMembership = await Membership.findOne({ customer: req.user._id, mess: messId });
        if (existingMembership) return res.status(400).json({ message: "You are already a member of this mess." });

        const membership = await Membership.create({
            customer: req.user._id,
            mess: messId,
            mealPlan: {
                name: mealPlan.name,
                price: mealPlan.priceHistory[mealPlan.priceHistory.length - 1].price,
                perDayRebateRate: mealPlan.perDayRebateRate,
            },
        });

        // Loophole Resolution: Handle pro-rata billing logic for the first month.
        // TODO: Call a helper function here to calculate and create the first invoice.

        res.status(201).json(membership);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Customer gets their own profile.
const getMyProfile = (req, res) => res.status(200).json(req.user);

// @desc    Customer updates their profile (name, photo).
const updateMyProfile = async (req, res) => {
    const { name, photoUrl } = req.body;
    try {
        const user = await User.findById(req.user.id);
        if (user) {
            user.name = name || user.name;
            user.photoUrl = photoUrl || user.photoUrl;
            const updatedUser = await user.save();
            res.status(200).json(updatedUser);
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Customer marks a formal leave for a membership.
const markLeave = async (req, res) => {
    const { startDate, endDate } = req.body;
    try {
        const membership = await Membership.findOne({ _id: req.params.membershipId, customer: req.user._id }).populate('mess');
        if (!membership) return res.status(404).json({ message: "Membership not found or not authorized." });
        
        // Loophole Resolution: Check against the manager's leave rules.
        // TODO: Add logic here to check against mess.leaveApplicationDeadlineTime.

        const leave = await Leave.create({ membership: req.params.membershipId, startDate, endDate });
        res.status(201).json({ message: 'Leave marked successfully', leave });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Customer toggles "Not Eating" for a single meal.
const toggleMealSkip = async (req, res) => {
    const { date, mealType } = req.body; // mealType is 'Lunch' or 'Dinner'
    try {
        const membership = await Membership.findOne({ _id: req.params.membershipId, customer: req.user._id }).populate('mess');
        if (!membership) return res.status(404).json({ message: "Membership not found." });

        // Loophole Resolution: Check against the "Not Eating" cutoff time.
        // TODO: Add logic here to check if the current time is before mess.notEatingCutoff.lunch/dinner.

        const { mess } = membership;
        let isRebateEligible = false, rebatePercentage = 0;
        if (mess.notEatingRebatePolicy === 'Full') {
            isRebateEligible = true;
            rebatePercentage = 100;
        } else if (mess.notEatingRebatePolicy === 'Partial') {
            isRebateEligible = true;
            rebatePercentage = mess.partialRebatePercentage;
        }

        const mealSkip = await MealSkip.create({ membership: req.params.membershipId, date, mealType, isRebateEligible, rebatePercentage });
        res.status(201).json({ message: `You have been marked as 'Not Eating' for ${mealType}.`, mealSkip });
    } catch (error) {
        if (error.code === 11000) return res.status(400).json({ message: `You have already skipped this meal.` });
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Customer notifies manager that a bill has been paid.
const notifyPayment = async (req, res) => {
    const { proofUrl } = req.body;
    try {
        const invoice = await Invoice.findById(req.params.invoiceId).populate({ path: 'membership', match: { customer: req.user._id }});
        if (!invoice || !invoice.membership) return res.status(404).json({ message: 'Invoice not found or not authorized.' });
        if (invoice.status !== 'due') return res.status(400).json({ message: 'This invoice is not currently due.' });
        
        invoice.status = 'pending_approval';
        invoice.proofUrl = proofUrl;
        await invoice.save();

        // TODO: Trigger a push notification to the manager.
        res.status(200).json({ message: 'Manager has been notified of your payment.' });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Get all active memberships for the logged-in customer.
const getMyMemberships = async (req, res) => {
    try {
        const memberships = await Membership.find({ customer: req.user._id, status: 'active' }).populate('mess', 'name address');
        res.status(200).json(memberships);
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// controllers/customer.controller.js (additions)
const setMyKioskPin = async (req, res, next) => {
  try {
    const { pin } = req.body;
    if (!/^\d{4,6}$/.test(pin || '')) {
      return res.status(400).json({ message: 'PIN must be 4–6 digits' });
    }
    const user = await User.findById(req.user._id);
    await user.setKioskPin(pin);
    await user.save();
    return res.status(200).json({ message: 'Kiosk PIN set' });
  } catch (e) {
    next(e);
  }
};

const getMyKioskPinStatus = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).select('+kioskPinHash');
    return res.status(200).json({ hasPin: !!user?.kioskPinHash });
  } catch (e) {
    next(e);
  }
};


module.exports = { setMyKioskPin, getMyKioskPinStatus, joinMess, getMyProfile, updateMyProfile, markLeave, toggleMealSkip, notifyPayment, getMyMemberships };