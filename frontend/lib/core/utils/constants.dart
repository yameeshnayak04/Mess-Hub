class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mess-hub-backend.onrender.com',
  );
  static const String apiPrefix = '/api';
  static const Duration connectionTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  static String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      // Return a placeholder or handle error as needed
      // For now, returning empty string for Image.network to handle errorBuilder
      return '';
    }
    if (path.startsWith('http')) {
      return path; // Already a full URL (from Cloudinary)
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
  // User data can be stored as JSON string
  // Defines the exact string key used to save/read the user's access token in local storage.
  // Prevents typos when interacting with storage. Using a constant prevents errors like writing to 'access_token' but reading from 'acces_token'.
  static const String userData = 'user_data';
  // Defines the key for storing the complete user profile data locally.
  // Same benefits as the access token key; ensures consistency when serializing/deserializing user data.
}

// lib/core/utils/constants.dart (excerpt)
class RouteNames {
  // Auth
  static const String splash = '/splash';
  // Decouples navigation calls from raw strings. Instead of router.go('/login'), you use router.go(RouteNames.login).
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

  static const String kioskLauncher = '/manager/kiosk';
  static const String kioskMode = '/manager/kiosk/mode';
  static const String managerMenu = '/manager/menu-editor';
  static const String createMessWizard = '/manager/create-mess';
  static const managerProfile = '/manager/profile';
}
