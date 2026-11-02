import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';

/// ─────────────────────────────────────────────────────────────
///  Theme Mode Provider — Dual Lighting Architecture
///  Supports Dark (Obsidian), Light (Porcelain), and System mode.
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

  Future<void> _loadThemeMode() async {
    try {
      final saved = await _storage.readRaw(_themeKey);
      if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'system') {
        state = ThemeMode.system;
      } else {
        state = ThemeMode.dark;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final val = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      };
      await _storage.writeRaw(_themeKey, val);
    } catch (_) {}
  }
}

