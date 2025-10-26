const { required } = require('joi');
const mongoose = require('mongoose');

const messSchema = new mongoose.Schema({
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  messName: {
    type: String,
    required: [true, 'Mess name is required'],
    trim: true
  },
  messImage: {
    type: String
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      required: true
    },
    coordinates: {
      type: [Number],
      required: true
    }
  },
  address: {
    type: String,
    required: [true, 'Address is required'],
    trim: true
  },
  city: {
    type: String,
    required: [true, 'City is required'],
    trim: true
  },
  contactPhone: {
    type: String,
    required: [true, 'Contact phone is required'],
    trim: true,
    match: [/^[0-9]{10}$/, 'Please provide a valid 10-digit phone number']
  },
  serviceType: {
    type: String,
    enum: ['Monthly Only', 'Both Daily & Monthly'],
    required: [true, 'Service type is required']
  },
  cuisine: {
    type: String,
    enum: ['Veg', 'Non-Veg', 'Both'],
    required: [true, 'Cuisine type is required']
  },
  maxCapacity: {
    type: Number,
    min: 1
  },
  tiffinService:{
    type : Boolean,
    required : true,
  },
  basicThaliDetails: {
    type: String,
    required: [true, 'Thali Details is required'],
    trim: true
  },
  timings: {
    lunch: {
      start: {
        type: String,
        required: true
      },
      end: {
        type: String,
        required: true
      }
    },
    dinner: {
      start: {
        type: String,
        required: true
      },
      end: {
        type: String,
        required: true
      }
    }
  },
  plans: [{
    name: {
      type: String,
      required: true
    },
    rate: {
      type: Number,
      required: true,
      min: 0
    }
  }],
  dailyThaliRate: {
    type: Number,
    min: 0,
    required: function() {
      return this.serviceType === 'Both Daily & Monthly';
    }
  },
  rules: {
    minLeaveDaysForRebate: {
      type: Number,
      required: true,
      min: 1
    },
    rebatePerThali: {
      type: Number,
      required: true,
      min: 0
    },
    skipAllowancePercent: {
      type: Number,
      default: 0,
      min: 0,
      max: 100
    },
    securityDeposit: {
      type: Number,
      min: 0
    },
    minMonthlyCharge: {
      type: Number,
      min: 0
    }
  }
}, {
  timestamps: true
});

// Create 2dsphere index for location
messSchema.index({ location: '2dsphere' });

// Create compound unique index on messName and address
messSchema.index({ messName: 1, address: 1 }, { unique: true });

module.exports = mongoose.model('Mess', messSchema);
