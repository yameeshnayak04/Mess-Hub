// controllers/auth.controller.js
const User = require('../models/user.model.js');
const jwt = require('jsonwebtoken');
const asyncHandler = require('../utils/asynchandler.js');

const generateToken = (id) => jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// @desc Send OTP for user registration
// @route POST /api/auth/register/send-otp
const sendRegistrationOtp = asyncHandler(async (req, res) => {
  const { name, phone, role, pin } = req.body;

  // Validate core fields
  if (!name || !phone || !role) {
    res.status(400);
    throw new Error('Name, phone, and role are required');
  }

  if (!['customer', 'manager'].includes(role)) {
    res.status(400);
    throw new Error('Invalid role specified');
  }

  // PIN is REQUIRED only for customers
  if (role === 'customer') {
    if (!pin || !/^\d{4}$/.test(pin)) {
      res.status(400);
      throw new Error('Customers must provide a 4-digit PIN for kiosk security.');
    }
  }

  // Managers should NOT have a PIN
  if (role === 'manager' && pin) {
    res.status(400);
    throw new Error('Managers do not use a PIN. Please remove the PIN field.');
  }

  const existing = await User.findOne({ phone });
  if (existing && !existing.otp) {
    res.status(400);
    throw new Error('User with this phone number already exists');
  }

  const otp = generateOTP();
  const otpExpires = new Date(Date.now() + 10 * 60 * 1000);

  // Store PIN only if customer
  const updates = { name, phone, role, otp, otpExpires };
  if (role === 'customer') {
    updates.pin = pin;
  }

  await User.findOneAndUpdate({ phone }, updates, { upsert: true, new: true });

  // Replace with SMS integration in production
  console.log(`OTP for registering ${phone} (${role}) is: ${otp}`);
  res.status(200).json({ message: 'OTP sent successfully.' });
});

// @desc Verify OTP and complete registration
// @route POST /api/auth/register/verify-otp
const verifyRegistrationOtp = asyncHandler(async (req, res) => {
  const { phone, otp } = req.body;
  const user = await User.findOne({ phone, otp, otpExpires: { $gt: Date.now() } });
  if (!user) {
    res.status(400);
    throw new Error('Invalid OTP or OTP has expired');
  }
  user.otp = undefined;
  user.otpExpires = undefined;
  await user.save();
  res.status(201).json({
    _id: user._id,
    name: user.name,
    phone: user.phone,
    role: user.role,
    token: generateToken(user._id),
  });
});

// @desc Send OTP for login
// @route POST /api/auth/login/send-otp
const sendLoginOtp = asyncHandler(async (req, res) => {
  const { phone } = req.body;
  const user = await User.findOne({ phone });
  if (!user) {
    res.status(404);
    throw new Error('User with this phone number not found');
  }
  const otp = generateOTP();
  user.otp = otp;
  user.otpExpires = new Date(Date.now() + 10 * 60 * 1000);
  await user.save();
  console.log(`OTP for logging in ${phone} is: ${otp}`);
  res.status(200).json({ message: 'OTP sent successfully.' });
});

// @desc Verify login OTP
// @route POST /api/auth/login/verify-otp
const verifyLoginOtp = asyncHandler(async (req, res) => {
  const { phone, otp } = req.body;
  const user = await User.findOne({ phone, otp, otpExpires: { $gt: Date.now() } });
  if (!user) {
    res.status(400);
    throw new Error('Invalid OTP or OTP has expired');
  }
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
});

// @desc Update PIN (only for customers)
// @route PUT /api/auth/me/pin
const updatePin = asyncHandler(async (req, res) => {
  const { pin } = req.body;

  // Only customers can set/update a PIN
  if (req.user.role !== 'customer') {
    res.status(403);
    throw new Error('Only customers can set a kiosk PIN.');
  }

  if (!pin || !/^\d{4}$/.test(pin)) {
    res.status(400);
    throw new Error('A 4-digit PIN is required.');
  }

  const user = await User.findById(req.user._id);
  if (!user) {
    res.status(404);
    throw new Error('User not found.');
  }

  user.pin = pin; // will be hashed by pre-save hook
  await user.save();
  res.status(200).json({ message: 'PIN has been updated successfully.' });
});

module.exports = {
  sendRegistrationOtp,
  verifyRegistrationOtp,
  sendLoginOtp,
  verifyLoginOtp,
  updatePin,
};
