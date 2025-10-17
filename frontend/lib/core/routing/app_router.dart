// lib/core/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:mess_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:mess_management_system/features/auth/presentation/screens/otp_screen.dart';
import 'package:mess_management_system/features/auth/presentation/screens/register_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/billing_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/leave_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/membership_detail_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/membership_detail_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/my_memberships_screen.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/screens/mess_detail_screen.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/screens/mess_list_screen.dart';

class AppRouter {
  AppRouter._(); // Private constructor

  // --- ROUTE NAMES ---
  // A centralized place for all route names to prevent typos.
  static const String registerRoute = '/register';
  static const String loginRoute = '/login';
  static const String otpRoute = '/otp';

  static const String customerHomeRoute = '/customer-home';
  static const String membershipDetailRoute = '/membership-detail';
  static const String leaveRoute = '/leave';
  static const String billingRoute = '/billing';

  static const String messListRoute = '/mess-list';
  static const String messDetailRoute = '/mess-detail';

  // --- ROUTE GENERATOR ---
  // This function is the single source of truth for all navigation in the app.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case otpRoute:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => OtpScreen(
                phone: args['phone'], isRegistration: args['isRegistration']),
          );
        }
        return _errorRoute(settings.name);

      // Customer Dashboard Routes
      case customerHomeRoute:
        return MaterialPageRoute(builder: (_) => const MyMembershipsScreen());

      case membershipDetailRoute:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
              builder: (_) =>
                  MembershipDetailScreen(membership: args['membership']));
        }
        return _errorRoute(settings.name);

      case leaveRoute:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
              builder: (_) => LeaveScreen(membershipId: args['membershipId']));
        }
        return _errorRoute(settings.name);

      case billingRoute:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
              builder: (_) =>
                  BillingScreen(membershipId: args['membershipId']));
        }
        return _errorRoute(settings.name);

      // Mess Discovery Routes
      case messListRoute:
        return MaterialPageRoute(builder: (_) => const MessListScreen());

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

  // A private helper for showing a generic error screen if a route is not found.
  static Route<dynamic> _errorRoute([String? routeName]) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(
              'Error: No route defined for ${routeName ?? 'the given route'}'),
        ),
      ),
    );
  }
}
