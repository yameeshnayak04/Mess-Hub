const mongoose = require('mongoose');

const DayMenuSchema = new mongoose.Schema({
    day: { type: String, enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'], required: true },
    lunch: { type: String },
    dinner: { type: String },
    lunchImage: { type: String },
    dinnerImage: { type: String },
});

const WeeklyMenuSchema = new mongoose.Schema({
    mess: { type: mongoose.Schema.Types.ObjectId, required: true, ref: 'Mess' },
    weekIdentifier: { type: String, required: true }, // e.g., "2025-W42"
    days: [DayMenuSchema],
}, { timestamps: true });

// **CRITICAL FIX**: Create a compound unique index.
// This ensures that for a single mess, the weekIdentifier must be unique.
// However, different messes can have the same weekIdentifier.
WeeklyMenuSchema.index({ mess: 1, weekIdentifier: 1 }, { unique: true });

const WeeklyMenu = mongoose.model('WeeklyMenu', WeeklyMenuSchema);
module.exports = WeeklyMenu;