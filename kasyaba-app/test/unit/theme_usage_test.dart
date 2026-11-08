// Theme-usage gate for Phase LT-E.
//
// Phase LT-D migrated every routed screen, shared widget, and system surface to
// `context.kColors`. This gate keeps it that way by scanning the migrated
// scopes for:
//   * raw Material palette constants (`Colors.white`, `Colors.grey`, ...),
//   * raw `Color(0x…)` literals,
//   * static color-token reads (`KasyabaTokens.ebony`,
//     `DashboardTokens.cello60`, `KasyabaTokens.canvasGradient`, ...).
//
// Sizing tokens (`KasyabaTokens.radiusCard`, `dockClearance`, …) stay legal —
// only names declared as `static const Color` / `static const RadialGradient`
// in the token files are treated as colors.
//
// The token sources themselves are allowlisted. `auth_widgets.dart` keeps two
// documented exceptions: the dark-only AuthFigmaTokens gradient recipe (no
// semantic equivalent yet) and the legacy dark placeholder grey.
//
// Comments are stripped before scanning (same technique as policy_copy_test),
// so explanatory notes may mention banned names without failing the gate.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Directories (relative to `lib/`) covered by the color gate.
const List<String> _scanScopes = <String>[
  'features/',
  'shared/',
  'app/router/',
];

/// Files allowed to define raw colors / static token values.
const Set<String> _allowlistedFiles = <String>{
  'app/theme/kasyaba_tokens.dart',
  'app/theme/kasyaba_color_scheme.dart',
  'app/theme/app_theme.dart',
  'features/dashboard/widgets/dashboard_tokens.dart',
};

const String _authWidgets = 'features/auth/widgets/auth_widgets.dart';

/// A line-level, file-scoped exception with an explicit reason.
class _ExceptionRule {
  const _ExceptionRule(this.file, this.reason, this.linePattern);

  final String file;
  final String reason;
  final RegExp linePattern;

  bool matches(String relativePath, String line) =>
      file == relativePath && linePattern.hasMatch(line.trim());
}

/// See `lib/features/auth/widgets/auth_widgets.dart` — these four gradients
/// are the dark-only Figma wash recipe. Light mode derives `AuthFigmaTokens
/// .lightGlow` from the active palette instead.
final List<_ExceptionRule> _authExceptions = <_ExceptionRule>[
  _ExceptionRule(
    _authWidgets,
    'AuthFigmaTokens.glowTopRight dark gradient recipe',
    RegExp(r'^colors: \[Color\(0xCC4F7596\), Color\(0x004F7596\)\],$'),
  ),
  _ExceptionRule(
    _authWidgets,
    'AuthFigmaTokens.glowBottomLeft dark gradient recipe',
    RegExp(r'^colors: \[KasyabaTokens\.cello, Color\(0x001E3A56\)\],$'),
  ),
  _ExceptionRule(
    _authWidgets,
    'AuthFigmaTokens.glowRight dark gradient recipe',
    RegExp(r'^colors: \[Color\(0xAB1E3A56\), Color\(0x001E3A56\)\],$'),
  ),
  _ExceptionRule(
    _authWidgets,
    'AuthFigmaTokens.forgotGlow dark gradient recipe',
    RegExp(r'^colors: \[Color\(0xAB4F7596\), Color\(0x004F7596\)\],$'),
  ),
  _ExceptionRule(
    _authWidgets,
    'legacy dark-only placeholder grey (light mode already uses textMuted)',
    RegExp(r'^color: isDark \? Colors\.grey\.shade600 : colors\.textMuted,$'),
  ),
];

/// Routed screens converted by the LT-D waves.
const List<String> _migratedScreens = <String>[
  'features/splash/screens/splash_screen.dart',
  'features/auth/screens/login_screen.dart',
  'features/auth/screens/register_screen.dart',
  'features/auth/screens/forgot_password_screen.dart',
  'features/dashboard/screens/dashboard_screen.dart',
  'features/planning/screens/planning_screen.dart',
  'features/transactions/screens/transactions_screen.dart',
  'features/bills/screens/bills_screen.dart',
  'features/savings/screens/goals_screen.dart',
  'features/budgets/screens/budgets_screen.dart',
  'features/alerts/screens/alerts_screen.dart',
  'features/settings/screens/settings_screen.dart',
  'features/accounts/screens/accounts_screen.dart',
  'features/settings/screens/notification_settings_screen.dart',
  'features/settings/screens/backup_export_screen.dart',
  'features/settings/screens/delete_account_screen.dart',
  'features/settings/screens/privacy_about_screen.dart',
  'features/planning/screens/math_breakdown_screen.dart',
  'features/transactions/screens/add_transaction_screen.dart',
  'features/bills/screens/add_bill_screen.dart',
  'features/savings/screens/create_goal_screen.dart',
  'features/savings/screens/goal_detail_screen.dart',
];

