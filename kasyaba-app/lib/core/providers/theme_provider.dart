import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';

/// ─────────────────────────────────────────────────────────────
///  Theme Mode Provider — frozen to dark for this cycle (D2).
///  Public API kept unchanged so settings keeps compiling.
/// ─────────────────────────────────────────────────────────────

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SecureStorageService _storage;
  static const _themeKey = 'app_theme_mode';

  ThemeModeNotifier(this._storage) : super(ThemeMode.dark) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    // Light/system are intentionally ignored while the navy dark theme is the
    // only designed surface (D2).
    state = ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = ThemeMode.dark;
    try {
      await _storage.writeRaw(_themeKey, 'dark');
    } catch (_) {}
  }
}
