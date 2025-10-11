// This file centralizes all navigation logic for the application.

import 'package:flutter/material.dart';
import 'package:mess_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:mess_management_system/features/auth/presentation/screens/otp_screen.dart';
import 'package:mess_management_system/features/auth/presentation/screens/register_screen.dart';

// We will create these screens in the next steps.
// For now, let's create placeholders so the code doesn't have errors.
// TODO: Replace these placeholders with the actual screen widgets.

class AppRouter {
  AppRouter._(); // Private constructor

  // --- ROUTE NAMES ---
  // Define static constant names for your routes. This prevents typos.
  static const String registerRoute = '/register';
  static const String loginRoute = '/login';
  static const String otpRoute = '/otp';
  static const String homeRoute = '/home';

  // --- ROUTE GENERATOR ---
  // This function is called whenever a new named route is pushed.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case otpRoute:
        // The OTP screen will need arguments like the phone number.
        // We'll pass them through the 'settings.arguments'.
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => OtpScreen(
                  phone: args['phone'],
                  isRegistration: args['isRegistration'],
                ));
      // case homeRoute:
      //   return MaterialPageRoute(builder: (_) => const HomeScreen());

      default:
        // If the route name is not found, show a simple error screen.
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