/// Shared widgets converted by LT-B.
const List<String> _migratedSharedWidgets = <String>[
  'shared/widgets/app_dialog.dart',
  'shared/widgets/app_sheet.dart',
  'shared/widgets/app_state_widgets.dart',
  'shared/widgets/figma_toggle_switch.dart',
  'shared/widgets/kasyaba_background.dart',
  'shared/widgets/kasyaba_card.dart',
  'shared/widgets/kasyaba_date_picker.dart',
  'shared/widgets/kasyaba_toast.dart',
  'shared/widgets/motion_components.dart',
  'shared/widgets/offline_status.dart',
  'shared/widgets/pill_button.dart',
];

/// System surfaces converted by LT-C.
const List<String> _migratedSystemSurfaces = <String>[
  'app/app.dart',
  'app/router/app_shell.dart',
];

/// Raw Material palette constants that are banned outside the token layer.
final RegExp _rawMaterialColorPattern = RegExp(
  r'\bColors\.(white|black|red|amber|blue|green|grey|orange|purple)\b',
);

/// Raw hex literals, e.g. `Color(0xFF0A1220)`.
final RegExp _rawHexColorPattern = RegExp(
  r'\bColor\(\s*0x[0-9A-Fa-f]+',
);

/// Static token reads, e.g. `KasyabaTokens.ebony`.
final RegExp _staticTokenPattern = RegExp(
  r'\b(KasyabaTokens|DashboardTokens)\.([A-Za-z0-9_]+)',
);

Directory _resolveLibDirectory() {
  final direct = Directory('lib');
  if (direct.existsSync()) return direct;

  final nested = Directory('kasyaba-app/lib');
  if (nested.existsSync()) return nested;

  fail('Could not locate lib/ from ${Directory.current.path}');
}

