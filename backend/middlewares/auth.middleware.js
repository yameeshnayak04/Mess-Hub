// This file defines middleware for protecting routes and checking user roles.

const jwt = require('jsonwebtoken');
const User = require('../models/user.model.js');

// --- Main Protection Middleware ---
const protect = async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // Find the user from the token's payload.
      // CORRECTED: Also exclude the 'pin' for better security.
      req.user = await User.findById(decoded.id).select('-otp -otpExpires -pin');
      
      if (!req.user) {
          return res.status(401).json({ message: 'User not found, authorization denied' });
      }
      next();
    } catch (error) {
      console.error(error);
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    return res.status(401).json({ message: 'Not authorized, no token' });
  }
};

// --- Role-Based Middleware ---
const isManager = (req, res, next) => {
    if (req.user && req.user.role === 'manager') {
        next();
    } else {
        res.status(403).json({ message: 'Access denied. Route requires manager privileges.' });
    }
};

const isCustomer = (req, res, next) => {
    if (req.user && req.user.role === 'customer') {
        next();
    } else {
        res.status(403).json({ message: 'Access denied. Route requires customer privileges.' });
    }
};

module.exports = { protect, isManager, isCustomer };