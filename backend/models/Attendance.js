const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: function() {
      return this.memberType === 'Monthly';
    }
  },
  mess: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Mess',
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  mealType: {
    type: String,
    enum: ['Lunch', 'Dinner'],
    required: true
  },
  status: {
    type: String,
    enum: ['Present', 'Skipped', 'Leave', 'Absent'],
    required: true
  },
  memberType: {
    type: String,
    enum: ['Monthly', 'Daily'],
    default: 'Monthly'
  }
}, {
  timestamps: true
});

// Compound indexes for efficient queries
attendanceSchema.index({ user: 1, mess: 1, date: 1, mealType: 1 });
attendanceSchema.index({ mess: 1, date: 1, mealType: 1, status: 1 });
attendanceSchema.index({ mess: 1, date: 1, memberType: 1, status: 1 });

module.exports = mongoose.model('Attendance', attendanceSchema);
