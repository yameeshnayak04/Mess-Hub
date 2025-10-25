const mongoose = require('mongoose');

const menuSchema = new mongoose.Schema({
  mess: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Mess',
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  lunchItems: [{
    type: String,
    trim: true
  }],
  dinnerItems: [{
    type: String,
    trim: true
  }]
}, {
  timestamps: true
});

// Compound unique index on mess and date
menuSchema.index({ mess: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Menu', menuSchema);
