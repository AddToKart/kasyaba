/// Single source of truth for the user-visible app version. Keep in sync with
/// the `version:` field in pubspec.yaml.
const String kAppVersion = '0.1.0';
const String kAppBuild = '1';
const String kAppVersionLabel = 'v$kAppVersion (Build $kAppBuild)';

/// Hosted legal pages are the canonical privacy/terms source (see plan D1).
///
/// These defaults are placeholders for local development. Production builds
/// MUST override both values with the real deployed backend URLs, e.g.:
///
/// ```sh
/// flutter build appbundle --release \
///   --dart-define=PRIVACY_POLICY_URL=https://api.example.com/privacy \
///   --dart-define=TERMS_URL=https://api.example.com/terms
/// ```
const String kPrivacyPolicyUrl = String.fromEnvironment(
  'PRIVACY_POLICY_URL',
  defaultValue: 'https://kasyaba.app/privacy',
);
const String kTermsUrl = String.fromEnvironment(
  'TERMS_URL',
  defaultValue: 'https://kasyaba.app/terms',
);
