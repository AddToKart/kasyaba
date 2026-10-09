import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/session_events.dart';
import '../storage/secure_storage_service.dart';
import '../connectivity/connectivity_service.dart';

// API configuration. Release builds must provide the production URL via
// `--dart-define=API_BASE_URL=https://...`; `main()` refuses to start without
// it so a misconfigured build can never silently point at localhost.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kReleaseMode ? '' : 'http://10.0.2.2:3000',
);

final dioProvider = Provider<Dio>((ref) {
  final sessionEvents = ref.watch(sessionExpiredProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: '$kApiBaseUrl/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add connectivity check interceptor (must be first to fail-fast)
  dio.interceptors.add(ConnectivityInterceptor(ref));

  // Add auth interceptor
  dio.interceptors.add(
    AuthInterceptor(ref, dio, () {
      if (!sessionEvents.isClosed) sessionEvents.add(null);
    }),
  );

  // Add logging interceptor in debug
  if (const bool.fromEnvironment('DEBUG_API', defaultValue: false)) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
});

class AuthInterceptor extends Interceptor {
  final Ref _ref;
  final Dio _dio;
  final void Function() _onSessionExpired;
  Future<void>? _refreshFuture;

  AuthInterceptor(this._ref, this._dio, this._onSessionExpired);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          message: 'Unable to read authentication credentials.',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra['_authRetry'] == true ||
        options.extra['_authRefresh'] == true ||
        options.path == '/auth/refresh') {
      return handler.next(err);
    }

    final refreshFuture = _refreshFuture ??= _refreshToken();
    try {
      await refreshFuture;
      options.extra['_authRetry'] = true;
      return handler.resolve(await _dio.fetch(options));
    } catch (_) {
      return handler.next(err);
    } finally {
      if (identical(_refreshFuture, refreshFuture)) {
        _refreshFuture = null;
      }
    }
  }

  Future<void> _refreshToken() async {
    final storage = _ref.read(secureStorageProvider);
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token');

    try {
      // Use the same base options without this interceptor so a failed refresh
      // cannot start another refresh cycle.
      final response = await Dio(_dio.options).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'_authRefresh': true}),
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['data']['accessToken'] as String;
        final newRefreshToken = response.data['data']['refreshToken'] as String;
        await storage.saveTokens(newAccessToken, newRefreshToken);
        return;
      }
      throw Exception('Refresh failed');
    } catch (_) {
      try {
        await storage.clearTokens();
      } catch (_) {
        // Preserve the refresh failure; a storage failure must not mask it.
      }
      // Tell the auth layer to drop the local session so the UI cannot stay
      // "signed in" with credentials the server no longer accepts.
      _onSessionExpired();
      rethrow;
    }
  }
}

/// Interceptor that checks connectivity before making API requests.
/// If the device is offline, the request is rejected immediately with a
/// user-friendly error instead of waiting for a timeout.
class ConnectivityInterceptor extends Interceptor {
  final Ref _ref;

  ConnectivityInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isOnline = _ref.read(isOnlineProvider);
    if (!isOnline) {
      return handler.reject(
        DioException(
          requestOptions: options,
          message:
              'No internet connection. Please check your network settings and try again.',
          type: DioExceptionType.connectionError,
        ),
      );
    }
    handler.next(options);
  }
}
