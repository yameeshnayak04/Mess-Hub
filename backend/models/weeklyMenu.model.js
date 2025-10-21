// models/weeklyMenu.model.js
const mongoose = require('mongoose');

const DayMenuSchema = new mongoose.Schema({
  day: { type: String, enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'], required: true },
  lunch: { type: String },
  dinner: { type: String },
  lunchImage: { type: String },
  dinnerImage: { type: String },
});

const WeeklyMenuSchema = new mongoose.Schema(
  {
    mess: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Mess' },
    weekIdentifier: { type: String, required: true }, // e.g., "2025-W42"
    days: [DayMenuSchema],
  },
  { timestamps: true }
);

WeeklyMenuSchema.index({ mess: 1, weekIdentifier: 1 }, { unique: true });

module.exports = mongoose.model('WeeklyMenu', WeeklyMenuSchema);
