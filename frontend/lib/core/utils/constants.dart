class ApiConstants {
  static const String baseUrl =
      'http://10.121.118.41:3000'; // Change to your backend URL
  static const String apiPrefix = '/api';

  // Timeout
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      // Return a placeholder or handle error as needed
      // For now, returning empty string for Image.network to handle errorBuilder
      return '';
    }
    if (path.startsWith('http')) {
      return path; // Already a full URL
    }
    // Prepend base URL (ensure no double slash if path starts with /)
    final separator =
        (baseUrl.endsWith('/') || path.startsWith('/')) ? '' : '/';
    return baseUrl +
        separator +
        path.replaceAll(r'\', '/'); // Handle potential backslashes
  }
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
