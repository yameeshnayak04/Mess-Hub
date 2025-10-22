// models/dailyMenu.model.js
const mongoose = require('mongoose');

const DailyMenuSchema = new mongoose.Schema(
  {
    mess: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Mess' },
    date: { type: Date, required: true }, // normalized to start of day (YYYY-MM-DD)
    lunch: { type: String },
    dinner: { type: String },
    lunchImage: { type: String },
    dinnerImage: { type: String },
  },
  { timestamps: true }
);

// One menu per mess per date
DailyMenuSchema.index({ mess: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('DailyMenu', DailyMenuSchema);
