// lib/features/auth/domain/repositories/auth_repository.dart

import 'package:mess_management_system/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  // PIN is now required for customer registration
  Future<void> sendRegistrationOtp(
      String name, String phone, String role, String? pin);

  Future<User> verifyRegistrationOtp(String phone, String otp);

  Future<void> sendLoginOtp(String phone);

  Future<User> verifyLoginOtp(String phone, String otp);
}
