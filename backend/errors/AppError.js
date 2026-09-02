// new_backend/errors/AppError.js
//
// Services throw these instead of touching `res` directly. In Phase 3 a single
// global error handler turns them into HTTP responses, so business logic never
// needs to know about status codes or JSON shapes.

class AppError extends Error {
  constructor(message, statusCode, code) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.code = code;
  }
}

// Bad input, or a business rule the caller broke (e.g. leave too short).
class ValidationError extends AppError {
  constructor(message, code = 'VALIDATION_ERROR') {
    super(message, 400, code);
  }
}

class NotFoundError extends AppError {
  constructor(message) {
    super(message, 404, 'NOT_FOUND');
  }
}

class ForbiddenError extends AppError {
  constructor(message) {
    super(message, 403, 'FORBIDDEN');
  }
}

class ConflictError extends AppError {
  constructor(message, code = 'CONFLICT') {
    super(message, 409, code);
  }
}

// Thrown when billing is asked to bill a period that still has missing
// attendance records. We refuse to bill rather than guess what happened on
// those days — guessing is exactly what produced wrong invoices in the old
// backend (a missing record was silently treated as a free rebate).
class IncompleteAttendanceDataError extends ConflictError {
  constructor(message) {
    super(message, 'INCOMPLETE_ATTENDANCE_DATA');
  }
}

module.exports = {
  AppError,
  ValidationError,
  NotFoundError,
  ForbiddenError,
  ConflictError,
  IncompleteAttendanceDataError,
};
