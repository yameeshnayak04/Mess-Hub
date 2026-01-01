const mongoose = require('mongoose');

const HHMM = /^([01]\d|2[0-3]):([0-5]\d)$/;

const messSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    messName: { type: String, required: [true, 'Mess name is required'], trim: true },
    messImage: { type: String },

    // GeoJSON Point with bounds validation
    location: {
      type: { type: String, enum: ['Point'], required: true },
      coordinates: {
        type: [Number],
        required: true,
        validate: {
          validator: function (v) {
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

    address: { type: String, required: [true, 'Address is required'], trim: true },
    city: { type: String, required: [true, 'City is required'], trim: true },
    contactPhone: {
      type: String,
      required: [true, 'Contact phone is required'],
      trim: true,
      match: [/^[0-9]{10}$/, 'Please provide a valid 10-digit phone number'],
    },

    serviceType: {
      type: String,
      enum: ['Monthly Only', 'Both Daily & Monthly'],
      required: [true, 'Service type is required'],
    },
    cuisine: {
      type: String,
      enum: ['Veg', 'Non-Veg', 'Both'],
      required: [true, 'Cuisine type is required'],
    },
    maxCapacity: { type: Number, min: 1 },

    tiffinService: { type: Boolean, required: true },
    basicThaliDetails: { type: String, required: [true, 'Thali Details is required'], trim: true },

    timings: {
      lunch: {
        start: { type: String, required: true, set: (v) => v?.trim(), validate: HHMM },
        end: { type: String, required: true, set: (v) => v?.trim(), validate: HHMM },
      },
      dinner: {
        start: { type: String, required: true, set: (v) => v?.trim(), validate: HHMM },
        end: { type: String, required: true, set: (v) => v?.trim(), validate: HHMM },
      },
    },

    plans: [
      {
        name: { type: String, required: true },
        rate: { type: Number, required: true, min: 0 },
        // _id exists by default for subdocs; can be referenced by planId in Membership
      },
    ],

    dailyThaliRate: {
      type: Number,
      min: 0,
      required: function () {
        return this.serviceType === 'Both Daily & Monthly';
      },
    },
    rules: {
      minLeaveDaysForRebate: { type: Number, required: true, min: 1 },
      rebatePerThali: { type: Number, required: true, min: 0 },
      skipAllowancePercent: { type: Number, default: 0, min: 0, max: 100 },
      // Managers can decide if absences also earn rebatePerThali
      allowAbsentRebate: { type: Boolean, default: false },
      securityDeposit: { type: Number, min: 0 },
      minMonthlyCharge: { type: Number, min: 0 },
    },
  },
  { timestamps: true }
);

// Validate time windows: start < end for lunch and dinner
messSchema.pre('validate', function (next) {
  const parse = (t) => {
    if (!t || !HHMM.test(t)) return null;
    const [h, m] = t.split(':').map(Number);
    return h * 60 + m;
  };
  const ls = parse(this.timings?.lunch?.start);
  const le = parse(this.timings?.lunch?.end);
  const ds = parse(this.timings?.dinner?.start);
  const de = parse(this.timings?.dinner?.end);

  if (ls != null && le != null && ls > le) {
    this.invalidate('timings.lunch.end', 'Lunch end must be after start');
  }
  if (ds != null && de != null && ds > de) {
    this.invalidate('timings.dinner.end', 'Dinner end must be after start');
  }
  if (le != null && ds != null && le >= ds) {
    this.invalidate('timings.dinner.start', 'Dinner start must be after lunch end');
  }
  next();
});

// Indexes
messSchema.index({ location: '2dsphere' });
messSchema.index({ messName: 1, address: 1 }, { unique: true });
messSchema.index({ owner: 1 });
messSchema.index({ cuisine: 1 });

module.exports = mongoose.model('Mess', messSchema);
