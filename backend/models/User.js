const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const bcryptjs = require('bcryptjs')

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      unique: true,
      match: [/^\d{10}$/, 'Please provide a valid 10-digit phone number'],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [8, 'Password must be at least 8 characters'],
      select: false,
    },
    role: {
      type: String,
      enum: ['Customer', 'Manager'],
      required: [true, 'Role is required'],
    },
    pin: {
      type: String,
      validate: {
        validator: function (v) {
          if (this.role === 'Customer') {
            return v && /^\d{4}$/.test(v);
          }
          return true;
        },
        message: 'PIN must be 4 digits for customers',
      },
      select: false,
    },
    // Only required/validated for Customers
    location: {
      type: {
        type: String,
        enum: ['Point'],
        required: function () {
          return this.role === 'Customer';
        },
      },
      coordinates: {
        type: [Number], // [lng, lat]
        required: function () {
          return this.role === 'Customer';
        },
        validate: {
          validator: function (v) {
            if (this.role !== 'Customer') return true;
            // Expect [lng, lat], with valid ranges
            return (
              Array.isArray(v) &&
              v.length === 2 &&
              v.every((n) => typeof n === 'number' && Number.isFinite(n)) &&
              v[0] >= -180 &&
              v[0] <= 180 &&
              v[1] >= -90 &&
              v[1] <= 90
            );
          },
          message:
            'Coordinates must be [lng, lat] with lng in [-180,180] and lat in [-90,90]',
        },
      },
    },
  },
  { timestamps: true }
);

// Optional: remove the manual location check since 'required' handles it for customers
userSchema.pre('validate', function (next) {
  if (this.role === 'Customer' && !this.pin) {
    this.invalidate('pin', 'PIN is required for customers');
  }
  next();
});

userSchema.methods.comparePassword = async function (enteredPassword) {
   // 'this.password' refers to the hashed password stored in the document
   // Need to make sure 'this.password' is selected when fetching the user if it was excluded by default
  return await bcrypt.compare(enteredPassword, this.password);
};

userSchema.pre('save', async function (next) {
  // Only hash the password if it has been modified (or is new)
  if (!this.isModified('password')) {
    return next();
  }

  try {
    // Generate a salt
    const salt = await bcrypt.genSalt(10); // 10 rounds is generally recommended
    // Hash the password using the salt
    this.password = await bcrypt.hash(this.password, salt);

    next(); // Proceed to save
  } catch (error) {
     console.error('Error during password hashing:', error);
    next(error); // Pass error to Mongoose error handling
  }
});

// 2dsphere index for geospatial queries
userSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('User', userSchema);
