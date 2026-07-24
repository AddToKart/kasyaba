import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';

// API configuration
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: '$kApiBaseUrl/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Add auth interceptor
  dio.interceptors.add(AuthInterceptor(ref));

  // Add logging interceptor in debug
  if (const bool.fromEnvironment('DEBUG_API', defaultValue: false)) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  return dio;
});

class AuthInterceptor extends Interceptor {
  final Ref _ref;
  bool _isRefreshing = false;
  final _pendingRequests = <({RequestOptions options, ErrorInterceptorHandler handler})>[];

  AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      // Queue this request to retry after refresh completes
      _pendingRequests.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;
    try {
      await _refreshToken();
      // Retry all queued requests including the current one
      _retryPendingRequests();
      final storage = _ref.read(secureStorageProvider);
      final newToken = await storage.getAccessToken();
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await Dio().fetch(err.requestOptions);
        return handler.resolve(response);
      }
    } catch (_) {
      _pendingRequests.clear();
      final storage = _ref.read(secureStorageProvider);
      await storage.clearTokens();
    } finally {
      _isRefreshing = false;
    }

    handler.next(err);
  }

  Future<void> _refreshToken() async {
    final storage = _ref.read(secureStorageProvider);
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token');

    final dio = _ref.read(dioProvider);
    final response = await dio.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });

    if (response.statusCode == 200) {
      final newAccessToken = response.data['data']['accessToken'] as String;
      final newRefreshToken = response.data['data']['refreshToken'] as String;
      await storage.saveTokens(newAccessToken, newRefreshToken);
    } else {
      throw Exception('Refresh failed');
    }
  }

  void _retryPendingRequests() async {
    final pending = List.from(_pendingRequests);
    _pendingRequests.clear();
    final storage = _ref.read(secureStorageProvider);
    final newToken = await storage.getAccessToken();

    for (final req in pending) {
      if (newToken != null) {
        req.options.headers['Authorization'] = 'Bearer $newToken';
      }
      try {
        final response = await Dio().fetch(req.options);
        req.handler.resolve(response);
      } catch (e) {
        req.handler.reject(DioException(requestOptions: req.options, error: e));
      }
    }
  }
}
