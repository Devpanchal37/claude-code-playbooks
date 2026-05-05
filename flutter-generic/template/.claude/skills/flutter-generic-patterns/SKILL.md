---
name: flutter-generic-patterns
description: Flutter coding patterns, conventions, and Clean Architecture workflows for this project. Fill in each section with your stack's specific patterns after completing TEMPLATE_SETUP.md.
version: 1.0.0
source: project-conventions
---

# Flutter Clean Architecture Patterns

> **This skill is a shell.** Fill in every section below with your project's actual stack and patterns.
> Once filled in, agents will reference this skill for all implementation and review work.
> See TEMPLATE_SETUP.md Step 2b for instructions.

---

## Stack

<!-- ═══════════════════════════════════════════════════════════
  Replace the example values with your actual packages and versions.
  
  - **Framework**: Flutter (Material Design / Cupertino)
  - **State Management**: {{STATE_MANAGEMENT}}
  - **Navigation**: {{ROUTING_SOLUTION}}
  - **DI**: {{DI_SOLUTION}}
  - **HTTP client**: (your choice — e.g. dio, http)
  - **Local storage**: (your choice — e.g. hive, shared_preferences)
  - **Responsive sizing**: (your choice — e.g. flutter_screenutil, MediaQuery)
  - **Testing mocking**: mocktail (recommended — no codegen)
  ═══════════════════════════════════════════════════════════ -->

---

## Project Structure

```
lib/
├── main.dart                        # App entry, DI initialization
├── src/
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_colors.dart      # All app colors
│   │   │   ├── app_text_styles.dart # All text styles
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   └── validators.dart
│   │   ├── network/
│   │   │   └── api_client.dart      # HTTP client setup
│   │   └── routes/
│   │       └── app_routes.dart      # Route constants
│   ├── shared/
│   │   └── widgets/                 # Shared reusable widgets
│   └── features/
│       └── <feature_name>/
│           ├── data/
│           │   ├── datasources/     # Remote / local data sources
│           │   ├── models/          # DTOs (fromJson/toJson/toDomain)
│           │   └── repositories/    # Concrete implementations
│           ├── domain/
│           │   ├── entities/        # @immutable pure Dart
│           │   ├── repositories/    # Abstract interfaces
│           │   └── use_cases/       # One execute() per use case
│           └── presentation/
│               ├── screens/         # Route target widgets
│               ├── widgets/         # Feature-specific widgets
│               └── (state_holders/) # Controllers / Notifiers / Blocs
```

---

## Core Conventions

### MUST-DO
<!-- ═══════════════════════════════════════════════════════════
  Fill in your project's non-negotiable rules:
  - State management: must use {{STATE_MANAGEMENT}}, not raw setState for feature state
  - Navigation: must use route constants from app_routes.dart — never hardcoded strings
  - Display strings: must use the localization accessor — never hardcode UI text
  - Colors: must use AppColors.xxx — never Color(0xFF...) or Colors.xxx
  - Text styles: must use AppTextStyles.xxx — never inline TextStyle
  - Sizing: describe your responsive sizing convention
  - Standard border radius: define your project's default
  ═══════════════════════════════════════════════════════════ -->

### File Naming
- All files: `snake_case.dart`
- State holders: `<feature>_controller.dart` / `<feature>_notifier.dart` / `<feature>_bloc.dart`
- Screens: `<feature>_screen.dart`
- Use cases: `<action>_use_case.dart`
- DTOs: `<entity>_model.dart`
- Tests mirror source: `test/features/<feature>/...`

---

## State Holder Pattern

<!-- ═══════════════════════════════════════════════════════════
  Add your state holder code pattern here.
  One state holder per screen. Holds only UI state.
  Business logic lives in use cases.
  
  See rules/dart/patterns.md for multi-stack examples.
  ═══════════════════════════════════════════════════════════ -->

---

## Screen Widget Pattern

<!-- ═══════════════════════════════════════════════════════════
  Add your screen widget pattern here.
  Every screen with async data must implement 4 states:
    1. Loading  — shimmer skeleton
    2. Error    — error message + retry
    3. Empty    — descriptive empty state
    4. Success  — actual content
  ═══════════════════════════════════════════════════════════ -->

---

## Route Registration

<!-- ═══════════════════════════════════════════════════════════
  Add your router setup pattern here.
  Show: how routes are declared, how DI is wired per route,
  and how to navigate (push, replace, pop).
  ═══════════════════════════════════════════════════════════ -->

---

## Shared Widget Pattern

```dart
// shared/widgets/app_button.dart — example structure, fill in your conventions
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // Use AppColors.xxx, AppTextStyles.xxx, and your sizing convention
    return const Placeholder();
  }
}
```

---

## Testing Patterns

<!-- ═══════════════════════════════════════════════════════════
  Add your test skeletons here.
  See rules/dart/testing.md for multi-stack examples.
  
  Include:
  - Use case unit test (mocktail mock of repository)
  - State holder unit test (mock use case, assert state transitions)
  - Widget test (inject mock state holder, pump widget, assert UI)
  ═══════════════════════════════════════════════════════════ -->

---

## Common Flutter Commands

```bash
flutter pub get                             # install dependencies
flutter run                                 # run on device
flutter test                                # all unit + widget tests
flutter test --coverage                     # with coverage
flutter test integration_test/             # integration tests
flutter analyze                             # lint
dart fix --apply                            # auto-fix lints
dart format .                               # format all Dart files
flutter build apk --release                 # Android release
flutter build apk --obfuscate \
  --split-debug-info=./debug-info/          # obfuscated release

# Codegen (if using build_runner — e.g. freezed, json_serializable, injectable)
dart run build_runner build --delete-conflicting-outputs
```

---

## When to Use Agents

- `/plan` — before starting any new feature
- `/tdd` — test-first widget/unit development
- `/code-review` — before marking a feature done
- `/refactor-clean` — when a file exceeds ~400 lines or has duplication
- `/build-fix` — when `flutter analyze` or `flutter test` fails
- `/verify` — before committing or creating a PR
