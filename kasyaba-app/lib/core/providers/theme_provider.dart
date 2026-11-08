import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';

/// ─────────────────────────────────────────────────────────────
///  Theme Mode Provider — persists the user's appearance choice.
///
///  Light/system were re-enabled by Phase LT-A of
///  LIGHT_MODE_AND_GOAL_INPUT_PLAN. D-LT2: the default remains dark when
///  nothing has been stored, so existing users see no change.
/// ─────────────────────────────────────────────────────────────

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SecureStorageService _storage;
  static const _themeKey = 'app_theme_mode';

  /// Guards the async hydration below: a user choice made before the stored
  /// value resolves must never be overwritten by the late load.
  bool _userSelected = false;

  ThemeModeNotifier(this._storage) : super(ThemeMode.dark) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final stored = await _storage.readRaw(_themeKey);
      if (!mounted || _userSelected) return;
      // D-LT2: default stays dark when nothing is stored.
      state = _decode(stored) ?? ThemeMode.dark;
    } catch (_) {
      if (!mounted || _userSelected) return;
      // Keep the dark default when secure storage is unavailable.
      state = ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _userSelected = true;
    state = mode;
    try {
      await _storage.writeRaw(_themeKey, _encode(mode));
    } catch (_) {}
  }

  ThemeMode? _decode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
        return ThemeMode.dark;
      default:
        return null;
    }
  }

  String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}
