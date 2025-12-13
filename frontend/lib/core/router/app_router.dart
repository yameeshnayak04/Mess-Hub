// lib/core/navigation/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_app/features/customer/membership/screens/review_editor_screen.dart';

// Manager profile
import 'package:mess_management_app/features/manager/profile/screens/mess_profile_screen.dart';

// Auth
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';

// Customer
import '../../features/customer/customer_shell.dart';
import '../../features/customer/home/screens/customer_home_screen.dart';
import '../../features/customer/discover/screens/discover_screen.dart';
import '../../features/customer/profile/screens/profile_screen.dart';
import '../../features/customer/mess_details/screens/mess_details_screen.dart';
import '../../features/customer/membership/screens/membership_dashboard_screen.dart';
import '../../features/customer/membership/screens/attendance_calendar_screen.dart';
import '../../features/customer/membership/screens/apply_leave_screen.dart';
import '../../features/customer/membership/screens/billing_screen.dart';

// Manager
import '../../features/manager/manager_shell.dart';
import '../../features/manager/home/screens/manager_home_screen.dart';
import '../../features/manager/members/screens/members_screen.dart';
import '../../features/manager/members/screens/member_details_screen.dart';
import '../../features/manager/payments/screens/payments_screen.dart';
import '../../features/manager/kiosk/screens/kiosk_launcher_screen.dart';
import '../../features/manager/kiosk/screens/kiosk_mode_screen.dart';
import '../../features/manager/menu/screens/menu_editor_screen.dart';
import '../../features/manager/create_mess/screens/create_mess_wizard_screen.dart';

// Routes
import '../../core/utils/constants.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // This makes the router accessible anywhere in the app via Riverpod
  // Declares a global configuration object (appRouterProvider) that supplies the application's entire routing logic.

  final authState = ref.watch(authProvider);
  // authProvider: A Riverpod StateProvider (likely) holding the user's authentication status (User object, loading state, error state).
  // Crucial for implementing "guarded routes"—restricting access to certain pages based on whether a user is logged in or not.

  return GoRouter(
    // Provides the instantiated GoRouter object back to the appRouterProvider.
    // GoRouter: The main configuration object for the go_router package.
    // This defines the structure and rules of all application navigation.

    initialLocation: RouteNames
        .splash, // Sets the initial URL path the app loads when it first starts.
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Redirect function: A function go_router runs before navigating to a destination.
      // Checks conditions (like login status, user role) and decides if the user should stay on their intended path (return null) or be sent to a different path (return '/login').
      // Prevents unauthorized access to screens and manages complex role-based navigation flows seamlessly.

      final user = authState.valueOrNull;
      final isLoading = authState.isLoading && !authState.hasValue;

      // Use matchedLocation for compatibility across go_router versions
      final loc = state.matchedLocation;

      // Auth route checks
      final onSplash = loc == RouteNames.splash;
      final onLogin = loc == RouteNames.login;
      final onRegister = loc == RouteNames.register;
      final onAuth = onLogin || onRegister;

      // Manager create-mess gating
      final onCreateMess = loc == RouteNames.createMessWizard;

      // 1) Initial boot: keep on splash while auth resolves
      if (isLoading) return onSplash ? null : RouteNames.splash;

      // 2) Not authenticated: allow only login/register
      if (user == null) {
        return onAuth ? null : RouteNames.login;
      }

      // 3) Authenticated Manager flow with create-mess gating
      if (user.role == 'Manager') {
        if (user.hasMess != true) {
          return onCreateMess ? null : RouteNames.createMessWizard;
        }
        if (onSplash || onAuth || onCreateMess) return RouteNames.managerHome;
        return null;
      }

      // 4) Authenticated Customer: from splash/auth go to home
      if (user.role == 'Customer') {
        if (onSplash || onAuth) return RouteNames.home;
        return null;
      }

      return null;
    },
    routes: [
      // Defines all possible screens and paths the application can navigate to.
      // Auth
      GoRoute(
          path: RouteNames.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: RouteNames.register,
          builder: (_, __) => const RegisterScreen()),

      // Customer tabs
      // ShellRoute: A go_router feature for persistent UI elements (like a navigation bar/scaffold).
      // Wraps a group of nested routes (home, discover, profile) within a common parent widget
      // Ensures the bottom navigation bar remains visible and doesn't rebuild when switching between the main customer tabs.
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
      GoRoute(
        path: '/review-editor/:messId',
        builder: (context, state) => ReviewEditorScreen(
          messId: state.pathParameters['messId']!,
        ),
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
          GoRoute(
              path: RouteNames.managerProfile,
              builder: (_, __) => const MessProfileScreen()),
        ],
      ),

      // Manager subpages (outside shell)
      GoRoute(
          path: RouteNames.kioskMode,
          builder: (_, __) => const KioskModeScreen()),
      GoRoute(
        name: RouteNames.managerMenu,
        path: RouteNames.managerMenu,
        builder: (_, __) => const MenuEditorScreen(),
      ),
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
