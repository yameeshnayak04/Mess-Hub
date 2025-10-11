// This file defines the contract for the authentication repository.
// It's an abstract class, meaning it only defines the methods that must be implemented.

import 'package:mess_management_system/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  // Contract for sending a registration OTP.
  // It takes a name and phone and returns a success message or throws an error.
  Future<void> sendRegistrationOtp(String name, String phone, String role);

  // Contract for verifying the registration OTP.
  // It takes a phone and OTP and returns a User entity upon success.
  Future<User> verifyRegistrationOtp(String phone, String otp);

  // Contract for sending a login OTP.
  Future<void> sendLoginOtp(String phone);

  // Contract for verifying the login OTP.
  Future<User> verifyLoginOtp(String phone, String otp);
}
