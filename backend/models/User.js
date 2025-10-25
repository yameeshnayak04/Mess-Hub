const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    unique: true,
    trim: true,
    match: [/^[0-9]{10}$/, 'Please provide a valid 10-digit phone number']
  },
  kioskPin: {
    type: String,
    required: function() {
      return this.role === 'Customer';
    },
    match: [/^[0-9]{4}$/, 'Kiosk PIN must be 4 digits']
  },
  role: {
    type: String,
    enum: ['Customer', 'Manager'],
    required: [true, 'Role is required']
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      required: function() {
        return this.role === 'Customer';
      }
    },
    coordinates: {
      type: [Number],
      required: function() {
        return this.role === 'Customer';
      }
    }
  }
}, {
  timestamps: true
});

// Create 2dsphere index for location
userSchema.index({ location: '2dsphere' });

// REMOVE THIS LINE - it's causing the duplicate index warning:
// userSchema.index({ phone: 1 });

// Hash kiosk PIN before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('kioskPin') || !this.kioskPin) {
    return next();
  }

  try {
    const salt = await bcrypt.genSalt(10);
    this.kioskPin = await bcrypt.hash(this.kioskPin, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Method to compare kiosk PIN
userSchema.methods.compareKioskPin = async function(enteredPin) {
  return await bcrypt.compare(enteredPin, this.kioskPin);
};

module.exports = mongoose.model('User', userSchema);
