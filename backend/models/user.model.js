// models/user.model.js
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs'); // For hashing the PIN

const UserSchema = new mongoose.Schema(
  {
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
    // Single source of truth for Kiosk PIN (hashed)
    pin: { type: String, select: false },
    photoUrl: { type: String, default: '' },

    // OTP fields for registration/login
    otp: { type: String, select: false },
    otpExpires: { type: Date, select: false },
  },
  { timestamps: true }
);

// Hash the PIN whenever it changes (fix: ensure early return closes correctly)
UserSchema.pre('save', async function (next) {
  if (!this.isModified('pin') || !this.pin) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.pin = await bcrypt.hash(this.pin, salt);
  next();
});

// Secure PIN comparison
UserSchema.methods.comparePin = async function (enteredPin) {
  if (!this.pin) return false;
  return bcrypt.compare(enteredPin, this.pin);
};

module.exports = mongoose.model('User', UserSchema);
