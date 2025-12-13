// Dio is the HTTP client used in this project; we extend its Interceptor.
import 'package:dio/dio.dart';

// Local service that provides secure storage read/write methods.
import '../services/storage_service.dart';

// Constants used across the app (e.g. storage keys).
import '../utils/constants.dart';

// An interceptor that automatically attaches the saved access token
// to outgoing requests and triggers a callback when a 401 Unauthorized
// response is received.
class AuthInterceptor extends Interceptor {
  // Reference to a storage service used to read the access token.
  final StorageService storageService;

  // Callback invoked when the server responds with 401 Unauthorized.
  // The caller can use this (for example) to navigate to the login screen
  // or refresh tokens.
  final void Function() onUnauthorized;

  // Constructor requires the storage service and the unauthorized callback.
  AuthInterceptor({
    required this.storageService,
    required this.onUnauthorized,
  });

  // onRequest is called by Dio before a request is sent.
  // We override it to inject the Authorization header when a token exists.
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Read the access token from secure storage using our StorageService.
    // This is asynchronous because secure storage APIs are typically async.
    final token = await storageService.read(StorageKeys.accessToken);

    // If a token was found, attach it to the Authorization header
    // using the Bearer scheme expected by the backend.
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Continue the request chain. Calling super ensures any other
    // interceptors or Dio's default behavior still run.
    super.onRequest(options, handler);
  }

  // onError is called when a request fails. We use it to detect
  // authentication errors (401) and notify the app via `onUnauthorized`.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Check the response status code safely (response may be null).
    if (err.response?.statusCode == 401) {
      // When unauthorized, call the provided callback so the app
      // can handle it (e.g. clear state, redirect to login).
      onUnauthorized();
    }

    // Continue the error chain so callers can still handle the error.
    super.onError(err, handler);
  }
}
