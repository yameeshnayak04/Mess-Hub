// lib/core/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:mess_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:mess_management_system/features/auth/presentation/screens/otp_screen.dart';
import 'package:mess_management_system/features/auth/presentation/screens/register_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/customer_dashboard_shell.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/attendance_calendar_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/leave_application_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/billing_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/mess_rating_screen.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/screens/mess_detail_screen.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/screens/mess_list_screen.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/screens/manager_dashboard_shell.dart';
import 'package:mess_management_system/features/mess_onboarding/presentation/screens/create_mess_screen.dart';

class AppRouter {
  AppRouter._(); // Private constructor

  // --- ROUTE NAMES ---
  // Authentication Routes
  static const String splashRoute = '/';
  static const String registerRoute = '/register';
  static const String loginRoute = '/login';
  static const String otpRoute = '/otp';

  // Customer Dashboard Routes
  static const String customerDashboardRoute = '/customer-dashboard';
  static const String attendanceRoute = '/attendance';
  static const String leaveApplicationRoute = '/leave-application';
  static const String billingRoute = '/billing';
  static const String messRatingRoute = '/mess-rating';

  // Manager Dashboard Routes
  static const String managerDashboardRoute = '/manager-dashboard';
  static const String createMessRoute = '/create-mess';

  // Kiosk Routes
  static const String kioskSetupRoute = '/kiosk-setup';

  // Mess Discovery Routes
  static const String messListRoute = '/mess-list';
  static const String messDetailRoute = '/mess-detail';

  // --- ROUTE GENERATOR ---
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ==================== AUTH ROUTES ====================
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
        return _errorRoute(settings.name);

      // ==================== CUSTOMER DASHBOARD ROUTES ====================

      case customerDashboardRoute:
        return MaterialPageRoute(builder: (_) => CustomerDashboardShell());

      case attendanceRoute:
        if (settings.arguments is Membership) {
          final membership = settings.arguments as Membership;
          return MaterialPageRoute(
            builder: (_) => AttendanceCalendarScreen(membership: membership),
          );
        }
        return _errorRoute(settings.name);

      case leaveApplicationRoute:
        if (settings.arguments is Membership) {
          final membership = settings.arguments as Membership;
          return MaterialPageRoute(
            builder: (_) => LeaveApplicationScreen(membership: membership),
          );
        }
        return _errorRoute(settings.name);

      case billingRoute:
        if (settings.arguments is Membership) {
          final membership = settings.arguments as Membership;
          return MaterialPageRoute(
            builder: (_) => BillingScreen(membership: membership),
          );
        }
        return _errorRoute(settings.name);

      case messRatingRoute:
        if (settings.arguments is Membership) {
          final membership = settings.arguments as Membership;
          return MaterialPageRoute(
            builder: (_) => MessRatingScreen(membership: membership),
          );
        }
        return _errorRoute(settings.name);

      // ==================== MANAGER DASHBOARD ROUTES ====================
      case managerDashboardRoute:
        return MaterialPageRoute(
          builder: (_) => const ManagerDashboardShell(),
        );

      case createMessRoute:
        return MaterialPageRoute(
          builder: (_) => const CreateMessScreen(),
        );

      // ==================== KIOSK ROUTES ====================
      // ==================== MESS DISCOVERY ROUTES ====================
      case messListRoute:
        return MaterialPageRoute(builder: (_) => const MessListScreen());

      case messDetailRoute:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => MessDetailScreen(messId: args['messId']),
          );
        }
        return _errorRoute(settings.name);

      // ==================== DEFAULT ROUTE ====================
      default:
        return _errorRoute(settings.name);
    }
  }

  // Error route for undefined routes
  static Route<dynamic> _errorRoute([String? routeName]) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Route Not Found',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No route defined for ${routeName ?? 'the given route'}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate back or to home
                },
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
