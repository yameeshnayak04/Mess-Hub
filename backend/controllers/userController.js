const User = require('../models/User');

// @desc    Get logged-in user profile
// @route   GET /api/users/profile/me
// @access  Private
exports.getMyProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).select('-kioskPin');

    res.status(200).json({
      success: true,
      data: user
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
    const { name, kioskPin } = req.body;

    const updateFields = {};
    if (name) updateFields.name = name;
    if (kioskPin) updateFields.kioskPin = kioskPin;

    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Update fields
    if (name) user.name = name;
    if (kioskPin) user.kioskPin = kioskPin;

    await user.save();

    // Return user without kioskPin
    const userResponse = await User.findById(user._id).select('-kioskPin');

    res.status(200).json({
      success: true,
      data: userResponse
    });
  } catch (error) {
    next(error);
  }
};
