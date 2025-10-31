// lib/core/navigation/app_router.dart
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

final appRouterProvider = Provider((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoading = authState.isLoading && !authState.hasValue;

      final loc = state.matchedLocation;
      final onSplash = loc == RouteNames.splash;
      final onLogin = loc == RouteNames.login;
      final onRegister = loc == RouteNames.register;
      final onAuth = onLogin || onRegister;
      final onCreateMess = loc == RouteNames.createMessWizard;

      // 1) Initial boot: stay on splash until auth resolves
      if (isLoading) return onSplash ? null : RouteNames.splash;

      // 2) Not authenticated: send to login unless already on auth
      if (user == null) return onAuth ? null : RouteNames.login;

      // 3) Authenticated manager: ensure mess exists
      if (user.role == 'Manager') {
        if (user.hasMess != true) {
          return onCreateMess ? null : RouteNames.createMessWizard;
        }
        // If coming from splash/auth/create, push to manager home
        if (onSplash || onAuth || onCreateMess) return RouteNames.managerHome;
        return null;
      }

      // 4) Authenticated customer: if coming from splash/auth, push to home
      if (user.role == 'Customer') {
        if (onSplash || onAuth) return RouteNames.home;
        return null;
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(
          path: RouteNames.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: RouteNames.register,
          builder: (_, __) => const RegisterScreen()),

      // Customer tabs
      ShellRoute(
        builder: (_, __, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
              path: RouteNames.home,
              builder: (_, __) => const CustomerHomeScreen()),
          GoRoute(
              path: RouteNames.discover,
              builder: (_, __) => const DiscoverScreen()),
          GoRoute(
              path: RouteNames.profile,
              builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Customer subpages (outside shell)
      GoRoute(
        path: '/mess-details/:id',
        builder: (_, state) =>
            MessDetailsScreen(messId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/membership-dashboard/:id',
        builder: (_, state) => MembershipDashboardScreen(
            membershipId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/attendance-calendar/:id',
        builder: (_, state) =>
            AttendanceCalendarScreen(membershipId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/apply-leave/:id',
        builder: (_, state) =>
            ApplyLeaveScreen(membershipId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/billing/:id',
        builder: (_, state) =>
            BillingScreen(membershipId: state.pathParameters['id']!),
      ),

      // Manager tabs
      ShellRoute(
        builder: (_, __, child) => ManagerShell(child: child),
        routes: [
          GoRoute(
              path: RouteNames.managerHome,
              builder: (_, __) => const ManagerHomeScreen()),
          GoRoute(
              path: RouteNames.managerMembers,
              builder: (_, __) => const MembersScreen()),
          GoRoute(
              path: RouteNames.managerPayments,
              builder: (_, __) => const PaymentsScreen()),
          GoRoute(
              path: RouteNames.kioskLauncher,
              builder: (_, __) => const KioskLauncherScreen()),
        ],
      ),

      // Manager subpages (outside shell)
      GoRoute(
          path: RouteNames.kioskMode,
          builder: (_, __) => const KioskModeScreen()),
      GoRoute(
          path: RouteNames.managerMenu,
          builder: (_, __) => const MenuEditorScreen()),
      GoRoute(
          path: RouteNames.createMessWizard,
          builder: (_, __) => const CreateMessWizardScreen()),
      GoRoute(
        path: '/manager/member/:membershipId',
        builder: (_, state) => MemberDetailsScreen(
          membershipId: state.pathParameters['membershipId']!,
          membership: state.extra as Map<String, dynamic>?,
        ),
      ),
    ],
  );
});
