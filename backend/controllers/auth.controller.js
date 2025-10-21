// controllers/auth.controller.js
const User = require('../models/user.model.js');
const jwt = require('jsonwebtoken');
const asyncHandler = require('../utils/asynchandler.js');

const generateToken = (id) => jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

const sendRegistrationOtp = asyncHandler(async (req, res) => {
  const { name, phone, role, pin } = req.body;
  if (!name || !phone || !role || !pin) {
    res.status(400);
    throw new Error('Name, phone, role, and a 4-digit PIN are required');
  }
  if (!['customer', 'manager'].includes(role)) {
    res.status(400);
    throw new Error('Invalid role specified');
  }
  if (!/^\d{4}$/.test(pin)) {
    res.status(400);
    throw new Error('PIN must be 4 digits.');
  }

  const existing = await User.findOne({ phone });
  if (existing && !existing.otp) {
    res.status(400);
    throw new Error('User with this phone number already exists');
  }

  const otp = generateOTP();
  const otpExpires = new Date(Date.now() + 10 * 60 * 1000);
  await User.findOneAndUpdate(
    { phone },
    { name, phone, role, pin, otp, otpExpires },
    { upsert: true, new: true }
  );
  // Replace with SMS integration in production
  console.log(`OTP for registering ${phone} (${role}) is: ${otp}`);
  res.status(200).json({ message: 'OTP sent successfully.' });
});

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
  res.status(201).json({ _id: user._id, name: user.name, phone: user.phone, role: user.role, token: generateToken(user._id) });
});

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
  res.status(200).json({ _id: user._id, name: user.name, phone: user.phone, role: user.role, token: generateToken(user._id) });
});

const updatePin = asyncHandler(async (req, res) => {
  const { pin } = req.body;
  if (!pin || !/^\d{4}$/.test(pin)) {
    res.status(400);
    throw new Error('A 4-digit PIN is required.');
  }
  const user = await User.findById(req.user.id);
  if (!user) {
    res.status(404);
    throw new Error('User not found.');
  }
  user.pin = pin; // will be hashed by pre-save hook
  await user.save();
  res.status(200).json({ message: 'PIN has been updated successfully.' });
});

module.exports = { sendRegistrationOtp, verifyRegistrationOtp, sendLoginOtp, verifyLoginOtp, updatePin };
