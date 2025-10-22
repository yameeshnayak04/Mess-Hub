// middlewares/auth.middleware.js
const jwt = require('jsonwebtoken');
const User = require('../models/user.model.js');
const Mess = require('../models/mess.model.js');

const protect = async (req, res, next) => {
  try {
    const header = req.headers.authorization || '';
    if (!header.startsWith('Bearer ')) return res.status(401).json({ message: 'Not authorized, no token' });
    const token = header.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id).select('-otp -otpExpires'); // keep pin hidden
    if (!user) return res.status(401).json({ message: 'User not found, authorization denied' });
    req.user = user;
    return next();
  } catch (e) {
    return res.status(401).json({ message: 'Not authorized, token failed' });
  }
};

const isManager = (req, res, next) => {
  if (req.user?.role === 'manager') return next();
  return res.status(403).json({ message: 'Access denied. Manager only.' });
};

const isCustomer = (req, res, next) => {
  if (req.user?.role === 'customer') return next();
  return res.status(403).json({ message: 'Access denied. Customer only.' });
};

// Ensure the authenticated manager owns the mess in :messId
const requireMessOwner = async (req, res, next) => {
  const { messId } = req.params;
  const mess = await Mess.findById(messId).select('owner');
  if (!mess) return res.status(404).json({ message: 'Mess not found' });
  if (String(mess.owner) !== String(req.user._id)) return res.status(403).json({ message: 'Not authorized for this mess' });
  return next();
};

module.exports = { protect, isManager, isCustomer, requireMessOwner };
