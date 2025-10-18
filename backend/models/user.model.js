// This file defines the data structure for all users in the application.

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs'); // We will use bcrypt to hash the PIN

const UserSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please provide a name'], // Error message if not provided
  },
  phone: {
    type: String,
    required: [true, 'Please provide a phone number'],
    unique: true, // No two users can have the same phone number
    match: [/^\d{10}$/, 'Please provide a valid 10-digit phone number'],
  },
  role: {
    type: String,
    enum: ['customer', 'manager'], // Role must be one of these two values
    required: [true, 'Please specify a role'],
  },
  // This will store the hashed version of the user's Kiosk PIN.
  pin: {
    type: String,
    // We only select the pin when we explicitly need to (e.g., for comparison).
    // It will not be returned in general user queries.
    select: false,
  },
  photoUrl: {
    type: String,
    default: '',
  },
  // These fields are temporary for the OTP verification process.
  otp: {
    type: String,
    select: false,
  },
  otpExpires: {
    type: Date,
    select: false,
  },
  kioskPinHash: { type: String, select: false },
  kioskPinSetAt: { type: Date },
}, {
  timestamps: true // Automatically adds createdAt and updatedAt fields
});

// Mongoose "pre-save hook": This function runs automatically right before a user document is saved.
// We use it to hash the PIN if it has been modified.
UserSchema.pre('save', async function(next) {
  // Only run this function if the pin was actually modified (or is new)
  if (!this.isModified('pin') || !this.pin) {
    return next();
  }
  // Hash the pin with a salt round of 10
  const salt = await bcrypt.genSalt(10);
  this.pin = await bcrypt.hash(this.pin, salt);
  next();
});

// Method to compare entered PIN with the hashed PIN in the database
UserSchema.methods.comparePin = async function(enteredPin) {
    if (!this.pin) return false;
    return await bcrypt.compare(enteredPin, this.pin);
};

// Helper to set PIN
UserSchema.methods.setKioskPin = async function(pin) {
  const salt = await bcrypt.genSalt(12);
  this.kioskPinHash = await bcrypt.hash(pin, salt);
  this.kioskPinSetAt = new Date();
};

// Helper to verify PIN
UserSchema.methods.verifyKioskPin = async function(pin) {
  if (!this.kioskPinHash) return false;
  return bcrypt.compare(pin, this.kioskPinHash);
};

const User = mongoose.model('User', UserSchema);
module.exports = User;