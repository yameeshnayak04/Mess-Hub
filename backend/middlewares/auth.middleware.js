// This file defines middleware for protecting routes and checking user roles.

// Import required libraries and models.
const jwt = require('jsonwebtoken');
const User = require('../models/user.model.js');

// --- Main Protection Middleware ---
// This function checks for a valid JWT in the request headers.
const protect = async (req, res, next) => {
  let token;

  // 1. Check if the 'Authorization' header exists and starts with 'Bearer'.
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      // 2. Extract the token from the header (format is "Bearer <token>").
      token = req.headers.authorization.split(' ')[1];

      // 3. Verify the token using the secret key from your .env file.
      // This will throw an error if the token is invalid or expired.
      const decoded = jwt.verify(token, process.env.JWT_SECRET);

      // 4. If verification is successful, find the user in the database using the ID from the token's payload.
      // We use .select('-otp -otpExpires') to exclude these temporary fields from the user object.
      req.user = await User.findById(decoded.id).select('-otp -otpExpires');
      
      // If for some reason the user from the token doesn't exist in the DB, deny access.
      if (!req.user) {
          return res.status(401).json({ message: 'User not found, authorization denied' });
      }

      // 5. If everything is okay, call next() to pass control to the next middleware or the route controller.
      next();
    } catch (error) {
      // This block runs if jwt.verify fails.
      console.error(error);
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  // If there's no token in the header at all, deny access.
  if (!token) {
    return res.status(401).json({ message: 'Not authorized, no token' });
  }
};


// --- Role-Based Middleware ---
// These functions should be used *after* the 'protect' middleware in your routes.

// Checks if the logged-in user has the 'manager' role.
const isManager = (req, res, next) => {
    // It assumes 'protect' has already run and attached req.user.
    if (req.user && req.user.role === 'manager') {
        next(); // User is a manager, proceed.
    } else {
        // 403 Forbidden is the correct status code for a user who is logged in
        // but does not have the necessary permissions for an action.
        res.status(403).json({ message: 'Access denied. Route requires manager privileges.' });
    }
};

// Checks if the logged-in user has the 'customer' role.
const isCustomer = (req, res, next) => {
    if (req.user && req.user.role === 'customer') {
        next(); // User is a customer, proceed.
    } else {
        res.status(403).json({ message: 'Access denied. Route requires customer privileges.' });
    }
};


// Export the middleware functions to be used in your route files.
module.exports = { protect, isManager, isCustomer };