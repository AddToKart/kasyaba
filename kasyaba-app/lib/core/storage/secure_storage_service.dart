import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'auth_user_id';
  static const _userEmailKey = 'auth_user_email';
  static const _userDisplayNameKey = 'auth_user_display_name';

  Future<void> saveTokens(
    String accessToken,
    String refreshToken, {
    String? userId,
    String? email,
    String? displayName,
  }) async {
    final userWrites = userId != null && email != null
        ? [
            _storage.write(key: _userIdKey, value: userId),
            _storage.write(key: _userEmailKey, value: email),
            _storage.write(key: _userDisplayNameKey, value: displayName ?? ''),
          ]
        : [
            _storage.delete(key: _userIdKey),
            _storage.delete(key: _userEmailKey),
            _storage.delete(key: _userDisplayNameKey),
          ];
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      ...userWrites,
    ]);
  }

  Future<void> saveUser({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userEmailKey, value: email),
      _storage.write(key: _userDisplayNameKey, value: displayName ?? ''),
    ]);
  }

  Future<Map<String, String>?> getCachedUser() async {
    final values = await Future.wait([
      _storage.read(key: _userIdKey),
      _storage.read(key: _userEmailKey),
      _storage.read(key: _userDisplayNameKey),
    ]);
    final userId = values[0];
    final email = values[1];
    if (userId == null || email == null) return null;
    return {
      'id': userId,
      'email': email,
      if (values[2] != null && values[2]!.isNotEmpty) 'displayName': values[2]!,
    };
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userEmailKey),
      _storage.delete(key: _userDisplayNameKey),
    ]);
  }
}
