import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Exact claims that no longer match the shipped online-first architecture
/// (plan §1 wording law and §4 D6). Comments are stripped before scanning so
/// implementation notes may reference retired wording without failing the
/// user-facing copy gate.
const List<String> _bannedPhrases = <String>[
  'local-first',
  'Local-First Edge Engine',
  'Every calculation runs on your device',
  '100% on-device math',
  'TLS 1.3',
  'AES-256',
];

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

/// Removes `//` line comments and `/* ... */` block comments while preserving
/// string literals (so `https://` URLs and in-copy slashes are untouched).
String _stripComments(String source) {
  final output = StringBuffer();
  var index = 0;
  String? quote;
  var escaped = false;

  while (index < source.length) {
    final char = source[index];

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
          index++;
        }
        continue;
      }
      if (next == '*') {
        index += 2;
        while (index + 1 < source.length &&
            !(source[index] == '*' && source[index + 1] == '/')) {
          index++;
        }
        index = index + 2 <= source.length ? index + 2 : source.length;
        continue;
      }
    }

    output.write(char);
    index++;
  }

  return output.toString();
}

void main() {
  late Directory libDirectory;
  late List<File> dartFiles;

  setUpAll(() {
    libDirectory = _resolveLibDirectory();
    dartFiles = _dartFilesIn(libDirectory);
  });

  test('lib/ contains no retired local-first or unverified security claims', () {
    expect(dartFiles, isNotEmpty);

    final violations = <String>[];
    for (final file in dartFiles) {
      final source = _stripComments(file.readAsStringSync()).toLowerCase();
      for (final phrase in _bannedPhrases) {
        if (source.contains(phrase.toLowerCase())) {
          violations.add('${file.path}: "$phrase"');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Retired policy wording found in lib/. Use online-first, server-backed '
          'copy instead:\n${violations.join('\n')}',
    );
  });

  test('in-app privacy summary carries the canonical online-first copy', () {
    final source = File(
      '${libDirectory.path}/features/settings/screens/privacy_about_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Server-backed with offline cache'));
    expect(
      source,
      contains('Daily math on-device; planning & forecasts on server'),
    );
    expect(source, contains('Online-first + on-device math'));
    expect(source, contains('encrypted in transit (HTTPS/TLS)'));
    expect(source, contains('Read full policy'));
  });

  test('auth trust footer carries the online-first copy', () {
    final source = File(
      '${libDirectory.path}/features/auth/widgets/auth_widgets.dart',
    ).readAsStringSync();

    expect(source, contains('Server-backed security. Instant on-device math.'));
  });
}
