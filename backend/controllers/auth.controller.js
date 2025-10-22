// controllers/auth.controller.js
const User = require('../models/user.model.js');
const jwt = require('jsonwebtoken');

const asyncHandler = require('../utils/asynchandler.js');

const generateToken = (id) => jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// Register OTP
const sendRegistrationOtp = asyncHandler(async (req, res) => {
  const { name, phone, role, pin } = req.body;
  if (!name || !phone || !role) { res.status(400); throw new Error('Name, phone, and role are required'); }
  if (!['customer', 'manager'].includes(role)) { res.status(400); throw new Error('Invalid role specified'); }
  if (role === 'customer') {
    if (!pin || !/^\d{4}$/.test(pin)) { res.status(400); throw new Error('Customers must provide a 4-digit PIN for kiosk security.'); }
  } else if (pin) { res.status(400); throw new Error('Managers do not use a PIN.'); }
  const existing = await User.findOne({ phone });
  if (existing && !existing.otp) { res.status(400); throw new Error('User with this phone number already exists'); }
  const otp = generateOTP();
  const otpExpires = new Date(Date.now() + 10 * 60 * 1000);
  const updates = { name, phone, role, otp, otpExpires };
  if (role === 'customer') updates.pin = pin; // hashed in pre-save on verify step if new doc, or here via findOneAndUpdate+save below
  await User.findOneAndUpdate({ phone }, updates, { upsert: true, new: true, setDefaultsOnInsert: true });
  // TODO: Integrate SMS gateway
  console.log(`OTP for registering ${phone} (${role}): ${otp}`);
  res.status(200).json({ message: 'OTP sent successfully.' });
});

// Verify Registration OTP
const verifyRegistrationOtp = asyncHandler(async (req, res) => {
  const { phone, otp } = req.body;
  // Load with pin to trigger hashing if modified
  const user = await User.findOne({ phone, otp, otpExpires: { $gt: Date.now() } }).select('+pin');
  if (!user) { res.status(400); throw new Error('Invalid or expired OTP'); }
  user.otp = undefined;
  user.otpExpires = undefined;
  // Ensure pin hashing occurs if present
  await user.save();
  res.status(201).json({ _id: user._id, name: user.name, phone: user.phone, role: user.role, token: generateToken(user._id) });
});

// Login OTP
const sendLoginOtp = asyncHandler(async (req, res) => {
  const { phone } = req.body;
  const user = await User.findOne({ phone });
  if (!user) { res.status(404); throw new Error('User with this phone number not found'); }
  const otp = generateOTP();
  user.otp = otp;
  user.otpExpires = new Date(Date.now() + 10 * 60 * 1000);
  await user.save();
  console.log(`OTP for logging in ${phone}: ${otp}`);
  res.status(200).json({ message: 'OTP sent successfully.' });
});

// Verify Login OTP
const verifyLoginOtp = asyncHandler(async (req, res) => {
  const { phone, otp } = req.body;
  const user = await User.findOne({ phone, otp, otpExpires: { $gt: Date.now() } });
  if (!user) { res.status(400); throw new Error('Invalid or expired OTP'); }
  user.otp = undefined;
  user.otpExpires = undefined;
  await user.save();
  res.status(200).json({ _id: user._id, name: user.name, phone: user.phone, role: user.role, token: generateToken(user._id) });
});

// Update Kiosk PIN (customers only)
const updatePin = asyncHandler(async (req, res) => {
  if (req.user.role !== 'customer') { res.status(403); throw new Error('Only customers can set a kiosk PIN.'); }
  const { pin } = req.body;
  if (!pin || !/^\d{4}$/.test(pin)) { res.status(400); throw new Error('A 4-digit PIN is required.'); }
  const user = await User.findById(req.user._id).select('+pin');
  if (!user) { res.status(404); throw new Error('User not found.'); }
  user.pin = pin; // hashed by pre-save
  await user.save();
  res.status(200).json({ message: 'PIN updated successfully.' });
});

module.exports = { sendRegistrationOtp, verifyRegistrationOtp, sendLoginOtp, verifyLoginOtp, updatePin };
