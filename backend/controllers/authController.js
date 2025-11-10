const User = require('../models/User');
const jwt = require('jsonwebtoken');
const Mess = require('../models/Mess');
const bcrypt = require('bcryptjs'); // <-- 1. IMPORT BCRYPT

// authController.js (add near top)
const withTimeout = (p, ms = 10000) =>
  Promise.race([p, new Promise((_, rej) => setTimeout(() => rej(new Error('Timed out')), ms))]);

// exports.register = async (req, res) => { ... }  Replace the DB calls:
const existingUser = await withTimeout(
  User.findOne({ phone }).lean().exec(),
  10000
);
if (existingUser) {
  return res.status(400).json({
    success: false,
    message: 'User with this phone number already exists',
  });
}

const user = await withTimeout(User.create(userData), 10000);

// --- 2. ADD A "BULLETPROOF" ERROR HELPER ---
// This ensures we ALWAYS send a JSON response and never crash.
const sendError = (res, e, message, statusCode = 500) => {
  console.error(`[authController Error] ${message}:`, e.message);
  // Send a generic error to the user
  res.status(statusCode).json({
    success: false,
    message: 'An error occurred. Please try again.',
  });
};

// --- (Your helper functions are fine) ---
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
    payload.hasMess = !!mess; // Sets true if mess exists, false otherwise
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
    // (This assumes your User model's 'pre-save' hook hashes the password)
    const user = await User.create(userData);

    // Generate token
    const token = generateToken(user._id);
    const userPayload = await buildUserPayload(user); // <-- Use payload builder

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      data: userPayload, // <-- Send payload
    });
  } catch (error) {
    // --- 3. USE THE BULLETPROOF HELPER ---
    sendError(res, error, 'Server error during registration');
  }
};

// @desc    Login user with phone and password
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res, next) => {
  try {
    const { phone, password } = req.body;
    const user = await User.findOne({ phone }).select('+password');

    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials (user not found)' });
    }
    
    // --- 4. THIS IS THE CRITICAL FIX ---
    // We use bcrypt.compare directly on the user.password field.
    // This will safely handle plain-text passwords (like 'Yameesh@123')
    // from your Atlas database without crashing the server.
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      // This is now safe. It won't crash, it will just be 'false'.
      return res.status(401).json({ success: false, message: 'Invalid credentials (password mismatch)' });
    }

    const token = generateToken(user._id);
    const userPayload = await buildUserPayload(user);

    return res.json({
      success: true,
      token,
      data: userPayload
    });

  } catch (error) {
    // --- 5. USE THE BULLETPROOF HELPER ---
    // This 'catch' will now only catch server errors,
    // not bcrypt crashes. It sends a JSON response instead of hanging.
    sendError(res, error, 'Server error during login');
  }
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
    const userPayload = await buildUserPayload(user); // <-- Use payload builder

    res.json({
      success: true,
      message: 'Login successful',
      token,
      data: userPayload, // <-- Send payload
    });
  } catch (error) {
    // --- 6. USE THE BULLETPROOF HELPER ---
    sendError(res, error, 'Server error during kiosk login');
  }
};

exports.logout = (req, res) => {
  return res.status(200).json({ success: true, message: 'Logged out' });
};