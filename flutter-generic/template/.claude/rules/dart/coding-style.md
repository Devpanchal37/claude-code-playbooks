---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---
# Dart/Flutter Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Dart/Flutter specific content.

## Formatting

- **dart format** for auto-formatting (enforced by CI)
- **flutter analyze** for static analysis
- **dart fix --apply** for auto-fixable lint issues
- Linting: extend `package:flutter_lints/flutter.yaml` in `analysis_options.yaml`

## State Management

<!-- ═══════════════════════════════════════════════════════════
  {{STATE_MANAGEMENT}} CONVENTIONS
  
  Replace this block with your project's mandatory state management rules.
  Define what is BANNED and what is CORRECT for your chosen stack.
  
  Include:
  - How to define a state holder (class declaration)
  - How to observe state in a widget (Consumer, BlocBuilder, Obx, etc.)
  - Whether StatefulWidget is allowed and when
  - Any BANNED alternatives (e.g. if using Riverpod, ban setState for feature state)
  
  Riverpod example skeleton:
    BANNED: setState for feature state, direct business logic in widgets
    CORRECT: AsyncNotifierProvider / StateNotifierProvider
    CORRECT widget: ConsumerWidget with ref.watch(provider)
    StatefulWidget allowed only for purely local animation/focus state
  
  Bloc example skeleton:
    BANNED: business logic in widgets
    CORRECT: Bloc<Event, State> or Cubit<State>
    CORRECT widget: BlocBuilder / BlocListener / BlocConsumer
  ═══════════════════════════════════════════════════════════ -->

`StatefulWidget` is allowed ONLY for purely local UI state that never needs testing (e.g., animation controllers, focus nodes).

## Navigation: Route Constants ONLY

<!-- ═══════════════════════════════════════════════════════════
  {{ROUTING_SOLUTION}} CONVENTIONS
  
  Replace this block with your project's routing rules.
  
  Include:
  - How route constants are defined and where (e.g. Routes class, AppRoutes class)
  - How to navigate (e.g. context.go(), Get.toNamed(), router.push())
  - BANNED patterns (hardcoded strings, Navigator.pushNamed('/home') etc.)
  
  GoRouter example:
    CORRECT: context.go(AppRoutes.home)
    CORRECT: context.push(AppRoutes.profile, extra: user)
    BANNED: Navigator.push(context, MaterialPageRoute(...)) for named routes
  ═══════════════════════════════════════════════════════════ -->

All route paths are defined as constants in the project's routes file — never hardcode route strings.

## Strings/Localization: Localization Accessor ONLY

<!-- ═══════════════════════════════════════════════════════════
  Replace this block with your project's localization rules.
  
  Include:
  - How to access localized strings (e.g. context.l10n.xxx, AppLocalizations.of(context).xxx)
  - BANNED patterns (hardcoded string literals in UI widgets)
  
  flutter_localizations example:
    CORRECT: Text(context.l10n.welcomeBack)
    BANNED:  Text('Welcome back')  // ❌
  ═══════════════════════════════════════════════════════════ -->

All user-visible strings must go through the project's localization accessor — never hardcode UI text.

## Colors: Color Constants ONLY

<!-- ═══════════════════════════════════════════════════════════
  Replace this block with your project's color rules.
  
  Include:
  - Where color constants live (e.g. AppColors, ColorHelper, ThemeData)
  - BANNED patterns (Color(0xFF...), Colors.blue)
  
  Example:
    CORRECT: color: AppColors.primary
    BANNED:  color: const Color(0xFF1A73E8)  // ❌
    BANNED:  color: Colors.blue              // ❌
  ═══════════════════════════════════════════════════════════ -->

## Text Styles: Text Style Constants ONLY

<!-- ═══════════════════════════════════════════════════════════
  Replace this block with your project's text style rules.
  
  Include:
  - Where text style constants live (e.g. AppTextStyles, TextStyleHelper, ThemeData.textTheme)
  - BANNED patterns (inline TextStyle with hardcoded fontSize/fontWeight)
  
  Example:
    CORRECT: style: AppTextStyles.heading1
    BANNED:  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)  // ❌
  ═══════════════════════════════════════════════════════════ -->

## Sizing: SizeUtils ONLY

```dart
// BANNED: hardcoded pixel values for responsive sizing
width: 16.0     // ❌
padding: EdgeInsets.all(8.0)  // ❌
borderRadius: BorderRadius.circular(8) // ❌

// CORRECT: flutter_screenutil convention
width: 16.w
padding: EdgeInsets.all(8.r)
borderRadius: BorderRadius.circular(8.r)  // 8.r is project standard for border radius
fontSize: 14.sp
height: 48.h
```

Standard border radius for this project: **8.r**.

## Immutability

- Prefer `final` over `var` for all fields and locals
- Use `const` constructors wherever possible
- Use `@immutable` on domain entities and DTOs
- Use `copyWith()` for modified copies:

```dart
@immutable
class UserProfile {
  const UserProfile({required this.name, required this.email});
  final String name;
  final String email;

  UserProfile copyWith({String? name, String? email}) => UserProfile(
    name: name ?? this.name,
    email: email ?? this.email,
  );
}
```

## Naming

Follow [Dart Effective Style](https://dart.dev/effective-dart/style):
- Classes, enums, typedefs: `UpperCamelCase`
- Files, directories, variables, parameters: `snake_case`
- Constants: `lowerCamelCase` (NOT SCREAMING_SNAKE)
- Private members: prefix with `_`
- Controllers: `<FeatureName>Controller` (e.g., `AuthController`, `ProfileController`)
- Use cases: `<Action>UseCase` (e.g., `LoginUseCase`, `GetUserProfileUseCase`)
- Screens: `<FeatureName>Screen` (e.g., `LoginScreen`, `HomeScreen`)

## Widget Conventions

```dart
// Always use super.key and const constructors
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) { ... }
}
```

- One widget class per file; file name matches class in snake_case
- Extract to named classes over private methods (`_buildFoo()`) when reused
- Use `Key` values on all interactive widgets for test targeting
- Keep `build()` methods free of logic — all logic belongs in controller

## Error Handling

```dart
// Use sealed classes for typed error states
sealed class DataState<T> {
  const DataState();
}
class DataLoading<T> extends DataState<T> { const DataLoading(); }
class DataSuccess<T> extends DataState<T> {
  const DataSuccess(this.data);
  final T data;
}
class DataError<T> extends DataState<T> {
  const DataError(this.message);
  final String message;
}
```

- Never use `dynamic` or bare `catch` — catch specific exceptions
- Show user-friendly messages via `locale.xxx` in UI
- Log full context for debugging (never log tokens/passwords)

## Null Safety

- Never use `!` (null bang) unless you have explicit proof the value is non-null
- Prefer `?.`, `??`, `??=` and early returns
- Use `required` for constructor parameters that must be provided
