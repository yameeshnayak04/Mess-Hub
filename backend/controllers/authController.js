// backend/controllers/authController.js
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const Mess = require('../models/Mess');

const buildUserPayload = async (user) => {
  const payload = {
    _id: user._id,
    name: user.name,
    phone: user.phone,
    role: user.role,
  };

  if (
    user.location &&
    user.location.type &&
    Array.isArray(user.location.coordinates) &&
    user.location.coordinates.length === 2
  ) {
    payload.location = user.location;
  }

  if (user.role === 'Manager') {
    const mess = await Mess.exists({ owner: user._id });
    payload.hasMess = !!mess;
  }

  return payload;
};

const generateToken = (id) =>
  jwt.sign(
    { id }, 
    process.env.JWT_SECRET, 
    { expiresIn: process.env.JWT_EXPIRES_IN || '30d', }
  );

// @desc Register a new user
// @route POST /api/auth/register
// @access Public
exports.register = async (req, res) => {
  try {
    const { name, phone, password, role, pin, location } = req.body;

    // Basic validation
    if (!name || !phone || !password || !role) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, phone, password, and role',
      });
    }

    // Unique phone
    const existingUser = await User.findOne({ phone });
    if (existingUser) {
      // Use 409 Conflict + machine-readable code so frontend can detect duplicate
      return res.status(409).json({
        success: false,
        code: 'USER_EXISTS',
        message: 'User with this phone number already exists',
      });
    }

    // Role-specific requirements
    if (role === 'Customer') {
      if (!pin) {
        return res.status(400).json({
          success: false,
          message: 'PIN is required for customers',
        });
      }
      if (!location || !location.coordinates) {
        return res.status(400).json({
          success: false,
          message: 'Location is required for customers',
        });
      }
    }

    const userData = { name, phone, password, role };
    if (role === 'Customer') {
      userData.pin = pin;
      userData.location = location;
    }

    const user = await User.create(userData);

    const token = generateToken(user._id);
    const payload = await buildUserPayload(user);

    return res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      data: payload,
    });
  } catch (error) {
    console.error('Register error:', error);
    return res.status(500).json({
      success: false,
      message: 'Server error during registration',
      error: error.message,
    });
  }
};

// @desc Login user with phone and password
// @route POST /api/auth/login
// @access Public
exports.login = async (req, res, next) => {
  try {
    const { phone, password } = req.body;

    const user = await User.findOne({ phone }).select('+password');
    if (!user) {
      return res
        .status(401)
        .json({ success: false, message: 'Invalid credentials (user not found)' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res
        .status(401)
        .json({ success: false, message: 'Invalid credentials (password mismatch)' });
    }

    const token = generateToken(user._id);
    const payload = await buildUserPayload(user);

    return res.json({ success: true, token, data: payload });
  } catch (error) {
    console.error('Login error:', error);
    return next(error);
  }
};


exports.logout = (req, res) => {
  return res.status(200).json({ success: true, message: 'Logged out' });
};
