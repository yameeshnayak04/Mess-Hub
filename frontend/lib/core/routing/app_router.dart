// This file centralizes all navigation logic for the application.

import 'package:flutter/material.dart';
import 'package:mess_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:mess_management_system/features/auth/presentation/screens/otp_screen.dart';
import 'package:mess_management_system/features/auth/presentation/screens/register_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/my_memberships_screen.dart';

class AppRouter {
  AppRouter._(); // Private constructor

  // --- ROUTE NAMES ---
  static const String registerRoute = '/register';
  static const String loginRoute = '/login';
  static const String otpRoute = '/otp';
  static const String customerHomeRoute = '/customer-home';

  // --- ROUTE GENERATOR ---
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // --- THIS IS THE CRITICAL FIX ---
      case otpRoute:
        // First, check if the arguments are not null AND are of the correct type.
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => OtpScreen(
              phone: args['phone'],
              isRegistration: args['isRegistration'],
            ),
          );
        }
        // If arguments are missing or wrong, redirect to a safe screen (like register).
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      // ------------------------------------

      case customerHomeRoute:
        return MaterialPageRoute(builder: (_) => const MyMembershipsScreen());

      default:
        // If the route name is not found, show a dedicated error screen.
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Error: No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
