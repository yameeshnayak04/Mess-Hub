// This file contains the logic for user authentication (registration and login).

// Import required models and libraries
const User = require('../models/user.model.js');
const jwt = require('jsonwebtoken');

// --- Helper Functions ---

// Generates a JSON Web Token (JWT) for a given user ID.
// This token will be used to authenticate the user for protected routes.
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: '30d', // The token will expire in 30 days
  });
};

// Generates a random 6-digit One-Time Password (OTP).
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};


// --- Controller Functions ---

// @desc    Send OTP for user registration
// @route   POST /api/auth/register/send-otp
const sendRegistrationOtp = async (req, res) => {
  // Destructure name, phone, and role from the request body.
  const { name, phone, role } = req.body;

  // Basic validation to ensure required fields are present.
  if (!name || !phone || !role) {
    return res.status(400).json({ message: 'Name, phone, and role are required' });
  }

  // Validate the role.
  if (!['customer', 'manager'].includes(role)) {
      return res.status(400).json({ message: 'Invalid role specified' });
  }

  try {
    // Check if a user with this phone number is already fully registered.
    const userExists = await User.findOne({ phone });
    if (userExists && userExists.otp === undefined) {
      return res.status(400).json({ message: 'User with this phone number already exists' });
    }

    // Generate a new OTP and set its expiration time to 10 minutes from now.
    const otp = generateOTP();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000);

    // Use findOneAndUpdate with 'upsert' to create a temporary user if they don't exist,
    // or update their OTP if they do (e.g., they failed the first verification).
    await User.findOneAndUpdate(
      { phone },
      { name, phone, role, otp, otpExpires },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    // --- SIMULATE SENDING SMS ---
    // In a real app, you would integrate an SMS gateway API here.
    console.log(`OTP for registering ${phone} (${role}) is: ${otp}`);
    // ----------------------------

    res.status(200).json({ message: 'OTP sent successfully. Please check your console.' });

  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// @desc    Verify OTP for registration and create the user
// @route   POST /api/auth/register/verify-otp
const verifyRegistrationOtp = async (req, res) => {
    const { phone, otp } = req.body;

    try {
        // Find a user with the matching phone and OTP, ensuring the OTP has not expired.
        const user = await User.findOne({
            phone,
            otp,
            otpExpires: { $gt: Date.now() } // $gt means "greater than"
        });

        // If no user is found, the OTP is invalid or has expired.
        if (!user) {
            return res.status(400).json({ message: 'Invalid OTP or OTP has expired' });
        }

        // OTP is correct, so we make it permanent by removing the OTP fields.
        user.otp = undefined;
        user.otpExpires = undefined;
        await user.save(); // Save the changes to the database.

        // Send back the user data and a new JWT for authentication.
        res.status(201).json({
            _id: user._id,
            name: user.name,
            phone: user.phone,
            role: user.role,
            token: generateToken(user._id),
        });

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Send OTP for user login
// @route   POST /api/auth/login/send-otp
const sendLoginOtp = async (req, res) => {
    const { phone } = req.body;

    try {
        const user = await User.findOne({ phone });
        // If no user exists with this phone number, return a 404 Not Found error.
        if (!user) {
            return res.status(404).json({ message: 'User with this phone number not found' });
        }

        const otp = generateOTP();
        user.otp = otp;
        user.otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes expiry
        await user.save();

    
        console.log(`OTP for logging in ${phone} is: ${otp}`);
    
        res.status(200).json({ message: 'OTP sent successfully. Please check your console.' });

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Verify OTP for login
// @route   POST /api/auth/login/verify-otp
const verifyLoginOtp = async (req, res) => {
    const { phone, otp } = req.body;

    try {
        const user = await User.findOne({
            phone,
            otp,
            otpExpires: { $gt: Date.now() },
        });

        if (!user) {
            return res.status(400).json({ message: 'Invalid OTP or OTP has expired' });
        }

        // Clear the OTP fields after successful verification.
        user.otp = undefined;
        user.otpExpires = undefined;
        await user.save();

        res.status(200).json({
            _id: user._id,
            name: user.name,
            phone: user.phone,
            role: user.role,
            token: generateToken(user._id),
        });

    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};


module.exports = {
    sendRegistrationOtp,
    verifyRegistrationOtp,
    sendLoginOtp,
    verifyLoginOtp
};