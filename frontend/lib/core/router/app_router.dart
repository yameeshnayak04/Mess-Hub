import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/customer/customer_shell.dart';
import '../../features/customer/home/screens/customer_home_screen.dart';
import '../../features/customer/discover/screens/discover_screen.dart';
import '../../features/customer/profile/screens/profile_screen.dart';
import '../../features/customer/mess_details/screens/mess_details_screen.dart';
import '../../features/customer/membership/screens/membership_dashboard_screen.dart';
import '../../features/customer/membership/screens/attendance_calendar_screen.dart';
import '../../features/customer/membership/screens/apply_leave_screen.dart';
import '../../features/customer/membership/screens/billing_screen.dart';
import '../../features/manager/manager_shell.dart';
import '../../features/manager/home/screens/manager_home_screen.dart';
import '../../features/manager/members/screens/members_screen.dart';
import '../../features/manager/members/screens/member_details_screen.dart';
import '../../features/manager/payments/screens/payments_screen.dart';
import '../../features/manager/kiosk/screens/kiosk_launcher_screen.dart';
import '../../features/manager/kiosk/screens/kiosk_mode_screen.dart';
import '../../features/manager/menu/screens/menu_editor_screen.dart';
import '../../features/manager/create_mess/screens/create_mess_wizard_screen.dart';
import '../../core/utils/constants.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.value;

      final isOnSplash = state.matchedLocation == RouteNames.splash;
      final isOnLogin = state.matchedLocation == RouteNames.login;
      final isOnRegister = state.matchedLocation == RouteNames.register;

      // While loading, stay on splash
      if (isLoading && !isOnSplash) {
        return RouteNames.splash;
      }

      // If not logged in and not on auth pages, go to login
      if (user == null && !isOnLogin && !isOnRegister && !isOnSplash) {
        return RouteNames.login;
      }

      // If logged in and on auth pages, redirect based on role
      if (user != null && (isOnLogin || isOnRegister || isOnSplash)) {
        if (user.role == 'Customer') {
          return RouteNames.home;
        } else if (user.role == 'Manager') {
          return RouteNames.managerHome;
        }
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer routes with shell
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const CustomerHomeScreen(),
          ),
          GoRoute(
            path: RouteNames.discover,
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Customer sub-routes (without shell)
      GoRoute(
        path: '/mess-details/:id',
        builder: (context, state) {
          final messId = state.pathParameters['id']!;
          return MessDetailsScreen(messId: messId);
        },
      ),
      GoRoute(
        path: '/membership-dashboard/:id',
        builder: (context, state) {
          final membershipId = state.pathParameters['id']!;
          return MembershipDashboardScreen(membershipId: membershipId);
        },
      ),
      GoRoute(
        path: '/attendance-calendar/:id',
        builder: (context, state) {
          final membershipId = state.pathParameters['id']!;
          return AttendanceCalendarScreen(membershipId: membershipId);
        },
      ),
      GoRoute(
        path: '/apply-leave/:id',
        builder: (context, state) {
          final membershipId = state.pathParameters['id']!;
          return ApplyLeaveScreen(membershipId: membershipId);
        },
      ),
      GoRoute(
        path: '/billing/:id',
        builder: (context, state) {
          final membershipId = state.pathParameters['id']!;
          return BillingScreen(membershipId: membershipId);
        },
      ),

      // Manager routes with shell
      ShellRoute(
        builder: (context, state, child) => ManagerShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.managerHome,
            builder: (context, state) => const ManagerHomeScreen(),
          ),
          GoRoute(
            path: RouteNames.managerMembers,
            builder: (context, state) => const MembersScreen(),
          ),
          GoRoute(
            path: RouteNames.managerPayments,
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: RouteNames.managerKiosk,
            builder: (context, state) => const KioskLauncherScreen(),
          ),
        ],
      ),

      // Manager sub-routes (without shell)
      GoRoute(
        path: RouteNames.kioskMode,
        builder: (context, state) => const KioskModeScreen(),
      ),
      GoRoute(
        path: RouteNames.managerMenu,
        builder: (context, state) => const MenuEditorScreen(),
      ),
      GoRoute(
        path: RouteNames.createMessWizard,
        builder: (context, state) => const CreateMessWizardScreen(),
      ),
      GoRoute(
        path: '/manager-member-details/:id',
        builder: (context, state) {
          final memberId = state.pathParameters['id']!;
          return MemberDetailsScreen(memberId: memberId);
        },
      ),
    ],
  );
});
