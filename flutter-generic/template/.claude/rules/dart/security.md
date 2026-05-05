---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---
# Dart/Flutter Security

> This file extends [common/security.md](../common/security.md) with Dart/Flutter specific content.

## Secret Management

- **Never** hardcode API keys, tokens, or passwords in Dart source files
- Use `--dart-define` or `--dart-define-from-file` for build-time secrets:

```bash
flutter run --dart-define=API_KEY=xxx
flutter run --dart-define-from-file=.env.json
```

```dart
// Access in code
const apiKey = String.fromEnvironment('API_KEY');
```

- Add `.env.json` and `*.env` to `.gitignore`
- Use `flutter_secure_storage` for runtime credential storage (uses Keychain/Keystore)

## Network Security

- Always use HTTPS — never plain HTTP for production endpoints
- Validate SSL certificates; avoid `badCertificateCallback: (_,_,_) => true`
- For Android: configure `network_security_config.xml` to disallow cleartext
- For iOS: ensure `NSAppTransportSecurity` does not allow arbitrary loads

## Data Storage

```dart
// Secure: use flutter_secure_storage for sensitive data
const storage = FlutterSecureStorage();
await storage.write(key: 'auth_token', value: token);

// Avoid: SharedPreferences for sensitive data (unencrypted)
```

## Input Validation

- Validate all user-entered data with `Form` + `FormField` validators
- Sanitize any content rendered as HTML (`flutter_widget_from_html` or similar)
- Never construct URLs or SQL from raw user input

## Dependency Security

- Pin major versions in `pubspec.yaml`: `some_package: ^2.0.0`
- Run `flutter pub outdated` regularly to check for vulnerable packages
- Review pub.dev security advisories before adding new dependencies
- Prefer packages with high pub points, verified publishers, and active maintenance

## Android Specific

- Disable debug mode in release builds (`debuggable: false` in `build.gradle`)
- Use ProGuard/R8 for release builds to obfuscate code
- Request only necessary permissions in `AndroidManifest.xml`

## iOS Specific

- Use App Transport Security (ATS) — do not disable globally
- Declare only necessary `NSUsageDescription` keys in `Info.plist`
- Enable Bitcode for obfuscation benefits (where applicable)

## Flutter Obfuscation

```bash
flutter build apk --obfuscate --split-debug-info=./debug-info/
flutter build ipa --obfuscate --split-debug-info=./debug-info/
```

Store `debug-info/` artifacts securely for crash symbolication.
