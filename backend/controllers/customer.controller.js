// This file contains the logic for customer-specific actions.

const Membership = require('../models/membership.model.js');
const Mess = require('../models/mess.model.js');
const Leave = require('../models/leave.model.js');

// @desc    Customer joins a mess by creating a membership
// @route   POST /api/customers/memberships
// @access  Private (Customer only)
const joinMess = async (req, res) => {
    const { messId, mealPlanId } = req.body;
    const customerId = req.user._id;

    try {
        // Find the mess the customer wants to join.
        const mess = await Mess.findById(messId);
        if (!mess) {
            return res.status(404).json({ message: "Mess not found" });
        }

        // Find the specific meal plan within the mess's offerings.
        const mealPlan = mess.mealPlans.id(mealPlanId);
        if (!mealPlan) {
            return res.status(404).json({ message: "Meal plan not found" });
        }
        
        // Check if the customer is already a member of this mess.
        const existingMembership = await Membership.findOne({ customer: customerId, mess: messId });
        if(existingMembership) {
            return res.status(400).json({ message: "You are already a member of this mess." });
        }

        // Create the new membership document.
        const membership = await Membership.create({
            customer: customerId,
            mess: messId,
            mealPlan: {
                name: mealPlan.name,
                // Get the latest price from the price history array.
                price: mealPlan.priceHistory[mealPlan.priceHistory.length - 1].price,
            },
        });

        res.status(201).json(membership);

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};


// @desc    Customer marks a leave for a specific membership
// @route   POST /api/customers/memberships/:membershipId/leaves
// @access  Private (Customer only)
const markLeave = async (req, res) => {
    const { startDate, endDate } = req.body;
    const { membershipId } = req.params;
    const customerId = req.user._id;

    try {
        // Find the membership to ensure it exists and belongs to the logged-in user.
        const membership = await Membership.findOne({ _id: membershipId, customer: customerId });
        if (!membership) {
            return res.status(404).json({ message: "Membership not found or you are not authorized." });
        }

        // TODO: Add logic to check against the mess's leaveCutoffDay and leaveCutoffTime.
        
        // Create the leave record.
        const leave = await Leave.create({
            membership: membershipId,
            startDate,
            endDate,
            // TODO: Add logic to calculate if the leave is rebate-eligible based on duration.
        });

        res.status(201).json({ message: 'Leave marked successfully', leave });
        
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Get all active memberships for the logged-in customer
// @route   GET /api/customers/me/memberships
// @access  Private (Customer only)
const getMyMemberships = async (req, res) => {
    try {
        // Find all memberships for the current user and populate the 'mess' field
        // with the name and address from the Mess collection.
        const memberships = await Membership.find({ customer: req.user._id, status: 'active' })
            .populate('mess', 'name address');
            
        res.status(200).json(memberships);

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

module.exports = {
    joinMess,
    markLeave,
    getMyMemberships,
};