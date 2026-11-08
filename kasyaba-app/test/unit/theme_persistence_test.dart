// Theme-mode persistence gate for Phase LT-E.
//
// Verifies the D-LT2 contract end-to-end without widgets:
//   * default remains Dark when secure storage is empty,
//   * choosing Light/System writes the canonical string,
//   * a fresh [ThemeModeNotifier] over the same storage hydrates the choice
//     (simulating an app restart),
//   * the Riverpod provider wires the notifier to `secureStorageProvider`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/providers/theme_provider.dart';
import 'package:kasyaba/core/storage/secure_storage_service.dart';

import '../support/fake_engine_stack.dart';

const String _themeKey = 'app_theme_mode';

void main() {
  test('defaults to ThemeMode.dark when nothing is stored', () async {
    final storage = FakeSecureStorage();
    final notifier = ThemeModeNotifier(storage);
    addTearDown(notifier.dispose);

    await pumpEventQueue();

    expect(notifier.state, ThemeMode.dark);
    expect(
      storage.values.containsKey(_themeKey),
      isFalse,
      reason: 'Hydrating the default must not write over the stored choice.',
    );
  });

  test('setThemeMode(light) persists the canonical light value', () async {
    final storage = FakeSecureStorage();
    final notifier = ThemeModeNotifier(storage);
    addTearDown(notifier.dispose);
    // Let the constructor's async hydration finish first (mirrors a user
    // interacting after the first frame).
    await pumpEventQueue();

    await notifier.setThemeMode(ThemeMode.light);

    expect(notifier.state, ThemeMode.light);
    expect(storage.values[_themeKey], 'light');
  });

  test('a new notifier over the same storage hydrates light', () async {
    final storage = FakeSecureStorage();
    final first = ThemeModeNotifier(storage);
    addTearDown(first.dispose);
    await pumpEventQueue();

    await first.setThemeMode(ThemeMode.light);

    final restarted = ThemeModeNotifier(storage);
    addTearDown(restarted.dispose);
    await pumpEventQueue();

    expect(
      restarted.state,
      ThemeMode.light,
      reason: 'App restart should restore the persisted light preference.',
    );
  });

  test('setThemeMode(system) persists and hydrates system', () async {
    final storage = FakeSecureStorage();
    final notifier = ThemeModeNotifier(storage);
    addTearDown(notifier.dispose);
    await pumpEventQueue();

    await notifier.setThemeMode(ThemeMode.system);
    expect(storage.values[_themeKey], 'system');

    final restarted = ThemeModeNotifier(storage);
    addTearDown(restarted.dispose);
    await pumpEventQueue();

    expect(restarted.state, ThemeMode.system);
  });

  test('setThemeMode(dark) round-trips dark explicitly', () async {
    final storage = FakeSecureStorage(
      initial: <String, String>{_themeKey: 'light'},
    );
    final notifier = ThemeModeNotifier(storage);
    addTearDown(notifier.dispose);
    await pumpEventQueue();
    expect(notifier.state, ThemeMode.light);

    await notifier.setThemeMode(ThemeMode.dark);
    expect(storage.values[_themeKey], 'dark');

    final restarted = ThemeModeNotifier(storage);
    addTearDown(restarted.dispose);
    await pumpEventQueue();

    expect(restarted.state, ThemeMode.dark);
  });

  test('unknown stored values fall back to the dark default', () async {
    final storage = FakeSecureStorage(
      initial: <String, String>{_themeKey: 'sepia'},
    );
    final notifier = ThemeModeNotifier(storage);
    addTearDown(notifier.dispose);

    await pumpEventQueue();

    expect(notifier.state, ThemeMode.dark);
  });

  test('an explicit choice made during hydration is not overwritten', () async {
    final storage = _DelayedReadStorage(
      initial: <String, String>{_themeKey: 'light'},
      delay: const Duration(milliseconds: 40),
    );
    final notifier = ThemeModeNotifier(storage);
    addTearDown(notifier.dispose);

    // The user picks a mode before the delayed storage read resolves.
    await notifier.setThemeMode(ThemeMode.system);
    await Future<void>.delayed(const Duration(milliseconds: 90));

    expect(
      notifier.state,
      ThemeMode.system,
      reason: 'late hydration must not clobber an explicit user choice',
    );
    expect(storage.values[_themeKey], 'system');
  });

  test(
    'themeModeProvider hydrates from secureStorageProvider overrides',
    () async {
      final storage = FakeSecureStorage(
        initial: <String, String>{_themeKey: 'light'},
      );
      final container = ProviderContainer(
        overrides: <Override>[
          secureStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      // First read builds the notifier synchronously (still on the dark
      // default); the persisted value arrives after the async storage read.
      container.read(themeModeProvider);
      await pumpEventQueue();

      expect(container.read(themeModeProvider), ThemeMode.light);
    },
  );
}

/// Delays the secure-storage read so a user choice can race the hydration.
class _DelayedReadStorage extends FakeSecureStorage {
  _DelayedReadStorage({super.initial, required this.delay});

  final Duration delay;

  @override
  Future<String?> readRaw(String key) async {
    await Future<void>.delayed(delay);
    return super.readRaw(key);
  }
}
