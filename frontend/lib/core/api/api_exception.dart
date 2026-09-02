// lib/core/api/api_exception.dart
//
// The backend answers every request with one of two shapes:
//
//   { "success": true,  "data": ..., "meta": {...} }
//   { "success": false, "code": "VALIDATION_ERROR", "message": "..." }
//
// So the useful signal on failure is `code`, not the HTTP status. This class
// carries that code through to the UI, and `friendlyMessage` turns it into
// something worth showing a user.
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  ApiException({required this.code, required this.message, this.statusCode});

  /// The backend writes customer-facing text for the errors a user can
  /// actually cause (a leave that is too short, a mess that is full), so we
  /// prefer its message. These are the fallbacks for codes where the raw
  /// message is too technical, or where no message came back at all.
  String get friendlyMessage {
    if (message.trim().isNotEmpty) return message;
    switch (code) {
      case 'UNAUTHENTICATED':
        return 'Please log in again.';
      case 'BAD_CREDENTIALS':
        return 'Phone number or password is incorrect.';
      case 'BAD_PIN':
        return 'Incorrect PIN.';
      case 'FORBIDDEN':
        return 'You do not have permission to do that.';
      case 'NOT_FOUND':
        return 'We could not find that.';
      case 'PHONE_TAKEN':
        return 'An account with this phone number already exists.';
      case 'MESS_FULL':
        return 'This mess is full right now.';
      case 'OUTSTANDING_BILLS':
        return 'There are unpaid bills to settle first.';
      case 'INCOMPLETE_ATTENDANCE_DATA':
        return 'Attendance for this period is still being recorded. Try again shortly.';
      case 'OVERLAPPING_PERIOD':
        return 'Those dates overlap something already booked.';
      case 'DUPLICATE':
        return 'That already exists.';
      case 'TOO_MANY_REQUESTS':
        return 'Too many attempts. Please wait a few minutes.';
      case 'NETWORK':
        return 'Could not reach the server. Check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  /// True when the session is gone and the user has to sign in again.
  bool get isUnauthenticated => code == 'UNAUTHENTICATED';

  @override
  String toString() => friendlyMessage;
}
