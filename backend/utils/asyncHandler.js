// backend/utils/asyncHandler.js

// This is a simple wrapper for our async controller functions.
// It catches any errors that occur in an async function and passes them
// to the next middleware in the chain (our global errorHandler).
// This prevents us from having to write try-catch blocks in every controller function.
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

module.exports = asyncHandler;