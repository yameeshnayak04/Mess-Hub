const User = require('../models/User');
const Mess = require('../models/Mess');

// @desc    Get logged-in user profile
// @route   GET /api/users/profile/me
// @access  Private
exports.getMyProfile = async (req, res, next) => {
  try {
    // Fetch user, excluding PIN by default
    const user = await User.findById(req.user.id).select('-pin');

    if (!user) {
       // Although 'protect' middleware usually handles this, double-check
       return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Convert to plain object to add properties
    const userProfile = user.toObject();

    // *** ADD hasMess check for Managers ***
    if (userProfile.role === 'Manager') {
      const messExists = await Mess.exists({ owner: userProfile._id });
      userProfile.hasMess = !!messExists; // Add hasMess: true or false
    }

    res.status(200).json({
      success: true,
      // Send the modified profile object
      data: userProfile
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update logged-in user profile
// @route   PUT /api/users/profile/me
// @access  Private
exports.updateMyProfile = async (req, res, next) => {
  try {
    const { name, pin } = req.body; // Only allow updating name/pin here

    // Find user including PIN for potential update
    const user = await User.findById(req.user.id).select('+pin'); // Select pin here if needed

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Update fields if provided
    let updated = false;
    if (name && name !== user.name) {
       user.name = name;
       updated = true;
    }
    // Only update PIN for customers and if provided/different
    if (user.role === 'Customer' && pin && pin !== user.pin) {
       user.pin = pin;
       updated = true;
    }

    // Save only if changes were made
    if (updated) {
       await user.save();
    }


    // Fetch the updated profile *without* the PIN to send back
    // Re-run the hasMess check here as well for consistency, although it shouldn't change on profile update
    const updatedUserProfile = await User.findById(user._id).select('-pin').lean(); // Use lean() for plain object

     if (updatedUserProfile.role === 'Manager') {
       const messExists = await Mess.exists({ owner: updatedUserProfile._id });
       updatedUserProfile.hasMess = !!messExists;
     }


    res.status(200).json({
      success: true,
      data: updatedUserProfile // Send updated profile without PIN
    });
  } catch (error) {
    next(error);
  }
};