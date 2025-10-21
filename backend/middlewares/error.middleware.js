// This file defines middleware for centralized error handling.

// Middleware to handle requests for routes that do not exist (404 Not Found).
const notFound = (req, res, next) => {
  const error = new Error(`Not Found - ${req.originalUrl}`);
  res.status(404);
  // Pass the error to the next middleware in the chain (which will be our errorHandler).
  next(error);
};

// Main error handling middleware. Express recognizes this by its 4 arguments.
const errorHandler = (err, req, res, next) => {
  // If an error occurs but the status code is still 200 (OK), default to 500 (Internal Server Error).
  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  res.status(statusCode);

  // Send a structured JSON response with the error message.
  res.json({
    message: err.message,
    // Only show the detailed stack trace if we are in a development environment for easier debugging.
    // In production, we hide the stack trace for security reasons.
    stack: process.env.NODE_ENV === 'production' ? null : err.stack,
  });
};

// Export the middleware functions.
module.exports = { notFound, errorHandler };