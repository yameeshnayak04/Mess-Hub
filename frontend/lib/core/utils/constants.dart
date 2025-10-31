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

// lib/core/utils/constants.dart (excerpt)
class RouteNames {
  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';

  // Customer tabs
  static const String home = '/';
  static const String discover = '/discover';
  static const String profile = '/profile';

  // Customer subroutes
  static const String messDetails = '/mess-details/:id';
  static const String membershipDashboard = '/membership-dashboard/:id';
  static const String attendanceCalendar = '/attendance-calendar/:id';
  static const String applyLeave = '/apply-leave/:id';
  static const String billing = '/billing/:id';

  // Manager tabs
  static const String managerHome = '/manager';
  static const String managerMembers = '/manager/members';
  static const String managerPayments = '/manager/payments';
  // Back-compat alias to fix "managerBillingApprovals" not defined
  static const String managerBillingApprovals = managerPayments;

  static const String kioskLauncher = '/manager/kiosk';
  static const String kioskMode = '/manager/kiosk/mode';
  static const String managerMenu = '/manager/menu-editor';
  static const String createMessWizard = '/manager/create-mess';

  // Helper
  static String managerMemberDetails(String membershipId) =>
      '/manager/member/$membershipId';
}
