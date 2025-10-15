// This file contains the final logic for user authentication, registration, and PIN management.

const User = require('../models/user.model.js');
const jwt = require('jsonwebtoken');

// --- Helper Functions ---
const generateToken = (id) => jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// @desc    Send OTP for user registration
// @route   POST /api/auth/register/send-otp
const sendRegistrationOtp = async (req, res) => {
  const { name, phone, role } = req.body;
  if (!name || !phone || !role) return res.status(400).json({ message: 'Name, phone, and role are required' });
  if (!['customer', 'manager'].includes(role)) return res.status(400).json({ message: 'Invalid role specified' });

  try {
    const userExists = await User.findOne({ phone });
    // Check if user is fully registered (OTP is cleared)
    if (userExists && !userExists.otp) {
        return res.status(400).json({ message: 'User with this phone number already exists' });
    }

    const otp = generateOTP();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // OTP expires in 10 minutes

    // Create a new temporary user or update an existing one
    await User.findOneAndUpdate({ phone }, { name, phone, role, otp, otpExpires }, { upsert: true, new: true });

    console.log(`OTP for registering ${phone} (${role}) is: ${otp}`);
    res.status(200).json({ message: 'OTP sent successfully. Please check your console.' });
  } catch (error) {
    res.status(500).json({ message: 'Server Error', error: error.message });
  }
};

// @desc    Verify OTP for registration and create the user
const verifyRegistrationOtp = async (req, res) => {
    const { phone, otp } = req.body;
    try {
        const user = await User.findOne({ phone, otp, otpExpires: { $gt: Date.now() } });
        if (!user) return res.status(400).json({ message: 'Invalid OTP or OTP has expired' });

        // Make the user permanent by clearing OTP fields
        user.otp = undefined;
        user.otpExpires = undefined;
        await user.save();

        res.status(201).json({ _id: user._id, name: user.name, phone: user.phone, role: user.role, token: generateToken(user._id) });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Send OTP for user login
const sendLoginOtp = async (req, res) => {
    const { phone } = req.body;
    try {
        const user = await User.findOne({ phone });
        if (!user) return res.status(404).json({ message: 'User with this phone number not found' });
        
        const otp = generateOTP();
        user.otp = otp;
        user.otpExpires = new Date(Date.now() + 10 * 60 * 1000);
        await user.save();
        
        console.log(`OTP for logging in ${phone} is: ${otp}`);
        res.status(200).json({ message: 'OTP sent successfully.' });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Verify OTP for login
const verifyLoginOtp = async (req, res) => {
    const { phone, otp } = req.body;
    try {
        const user = await User.findOne({ phone, otp, otpExpires: { $gt: Date.now() } });
        if (!user) return res.status(400).json({ message: 'Invalid OTP or OTP has expired' });

        user.otp = undefined;
        user.otpExpires = undefined;
        await user.save();
        
        res.status(200).json({ _id: user._id, name: user.name, phone: user.phone, role: user.role, token: generateToken(user._id) });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

// @desc    Set or reset a user's Kiosk PIN
// @route   PUT /api/auth/me/pin
// @access  Private (Customer or Manager)
const setPin = async (req, res) => {
    const { pin } = req.body;
    // Basic validation for the PIN
    if (!pin || !/^\d{4}$/.test(pin)) {
        return res.status(400).json({ message: 'A 4-digit PIN is required.' });
    }
    try {
        // req.user is attached by the 'protect' middleware
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ message: 'User not found.' });

        user.pin = pin; // The pre-save hook in the user model will hash this automatically
        await user.save();
        
        res.status(200).json({ message: 'PIN has been set successfully.' });
    } catch (error) {
        res.status(500).json({ message: 'Server Error', error: error.message });
    }
};

module.exports = {
    sendRegistrationOtp,
    verifyRegistrationOtp,
    sendLoginOtp,
    verifyLoginOtp,
    setPin, // Export the new PIN function
};