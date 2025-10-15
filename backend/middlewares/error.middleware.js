// This file defines middleware for centralized error handling.

// Middleware to handle requests for routes that do not exist (404 Not Found).
const notFound = (req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  res.status(404);
  next(error); // Pass the error to the next middleware (errorHandler).
};

// Main error handling middleware. Express recognizes this by its 4 arguments.
const errorHandler = (err, req, res, next) => {
  // If the error occurs but the status code is still 200, default to 500.
  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  res.status(statusCode);

  // Send a clean JSON error response.
  res.json({
    message: err.message,
    // Only show the detailed stack trace if we are in a development environment.
    stack: process.env.NODE_ENV === 'production' ? null : err.stack,
  });
};

// Export only the error handling middleware functions from this file.
module.exports = { notFound, errorHandler };