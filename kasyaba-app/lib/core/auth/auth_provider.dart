import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../api/api_client.dart';

// Auth state
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final String? displayName;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.email,
    this.displayName,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? email,
    String? displayName,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthNotifier(this._dio, this._storage) : super(const AuthState());

  String _extractDisplayName(Map<String, dynamic>? userJson, String fallbackEmail) {
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

  Future<void> checkAuth() async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      try {
        final response = await _dio.get('/auth/me');
        final user = response.data['data'] as Map<String, dynamic>?;
        if (user != null) {
          final email = (user['email'] as String?) ?? '';
          state = AuthState(
            isAuthenticated: true,
            userId: user['id'] as String?,
            email: email,
            displayName: _extractDisplayName(user, email),
          );
        }
      } catch (_) {
        await _storage.clearTokens();
      }
    }
  }

  Future<void> register(String email, String password, {String? displayName}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'displayName': displayName,
      });
      final data = response.data['data'];
      await _storage.saveTokens(data['accessToken'], data['refreshToken']);
      final user = data['user'] as Map<String, dynamic>?;
      state = AuthState(
        isAuthenticated: true,
        userId: user?['id'] as String?,
        email: email,
        displayName: _extractDisplayName(user, email),
      );
    } on DioException catch (e) {
      final error = e.response?.data?['error']?['message'] ?? 'Registration failed';
      state = state.copyWith(isLoading: false, error: error);
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data['data'];
      await _storage.saveTokens(data['accessToken'], data['refreshToken']);
      final user = data['user'] as Map<String, dynamic>?;
      state = AuthState(
        isAuthenticated: true,
        userId: user?['id'] as String?,
        email: email,
        displayName: _extractDisplayName(user, email),
      );
    } on DioException catch (e) {
      final error = e.response?.data?['error']?['message'] ?? 'Login failed';
      state = state.copyWith(isLoading: false, error: error);
      rethrow;
    }
  }

  Future<void> googleLogin(String idToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post('/auth/google', data: {
        'idToken': idToken,
      });
      final data = response.data['data'];
      await _storage.saveTokens(data['accessToken'], data['refreshToken']);
      final user = data['user'] as Map<String, dynamic>?;
      final email = (user?['email'] as String?) ?? '';
      state = AuthState(
        isAuthenticated: true,
        userId: user?['id'] as String?,
        email: email,
        displayName: _extractDisplayName(user, email),
      );
    } on DioException catch (e) {
      final error = e.response?.data?['error']?['message'] ?? 'Google login failed';
      state = state.copyWith(isLoading: false, error: error);
      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {}
    }
    await _storage.clearTokens();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.read(dioProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthNotifier(dio, storage);
});
