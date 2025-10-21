// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:mess_management_system/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mess_management_system/features/auth/domain/entities/user.dart';
import 'package:mess_management_system/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> sendRegistrationOtp(
      String name, String phone, String role, String? pin) async {
    return remoteDataSource.sendRegistrationOtp(name, phone, role, pin);
  }

  @override
  Future<User> verifyRegistrationOtp(String phone, String otp) async {
    final userData = await remoteDataSource.verifyRegistrationOtp(phone, otp);
    return User(
      id: userData['_id'],
      name: userData['name'],
      phone: userData['phone'],
      role: userData['role'],
      token: userData['token'],
      hasPin: userData['role'] ==
          'customer', // Customers have PIN set during registration
    );
  }

  @override
  Future<void> sendLoginOtp(String phone) async {
    return remoteDataSource.sendLoginOtp(phone);
  }

  @override
  Future<User> verifyLoginOtp(String phone, String otp) async {
    final userData = await remoteDataSource.verifyLoginOtp(phone, otp);
    return User(
      id: userData['_id'],
      name: userData['name'],
      phone: userData['phone'],
      role: userData['role'],
      token: userData['token'],
      hasPin: userData['role'] ==
          'customer', // Assume customer has PIN if registered
    );
  }
}
