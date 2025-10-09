// This file defines the data structure for users.

// Import Mongoose, an ODM library for MongoDB, to define schemas and models.
const mongoose = require('mongoose');

// Define the schema for the User collection.
const UserSchema = new mongoose.Schema({
  // 'name' field is a string and is required for every user.
  name: {
    type: String,
    required: true,
  },
  // 'phone' is a string, required, must be unique, and must be 10 digits.
  phone: {
    type: String,
    required: true,
    unique: true,
    match: [/^\d{10}$/, 'Please fill a valid 10-digit phone number'],
  },
  // 'role' determines if the user is a customer or a mess owner.
  // 'enum' restricts the value to be one of the specified strings.
  role: {
    type: String,
    enum: ['customer', 'manager'], // The role can only be 'customer' or 'manager'.
    required: true,
  },
  // 'otp' and 'otpExpires' are used for the phone verification process.
  // They are not required and will only be present temporarily.
  otp: {
    type: String,
  },
  otpExpires: {
    type: Date,
  },
  // 'photoUrl' can store a link to the user's profile picture for the Kiosk.
  photoUrl: {
    type: String,
    default: '', // Default to an empty string if no photo is provided.
  },
}, {
  // 'timestamps: true' automatically adds 'createdAt' and 'updatedAt' fields.
  timestamps: true
});

// Create the User model from the schema.
const User = mongoose.model('User', UserSchema);

// Export the model to be used in other parts of the application.
module.exports = User;