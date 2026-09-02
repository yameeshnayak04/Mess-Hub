import 'package:dio/dio.dart';
import '../utils/constants.dart';
import 'api_exception.dart';

/// Thin wrapper over Dio that also understands the backend's response
/// envelope, so repositories deal in plain data instead of unwrapping
/// `{ success, data, meta }` by hand at every call site.
class DioClient {
  final Dio _dio;

  DioClient(this._dio) {
    _dio
      ..options.baseUrl = ApiConstants.baseUrl + ApiConstants.apiPrefix
      ..options.connectTimeout = ApiConstants.connectionTimeout
      ..options.receiveTimeout = ApiConstants.receiveTimeout
      ..options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    // Never throw on a non-2xx: the body still carries `code` and `message`,
    // which is what we actually want to report. unwrap() decides what is an
    // error, based on the envelope rather than the status line.
    _dio.options.validateStatus =
        (code) => code != null && code >= 200 && code < 600;
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Images now come back as absolute Cloudinary URLs, so this is only a
  /// safety net for anything still stored as a relative path.
  String resolveServerUrl(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${ApiConstants.baseUrl}$path';
  }

  // ---------------------------------------------------------------- envelope

  /// Returns the `data` field of a successful response, or throws an
  /// [ApiException] carrying the backend's `code` and `message`.
  static dynamic unwrap(Response response) {
    final body = response.data;

    if (body is Map && body['success'] == true) {
      return body['data'];
    }

    if (body is Map && body['success'] == false) {
      throw ApiException(
        code: (body['code'] as String?) ?? 'INTERNAL_ERROR',
        message: (body['message'] as String?) ?? '',
        statusCode: response.statusCode,
      );
    }

    // Anything that is not the documented envelope (a proxy error page, an
    // empty body) is treated as a server problem rather than silently parsed.
    throw ApiException(
      code: 'INTERNAL_ERROR',
      message: 'Unexpected response from the server.',
      statusCode: response.statusCode,
    );
  }

  /// Same as [unwrap] but also hands back `meta`, which list endpoints use for
  /// pagination (`page`, `limit`, `total`, `totalPages`, `hasNextPage`).
  static ({dynamic data, Map<String, dynamic>? meta}) unwrapWithMeta(
    Response response,
  ) {
    final data = unwrap(response);
    final body = response.data;
    final meta = (body is Map && body['meta'] is Map)
        ? Map<String, dynamic>.from(body['meta'] as Map)
        : null;
    return (data: data, meta: meta);
  }

  /// Turns Dio's transport-level failures (no connection, timeout) into the
  /// same ApiException type, so callers only ever catch one thing.
  static ApiException asApiException(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map && body['code'] is String) {
        return ApiException(
          code: body['code'] as String,
          message: (body['message'] as String?) ?? '',
          statusCode: error.response?.statusCode,
        );
      }
      return ApiException(
        code: 'NETWORK',
        message: '',
        statusCode: error.response?.statusCode,
      );
    }
    return ApiException(code: 'INTERNAL_ERROR', message: error.toString());
  }

  // ---------------------------------------------------------------- verbs

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get(path, queryParameters: queryParameters, options: options);

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post(path,
          data: data, queryParameters: queryParameters, options: options);

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.put(path,
          data: data, queryParameters: queryParameters, options: options);

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.patch(path,
          data: data, queryParameters: queryParameters, options: options);

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.delete(path,
          data: data, queryParameters: queryParameters, options: options);
}