List<File> _dartFilesIn(Directory root) {
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

String _relativeLibPath(File file, Directory libDirectory) {
  final normalizedFile = file.absolute.path.replaceAll('\\', '/');
  final normalizedRoot = libDirectory.absolute.path.replaceAll('\\', '/');
  final prefix = normalizedRoot.endsWith('/')
      ? normalizedRoot
      : '$normalizedRoot/';
  return normalizedFile.startsWith(prefix)
      ? normalizedFile.substring(prefix.length)
      : normalizedFile;
}

/// Blanks out `//` and `/* … */` comments while preserving string literals,
/// line count, and column positions (comment characters become spaces).
String _stripCommentsPreservingLines(String source) {
  final output = StringBuffer();
  var index = 0;
  String? quote;
  var escaped = false;
  var inBlockComment = false;

  while (index < source.length) {
    final char = source[index];

    if (inBlockComment) {
      if (char == '*' &&
          index + 1 < source.length &&
          source[index + 1] == '/') {
        output.write('  ');
        index += 2;
        inBlockComment = false;
        continue;
      }
      output.write(char == '\n' ? '\n' : ' ');
      index++;
      continue;
    }

    if (quote != null) {
      output.write(char);
      if (escaped) {
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == quote) {
        quote = null;
      }
      index++;
      continue;
    }

    if (char == "'" || char == '"') {
      quote = char;
      output.write(char);
      index++;
      continue;
    }

    if (char == '/' && index + 1 < source.length) {
      final next = source[index + 1];
      if (next == '/') {
        while (index < source.length && source[index] != '\n') {
          output.write(' ');
          index++;
        }
        continue;
      }
      if (next == '*') {
        output.write('  ');
        index += 2;
        inBlockComment = true;
        continue;
      }
    }

    output.write(char);
    index++;
  }

  return output.toString();
}

/// Color names declared by the token files (`static const Color` /
/// `static const RadialGradient`). Sizing tokens are deliberately excluded.
Set<String> _colorTokenNames(Directory libDirectory) {
  final names = <String>{};
  final declaration = RegExp(
    r'static const (?:Color|RadialGradient)\s+([A-Za-z0-9_]+)',
  );

  for (final relative in <String>[
    'app/theme/kasyaba_tokens.dart',
    'features/dashboard/widgets/dashboard_tokens.dart',
  ]) {
    final file = File('${libDirectory.path}/$relative');
    expect(file.existsSync(), isTrue, reason: 'Missing token file $relative');
    final source = _stripCommentsPreservingLines(file.readAsStringSync());
    for (final match in declaration.allMatches(source)) {
      names.add(match.group(1)!);
    }
  }

  expect(
    names,
    containsAll(<String>[
      'ebony',
      'bigStone',
      'cello60',
      'periwinkleGray',
      'canvasGradient',
    ]),
    reason: 'Token color discovery should find the known semantic colors.',
  );
  return names;
}

void main() {
  late Directory libDirectory;
  late Set<String> colorTokenNames;

  setUpAll(() {
    libDirectory = _resolveLibDirectory();
    colorTokenNames = _colorTokenNames(libDirectory);
  });

  test(
    'migrated scopes contain no raw color literals or static color tokens',
    () {
      final violations = <String>[];

      for (final file in _dartFilesIn(libDirectory)) {
        final relative = _relativeLibPath(file, libDirectory);
        if (!_scanScopes.any(relative.startsWith)) continue;
        if (_allowlistedFiles.contains(relative)) continue;

        final lines =
            _stripCommentsPreservingLines(file.readAsStringSync()).split('\n');

        for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
          final line = lines[lineIndex];
          final lineNumber = lineIndex + 1;
          if (_authExceptions.any(
            (exception) => exception.matches(relative, line),
          )) {
            continue;
          }

          for (final match in _rawMaterialColorPattern.allMatches(line)) {
            violations.add(
              '$relative:$lineNumber: raw ${match.group(0)}',
            );
          }
          for (final match in _rawHexColorPattern.allMatches(line)) {
            violations.add(
              '$relative:$lineNumber: raw ${match.group(0)}…)',
            );
          }
          for (final match in _staticTokenPattern.allMatches(line)) {
            final token = match.group(2)!;
            if (!colorTokenNames.contains(token)) continue;
            violations.add(
              '$relative:$lineNumber: static ${match.group(0)} '
              '(use context.kColors)',
            );
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Screens/widgets/routing must paint from context.kColors. '
            'Move any intentional literal into the token layer instead of '
            'hard-painting it:\n${violations.join('\n')}',
      );
    },
  );

  test('documented auth_widgets exceptions still match their exact lines', () {
    final source = File('${libDirectory.path}/$_authWidgets').readAsStringSync();
    final lines = _stripCommentsPreservingLines(
      source,
    ).split('\n').map((line) => line.trim()).toList(growable: false);

    for (final exception in _authExceptions) {
      expect(
        lines.any(exception.linePattern.hasMatch),
        isTrue,
        reason:
            'Stale exception "${exception.reason}" in $_authWidgets. '
            'Remove it if the line changed so the ban applies again.',
      );
    }
  });

  test('every migrated screen and shared surface reads context.kColors', () {
    final missing = <String>[];

    for (final relative in <String>[
      ..._migratedScreens,
      ..._migratedSharedWidgets,
      ..._migratedSystemSurfaces,
    ]) {
      final file = File('${libDirectory.path}/$relative');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Migrated file list points at a missing file: $relative',
      );
      final source = _stripCommentsPreservingLines(file.readAsStringSync());
      if (!source.contains('kColors')) {
        missing.add(relative);
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'These migrated files never read context.kColors, so they cannot '
          'follow the selected theme:\n${missing.join('\n')}',
    );
  });

  test('sizing tokens remain allowed while color tokens stay banned', () {
    expect(colorTokenNames, contains('ebony'));
    expect(colorTokenNames, isNot(contains('radiusCard')));
    expect(colorTokenNames, isNot(contains('dockClearance')));
    expect(colorTokenNames, isNot(contains('radiusDialog')));
  });
}
