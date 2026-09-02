// new_backend/middleware/asyncHandler.js
//
// Express 4 does not catch errors thrown inside async route handlers — the
// promise just rejects and the request hangs forever. Wrapping every handler
// in this means any thrown error goes to the global error handler instead.
//
// This replaces the try/catch { next(error) } block that was repeated in
// every single controller function in the old backend (and forgotten in a
// few, which is exactly how requests ended up hanging).
function asyncHandler(handler) {
  return (req, res, next) => {
    Promise.resolve(handler(req, res, next)).catch(next);
  };
}

module.exports = asyncHandler;
