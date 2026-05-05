---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---
# Dart/Flutter Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Dart/Flutter + GetX specific content.

## Formatting

- **dart format** for auto-formatting (enforced by CI)
- **flutter analyze** for static analysis
- **dart fix --apply** for auto-fixable lint issues
- Linting: extend `package:flutter_lints/flutter.yaml` in `analysis_options.yaml`

## State Management: GetX ONLY

**CRITICAL**: This project uses GetX exclusively.

```dart
// BANNED: setState for feature state
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  void login() => setState(() => isLoading = true); // ❌ BANNED
}

// BANNED: Riverpod
final userProvider = StateProvider<User>(...); // ❌ BANNED

// BANNED: Bloc
class LoginBloc extends Bloc<LoginEvent, LoginState> {...} // ❌ BANNED

// CORRECT: GetX controller
class LoginController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      await _loginUseCase.execute(email, password);
      Get.toNamed(Routes.home);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}

// CORRECT: StatelessWidget + Obx
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();
    return Obx(() => c.isLoading.value
      ? const CircularProgressIndicator()
      : LoginForm(onSubmit: c.login),
    );
  }
}
```

`StatefulWidget` is allowed ONLY for purely local UI state that never needs testing (e.g., animation controllers, focus nodes).

## Navigation: Routes.xxx ONLY

```dart
// BANNED: hardcoded strings
Get.toNamed('/home');          // ❌
Get.toNamed('/profile/edit'); // ❌

// CORRECT: Routes constants
Get.toNamed(Routes.home);
Get.toNamed(Routes.profileEdit, arguments: user);
Get.offAllNamed(Routes.login);
Get.back();
```

All route paths are defined as `static const` in `lib/src/core/routes/routes.dart`.

## Strings/Localization: locale.xxx ONLY

```dart
// BANNED: hardcoded display strings
Text('Welcome back');          // ❌
Text('Email is required');     // ❌
SnackBar(content: Text('Error occurred')); // ❌

// CORRECT: locale keys
Text(locale.welcomeBack);
Text(locale.emailRequired);
```

`locale` is the GetX translation accessor. All user-visible strings must go through it.

## Colors: ColorHelper.xxx ONLY

```dart
// BANNED: hardcoded colors
color: const Color(0xFF1A73E8)  // ❌
color: Colors.blue              // ❌ (unless for testing)
backgroundColor: Color(0xFFF5F5F5) // ❌

// CORRECT
color: ColorHelper.primary
color: ColorHelper.background
color: ColorHelper.error
```

## Text Styles: TextStyleHelper.xxx ONLY

```dart
// BANNED: hardcoded text styles
style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold) // ❌

// CORRECT
style: TextStyleHelper.heading1
style: TextStyleHelper.bodyRegular
style: TextStyleHelper.labelSmall
```

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
