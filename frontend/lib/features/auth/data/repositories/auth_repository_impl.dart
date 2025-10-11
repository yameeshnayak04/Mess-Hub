// This file implements the AuthRepository contract defined in the domain layer.

import 'package:mess_management_system/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mess_management_system/features/auth/domain/entities/user.dart';
import 'package:mess_management_system/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  // We depend on the remote data source to make the actual API calls.
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> sendRegistrationOtp(
      String name, String phone, String role) async {
    // Simply call the corresponding method in the data source.
    // Error handling is done inside the data source.
    return remoteDataSource.sendRegistrationOtp(name, phone, role);
  }

  @override
  Future<User> verifyRegistrationOtp(String phone, String otp) async {
    // Get the raw data (Map) from the data source.
    final userData = await remoteDataSource.verifyRegistrationOtp(phone, otp);
    // Convert the raw Map into a pure User entity.
    // Here we need a way to convert the Map to a User. Let's assume a model class.
    // This is a placeholder for the actual conversion logic.
    return User(
      id: userData['_id'],
      name: userData['name'],
      phone: userData['phone'],
      role: userData['role'],
      token: userData['token'],
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
    );
  }
}
