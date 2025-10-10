// This file defines middleware for centralized error handling.

// Middleware to handle requests for routes that do not exist (404 Not Found).
const notFound = (req, res, next) => {
  // Create a new Error object for the non-existent route.
  const error = new Error(`Not Found - ${req.originalUrl}`);
  // Set the response status code to 404.
  res.status(404);
  // Pass the error to the next middleware in the chain (which will be our errorHandler).
  next(error);
};

// Main error handling middleware. This is where all errors will end up.
// Express recognizes a middleware with 4 arguments (err, req, res, next) as an error handler.
const errorHandler = (err, req, res, next) => {
  // Sometimes, an error might occur but the status code is still 200 (OK).
  // This line sets the status code to 500 (Internal Server Error) if it's still 200, otherwise keeps the existing error code.
  const statusCode = res.statusCode === 200 ? 500 : res.statusCode;
  res.status(statusCode);

  // Send a structured JSON response with the error message.
  // In a development environment, we also send the error stack trace for easier debugging.
  // In production, we would hide the stack trace for security reasons.
  res.json({
    message: err.message,
    // The 'stack' property will only be included if the environment is not 'production'.
    stack: process.env.NODE_ENV === 'production' ? null : err.stack,
  });
};

// Export the middleware functions.
module.exports = { notFound, errorHandler };