const User = require('../models/User');
const jwt = require('jsonwebtoken');

const buildUserPayload = (user) => {
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
  return payload;
};

// Generate JWT Token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
};

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
exports.register = async (req, res) => {
  try {
    const { name, phone, password, role, pin, location } = req.body;

    // Validation
    if (!name || !phone || !password || !role) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, phone, password, and role',
      });
    }

    // Check if user exists
    const existingUser = await User.findOne({ phone });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this phone number already exists',
      });
    }

    // Role-specific validation
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

    // Create user data
    const userData = {
      name,
      phone,
      password,
      role,
    };

    // Add optional fields based on role
    if (role === 'Customer') {
      userData.pin = pin;
      userData.location = location;
    }

    // Create user
    const user = await User.create(userData);

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      data: buildUserPayload(user),
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during registration',
      error: error.message,
    });
  }
};

// @desc    Login user with phone and password
// @route   POST /api/auth/login
// @access  Public
// login (password)
exports.login = async (req, res) => {
  const { phone, password } = req.body;
  const user = await User.findOne({ phone }).select('+password');
  if (!user) return res.status(401).json({ success:false, message:'Invalid credentials' });
  const ok = await user.comparePassword(password);
  if (!ok) return res.status(401).json({ success:false, message:'Invalid credentials' });
  const token = generateToken(user._id);
  return res.json({ success:true, token, data: { _id:user._id, name:user.name, phone:user.phone, role:user.role, location:user.location } });
};


// @desc    Kiosk login with phone and PIN (for customers only)
// @route   POST /api/auth/kiosk-login
// @access  Public
exports.kioskLogin = async (req, res) => {
  try {
    const { phone, pin } = req.body;

    if (!phone || !pin) {
      return res.status(400).json({
        success: false,
        message: 'Please provide phone number and PIN',
      });
    }

    // Find user and include pin
    const user = await User.findOne({ phone }).select('+pin');
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Only customers can use PIN login
    if (user.role !== 'Customer') {
      return res.status(403).json({
        success: false,
        message: 'PIN login is only available for customers',
      });
    }

    // Verify PIN
    if (user.pin !== pin) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Generate token
    const token = generateToken(user._id);

    res.json({
      success: true,
      message: 'Login successful',
      token,
      data: {
        _id: user._id,
        name: user.name,
        phone: user.phone,
        role: user.role,
        location: user.location,
      },
    });
  } catch (error) {
    console.error('Kiosk login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login',
      error: error.message,
    });
  }
};

exports.logout = (req, res) => {
  return res.status(200).json({ success: true, message: 'Logged out' });
};
