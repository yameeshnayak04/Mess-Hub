// This file defines the final, clean data structure for all users.

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs'); // For hashing the PIN

const UserSchema = new mongoose.Schema({
  name: { type: String, required: [true, 'Please provide a name'] },
  phone: {
    type: String,
    required: [true, 'Please provide a phone number'],
    unique: true,
    match: [/^\d{10}$/, 'Please provide a valid 10-digit phone number'],
  },
  role: {
    type: String,
    enum: ['customer', 'manager'],
    required: [true, 'Please specify a role'],
  },
  // This is the single source of truth for the Kiosk PIN.
  pin: { type: String, select: false }, // 'select: false' hides it from normal queries.
  photoUrl: { type: String, default: '' },
  
  // These fields are temporary for the OTP verification process.
  otp: { type: String, select: false },
  otpExpires: { type: Date, select: false },
}, { timestamps: true });

// Mongoose "pre-save hook" to automatically hash the PIN whenever it is changed.
UserSchema.pre('save', async function(next) {
  if (!this.isModified('pin') || !this.pin) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.pin = await bcrypt.hash(this.pin, salt);
  next();
});

// A method on the user document to securely compare an entered PIN.
UserSchema.methods.comparePin = async function(enteredPin) {
    if (!this.pin) return false; // Fails if PIN is not set.
    return await bcrypt.compare(enteredPin, this.pin);
};

const User = mongoose.model('User', UserSchema);
module.exports = User;