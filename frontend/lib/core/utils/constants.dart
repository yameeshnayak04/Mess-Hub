class ApiConstants {
  static const String baseUrl =
      'http://your-backend-url:5000'; // Change to your backend URL
  static const String apiPrefix = '/api';

  // Timeout
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String userData = 'user_data';
}

class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String profile = '/profile';
  static const String messDetails = '/mess-details/:id';
  static const String membershipDashboard = '/membership-dashboard/:id';
  static const String attendanceCalendar = '/attendance-calendar/:id';
  static const String applyLeave = '/apply-leave/:id';
  static const String billing = '/billing/:id';

  // Manager routes
  static const String managerHome = '/manager-home';
  static const String managerMembers = '/manager-members';
  static const String managerPayments = '/manager-payments';
  static const String managerKiosk = '/manager-kiosk';
  static const String kioskMode = '/kiosk-mode';
  static const String managerMenu = '/manager-menu';
  static const String createMessWizard = '/create-mess-wizard';
  static const String memberDetails = '/manager-member-details/:id';
}

class LottieAssets {
  static const String loading = 'assets/lottie/loading.json';
  static const String success = 'assets/lottie/success.json';
  static const String error = 'assets/lottie/error.json';
  static const String empty = 'assets/lottie/empty.json';
}
