import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../storage/secure_storage_service.dart';
import 'session_events.dart';

// Auth state
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? displayName;
  final bool hasPassword;
  final bool isInitializing;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.email,
    this.displayName,
    this.hasPassword = false,
    this.isInitializing = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? email,
    String? displayName,
    bool? hasPassword,
    bool? isInitializing,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      hasPassword: hasPassword ?? this.hasPassword,
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final SecureStorageService _storage;
  StreamSubscription<void>? _sessionExpiredSubscription;
  int _authOperation = 0;

  AuthNotifier(this._dio, this._storage, Stream<void> sessionExpired)
    : super(const AuthState(isInitializing: true)) {
    _sessionExpiredSubscription = sessionExpired.listen((_) {
      _handleSessionExpired();
    });
    unawaited(checkAuth());
  }

  @override
  void dispose() {
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  /// Forces a local sign-out when the refresh token is rejected so the UI
  /// cannot remain "signed in" with credentials the server no longer accepts.
  void _handleSessionExpired() {
    ++_authOperation;
    state = const AuthState();
    unawaited(_storage.clearTokens().catchError((_) {}));
  }

  String _extractDisplayName(
    Map<String, dynamic>? userJson,
    String fallbackEmail,
  ) {
    if (userJson != null) {
      final name = userJson['displayName'] as String?;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    if (fallbackEmail.isNotEmpty && fallbackEmail.contains('@')) {
      final prefix = fallbackEmail.split('@')[0];
      if (prefix.isNotEmpty) {
        return prefix[0].toUpperCase() + prefix.substring(1);
      }
    }
    return 'User';
  }

  Future<void> _restoreCachedUser(int operation) async {
    try {
      final cached = await _storage.getCachedUser();
      if (!mounted || operation != _authOperation || cached == null) return;
      final email = cached['email'] ?? '';
      state = AuthState(
        isAuthenticated: true,
        userId: cached['id'],
        email: email,
        displayName: cached['displayName'] ?? _extractDisplayName(null, email),
        isInitializing: false,
      );
    } catch (_) {
      // Offline restoration is best-effort; the next online check can recover.
    }
  }

  Future<void> checkAuth() async {
    final operation = ++_authOperation;
    try {
      final token = await _storage.getAccessToken();
      if (!mounted || operation != _authOperation) return;
      if (token != null) {
        final response = await _dio.get('/auth/me');
        if (!mounted || operation != _authOperation) return;
        final user = response.data['data'] as Map<String, dynamic>?;
        if (user != null) {
          final email = (user['email'] as String?) ?? '';
          state = AuthState(
            isAuthenticated: true,
            userId: user['id'] as String?,
            email: email,
            displayName: _extractDisplayName(user, email),
            hasPassword: (user['hasPassword'] as bool?) ?? false,
          );
          final userId = user['id'] as String?;
          if (userId != null) {
            unawaited(
              _storage
                  .saveUser(
                    userId: userId,
                    email: email,
                    displayName: _extractDisplayName(user, email),
                  )
                  .catchError((_) {}),
            );
          }
        } else {
          await _storage.clearTokens();
        }
      }
    } on DioException catch (error) {
      if (!mounted || operation != _authOperation) return;
      if (error.response?.statusCode == 401) {
        try {
          await _storage.clearTokens();
        } catch (_) {
          // Ignore cleanup failures after an invalid session.
        }
      } else {
        await _restoreCachedUser(operation);
      }
    } catch (_) {
      await _restoreCachedUser(operation);
    } finally {
      // Guarantee the startup gate is always released, even when the token is
      // missing, the network is down, and no cached user exists.
      if (mounted && operation == _authOperation && state.isInitializing) {
        state = state.copyWith(isInitializing: false);
      }
    }
  }

  Future<void> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    final operation = ++_authOperation;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
      final data = response.data['data'];
      final user = data['user'] as Map<String, dynamic>?;
      final resolvedEmail = (user?['email'] as String?) ?? email;
      await _storage.saveTokens(
        data['accessToken'],
        data['refreshToken'],
        userId: user?['id'] as String?,
        email: resolvedEmail,
        displayName: _extractDisplayName(user, resolvedEmail),
      );
      if (!mounted || operation != _authOperation) return;
      state = AuthState(
        isAuthenticated: true,
        userId: user?['id'] as String?,
        email: resolvedEmail,
        displayName: _extractDisplayName(user, resolvedEmail),
        hasPassword: (user?['hasPassword'] as bool?) ?? true,
      );
    } on DioException catch (e) {
      if (!mounted || operation != _authOperation) return;
      final error =
          e.response?.data?['error']?['message'] ?? 'Registration failed';
      state = state.copyWith(isLoading: false, error: error);
      rethrow;
    } catch (_) {
      if (!mounted || operation != _authOperation) return;
      state = state.copyWith(isLoading: false, error: 'Registration failed');
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    final operation = ++_authOperation;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data['data'];
      final user = data['user'] as Map<String, dynamic>?;
      final resolvedEmail = (user?['email'] as String?) ?? email;
      await _storage.saveTokens(
        data['accessToken'],
        data['refreshToken'],
        userId: user?['id'] as String?,
        email: resolvedEmail,
        displayName: _extractDisplayName(user, resolvedEmail),
      );
      if (!mounted || operation != _authOperation) return;
      state = AuthState(
        isAuthenticated: true,
        userId: user?['id'] as String?,
        email: resolvedEmail,
        displayName: _extractDisplayName(user, resolvedEmail),
        hasPassword: (user?['hasPassword'] as bool?) ?? true,
      );
    } on DioException catch (e) {
      if (!mounted || operation != _authOperation) return;
      final error = e.response?.data?['error']?['message'] ?? 'Login failed';
      state = state.copyWith(isLoading: false, error: error);
      rethrow;
    } catch (_) {
      if (!mounted || operation != _authOperation) return;
      state = state.copyWith(isLoading: false, error: 'Login failed');
      rethrow;
    }
  }

  Future<void> googleLogin(String idToken) async {
    final operation = ++_authOperation;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(
        '/auth/google',
        data: {'idToken': idToken},
      );
      final data = response.data['data'];
      final user = data['user'] as Map<String, dynamic>?;
      final email = (user?['email'] as String?) ?? '';
      await _storage.saveTokens(
        data['accessToken'],
        data['refreshToken'],
        userId: user?['id'] as String?,
        email: email,
        displayName: _extractDisplayName(user, email),
      );
      if (!mounted || operation != _authOperation) return;
      state = AuthState(
        isAuthenticated: true,
        userId: user?['id'] as String?,
        email: email,
        displayName: _extractDisplayName(user, email),
        hasPassword: (user?['hasPassword'] as bool?) ?? false,
      );
    } on DioException catch (e) {
      if (!mounted || operation != _authOperation) return;
      final error =
          e.response?.data?['error']?['message'] ?? 'Google login failed';
      state = state.copyWith(isLoading: false, error: error);
      rethrow;
    } catch (_) {
      if (!mounted || operation != _authOperation) return;
      state = state.copyWith(isLoading: false, error: 'Google login failed');
      rethrow;
    }
  }

  /// Fetches a portable JSON export of the signed-in user's financial data.
  Future<Map<String, dynamic>> exportData() async {
    final response = await _dio.get('/auth/export');
    final data = response.data['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected export response format.');
    }
    return data;
  }

  /// Permanently deletes the signed-in account and all associated server data,
  /// then clears local credentials and session state.
  ///
  /// [password] is required by the API for accounts that have one; Google-only
  /// accounts are confirmed by the active session.
  Future<void> deleteAccount({String? password}) async {
    final operation = ++_authOperation;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.delete(
        '/auth/me',
        data: {
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 404 means the account is already gone as far as this device is
      // concerned; every other failure (including a wrong password) must be
      // surfaced so the local session is not cleared prematurely.
      if (status != 404) {
        if (mounted && operation == _authOperation) {
          final error =
              e.response?.data?['error']?['message'] ??
              'Failed to delete account';
          state = state.copyWith(isLoading: false, error: error);
        }
        rethrow;
      }
    } catch (_) {
      if (mounted && operation == _authOperation) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete account',
        );
      }
      rethrow;
    }

    try {
      await _storage.clearTokens();
    } catch (_) {
      // Server-side deletion already succeeded; local cleanup is best effort
      // so the user is never blocked from leaving the deleted account.
    }
    if (mounted && operation == _authOperation) {
      state = const AuthState();
    }
  }

  Future<void> logout() async {
    ++_authOperation;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Local sign-out must still complete when the API or storage is down.
    } finally {
      try {
        await _storage.clearTokens();
      } catch (_) {
        // Nothing else can safely be done if secure storage is unavailable.
      }
      if (mounted) state = const AuthState();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.read(dioProvider);
  final storage = ref.read(secureStorageProvider);
  final sessionExpired = ref.watch(sessionExpiredProvider);
  return AuthNotifier(dio, storage, sessionExpired.stream);
});
