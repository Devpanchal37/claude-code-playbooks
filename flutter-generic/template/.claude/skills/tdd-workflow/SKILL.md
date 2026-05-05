---
name: tdd-workflow
description: Use this skill when writing new Flutter/Dart features, fixing bugs, or refactoring. Enforces test-driven development with 80%+ coverage including use case tests, controller tests, and widget tests.
origin: project-conventions
---

# Test-Driven Development Workflow — Flutter/GetX

This skill ensures all Flutter/Dart code follows TDD principles with GetX Clean Architecture.

## When to Activate

- Writing new features (use case → controller → screen)
- Fixing bugs (write failing test that reproduces bug first)
- Refactoring existing code (tests protect against regressions)
- Adding new API integrations (mock at repository level)

## Core Principles

### 1. Domain First — Tests First
Always start with the domain layer (use case). It's pure Dart and easiest to test.

```
1. Write use case test (FAILS)
2. Write use case implementation (PASSES)
3. Write controller test (FAILS)
4. Write controller implementation (PASSES)
5. Write widget test (FAILS)
6. Write screen implementation (PASSES)
```

### 2. Coverage Requirements
- `domain/use_cases/` — **100%**
- `presentation/controllers/` — **80%+**
- `presentation/screens/` + `widgets/` — **60%+**
- Overall minimum — **80%**

## TDD Workflow Steps

### Step 1: Write Use Case Test (RED)

```dart
// test/features/auth/domain/use_cases/login_use_case_test.dart
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase sut;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    sut = LoginUseCase(mockRepo);
  });

  test('FAILS — LoginUseCase not implemented yet', () async {
    when(() => mockRepo.login(any(), any()))
        .thenAnswer((_) async => const User(id: '1', email: 'a@b.com'));

    final result = await sut.execute('a@b.com', 'password');
    expect(result.id, '1');
  });
}
```

### Step 2: Run Test — Verify FAILS
```bash
flutter test test/features/auth/domain/use_cases/login_use_case_test.dart
# Expected: FAIL (LoginUseCase doesn't exist yet)
```

### Step 3: Write Minimal Use Case (GREEN)

```dart
// lib/src/features/auth/domain/use_cases/login_use_case.dart
class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<User> execute(String email, String password) =>
      _repository.login(email, password);
}
```

### Step 4: Run — Verify PASSES
```bash
flutter test test/features/auth/domain/use_cases/login_use_case_test.dart
# Expected: PASS
```

### Step 5: Write Controller Test (RED)

```dart
// test/features/auth/presentation/controllers/auth_controller_test.dart
class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  late AuthController sut;
  late MockLoginUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockLoginUseCase();
    sut = AuthController(mockUseCase);
  });

  tearDown(Get.reset);

  test('sets isLoading true then false on success', () async {
    when(() => mockUseCase.execute(any(), any()))
        .thenAnswer((_) async => const User(id: '1', email: 'a@b.com'));

    final loadingStates = <bool>[];
    ever(sut.isLoading, loadingStates.add);

    await sut.login('a@b.com', 'password');

    expect(loadingStates, [true, false]);
    expect(sut.errorMessage.value, isEmpty);
  });

  test('sets errorMessage on failure', () async {
    when(() => mockUseCase.execute(any(), any()))
        .thenThrow(Exception('Network error'));

    await sut.login('a@b.com', 'password');

    expect(sut.errorMessage.value, isNotEmpty);
    expect(sut.isLoading.value, isFalse);
  });
}
```

### Step 6: Write Controller (GREEN)

```dart
// lib/src/features/auth/presentation/controllers/auth_controller.dart
class AuthController extends GetxController {
  AuthController(this._loginUseCase);
  final LoginUseCase _loginUseCase;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _loginUseCase.execute(email, password);
      Get.offAllNamed(Routes.home);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
```

### Step 7: Write Widget Test (RED)

```dart
// test/features/auth/presentation/screens/login_screen_test.dart
class MockAuthController extends GetxController
    with Mock implements AuthController {}

void main() {
  late MockAuthController mockController;

  setUp(() {
    mockController = MockAuthController();
    Get.put<AuthController>(mockController);
  });

  tearDown(Get.reset);

  testWidgets('shows error when errorMessage set', (tester) async {
    mockController.errorMessage.value = 'Invalid credentials';

    await tester.pumpWidget(const GetMaterialApp(home: LoginScreen()));
    await tester.pump();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('calls login on button tap', (tester) async {
    when(() => mockController.login(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(const GetMaterialApp(home: LoginScreen()));

    await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'pass');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    verify(() => mockController.login('a@b.com', 'pass')).called(1);
  });
}
```

### Step 8: Write Screen (GREEN)

```dart
// lib/src/features/auth/presentation/screens/login_screen.dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    return Scaffold(
      key: const Key('login_screen'),
      body: Obx(() => Column(
        children: [
          TextField(key: const Key('email_field'), ...),
          TextField(key: const Key('password_field'), ...),
          if (c.errorMessage.value.isNotEmpty)
            Text(c.errorMessage.value),
          AppButton(
            key: const Key('login_button'),
            label: locale.login,
            isLoading: c.isLoading.value,
            onPressed: () => c.login(emailController.text, passwordController.text),
          ),
        ],
      )),
    );
  }
}
```

### Step 9: Verify Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
# Target: 80%+ overall, 100% for use_cases/
```

## Test Anti-Patterns to Avoid

```dart
// BAD: Testing Get.toNamed() directly
verify(() => Get.toNamed(Routes.home)).called(1); // Don't do this

// GOOD: Test that use case was called
verify(() => mockLoginUseCase.execute(any(), any())).called(1);
```

```dart
// BAD: Forgetting Get.reset()
tearDown(() {}); // leaks controller to next test

// GOOD:
tearDown(Get.reset);
```

```dart
// BAD: Using MaterialApp in tests with GetX
await tester.pumpWidget(MaterialApp(home: LoginScreen())); // Get.find fails

// GOOD:
await tester.pumpWidget(GetMaterialApp(home: LoginScreen()));
```

## Commands Reference

```bash
flutter test                                 # run all tests
flutter test test/features/auth/             # single feature
flutter test --coverage                      # with coverage report
flutter test --name "LoginUseCase"           # filter by name
flutter test --reporter expanded             # verbose output
dart run build_runner build \
  --delete-conflicting-outputs               # regenerate mocks (if using mockito)
```

## TDD Cycle Summary

```
RED   → Write failing test
GREEN → Write minimal code to pass
REFACTOR → Improve while keeping green
REPEAT per layer: use case → controller → widget
```
