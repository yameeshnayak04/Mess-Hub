// This file centralizes all navigation logic for the application.

import 'package:flutter/material.dart';
import 'package:mess_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:mess_management_system/features/auth/presentation/screens/otp_screen.dart';
import 'package:mess_management_system/features/auth/presentation/screens/register_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/billing_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/leave_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/my_memberships_screen.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/screens/mess_detail_screen.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/screens/mess_list_screen.dart';

class AppRouter {
  AppRouter._(); // Private constructor

  // --- ROUTE NAMES ---
  static const String registerRoute = '/register';
  static const String loginRoute = '/login';
  static const String otpRoute = '/otp';
  static const String customerHomeRoute = '/customer-home';
  static const String messListRoute = '/mess-list'; // For discovery
  // -- NEW ROUTES --
  static const String leaveRoute = '/leave';
  static const String billingRoute = '/billing';
  static const String messDetailRoute = '/mess-detail'; // <-- ADD THIS
  // ----------------

  // --- ROUTE GENERATOR ---
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case otpRoute:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => OtpScreen(
              phone: args['phone'],
              isRegistration: args['isRegistration'],
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case customerHomeRoute:
        return MaterialPageRoute(builder: (_) => const MyMembershipsScreen());

      case messListRoute:
        return MaterialPageRoute(builder: (_) => const MessListScreen());

      // -- NEW ROUTE HANDLERS --
      case leaveRoute:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
              builder: (_) => LeaveScreen(membershipId: args['membershipId']));
        }
        return _errorRoute(); // Go to error if no ID is passed

      case billingRoute:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
              builder: (_) =>
                  BillingScreen(membershipId: args['membershipId']));
        }
        return _errorRoute();
      // ------------------------
      case messDetailRoute:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
              builder: (_) => MessDetailScreen(messId: args['messId']));
        }
        return _errorRoute(settings.name);
      default:
        return _errorRoute(settings.name);
    }
  }

  // A private helper for showing a generic error screen.
  static Route<dynamic> _errorRoute([String? routeName]) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(
              'Error: No route defined for ${routeName ?? 'the given route'}'),
        ),
      ),
    );
  }
}
