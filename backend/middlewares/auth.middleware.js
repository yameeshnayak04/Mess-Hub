// middlewares/auth.middleware.js
const jwt = require('jsonwebtoken');
const User = require('../models/user.model.js');

const protect = async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = await User.findById(decoded.id).select('-otp -otpExpires -pin');
      if (!req.user) return res.status(401).json({ message: 'User not found, authorization denied' });
      return next();
    } catch (e) {
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }
  return res.status(401).json({ message: 'Not authorized, no token' });
};

const isManager = (req, res, next) => {
  if (req.user && req.user.role === 'manager') return next();
  return res.status(403).json({ message: 'Access denied. Route requires manager privileges.' });
};

const isCustomer = (req, res, next) => {
  if (req.user && req.user.role === 'customer') return next();
  return res.status(403).json({ message: 'Access denied. Route requires customer privileges.' });
};

module.exports = { protect, isManager, isCustomer };
