const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Generate JWT Token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: '30d'
  });
};

// @desc    Register new user
// @route   POST /api/auth/register
// @access  Public
exports.registerUser = async (req, res, next) => {
  try {
    const { name, phone, kioskPin, role, location } = req.body;

    // Check if user already exists
    const userExists = await User.findOne({ phone });

    if (userExists) {
      return res.status(400).json({
        success: false,
        message: 'User with this phone number already exists'
      });
    }

    // Create user
    const user = await User.create({
      name,
      phone,
      kioskPin,
      role,
      location
    });

    // Return user without kioskPin
    const userResponse = {
      _id: user._id,
      name: user.name,
      phone: user.phone,
      role: user.role,
      location: user.location
    };

    res.status(201).json({
      success: true,
      data: userResponse,
      token: generateToken(user._id)
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
exports.loginUser = async (req, res, next) => {
  try {
    const { phone, kioskPin } = req.body;

    // Find user by phone
    const user = await User.findOne({ phone });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check kiosk PIN
    const isMatch = await user.compareKioskPin(kioskPin);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Return user without kioskPin
    const userResponse = {
      _id: user._id,
      name: user.name,
      phone: user.phone,
      role: user.role,
      location: user.location
    };

    res.status(200).json({
      success: true,
      data: userResponse,
      token: generateToken(user._id)
    });
  } catch (error) {
    next(error);
  }
};
