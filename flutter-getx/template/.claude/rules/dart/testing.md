---
paths:
  - "**/*_test.dart"
  - "**/test/**"
  - "**/integration_test/**"
---
# Dart/Flutter Testing

> This file extends [common/testing.md](../common/testing.md) with Dart/Flutter + GetX specific content.

## Frameworks

| Layer | Framework | Purpose |
|-------|-----------|---------|
| Pure Dart (use cases, entities) | `package:test` | Unit tests, no Flutter dependency |
| Widget layer | `package:flutter_test` | Widget pump, GetX controller tests |
| Integration | `package:integration_test` | Full-app on-device tests |
| Mocking | `package:mocktail` | Null-safe mocking without codegen |

## Test File Structure

Mirror source paths under `test/`:
```
lib/src/features/auth/domain/use_cases/login_use_case.dart
→ test/features/auth/domain/use_cases/login_use_case_test.dart

lib/src/features/auth/presentation/controllers/auth_controller.dart
→ test/features/auth/presentation/controllers/auth_controller_test.dart
```

## Unit Test Skeleton — Use Case

```dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase sut;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    sut = LoginUseCase(mockRepo);
  });

  group('LoginUseCase', () {
    test('returns User on valid credentials', () async {
      when(() => mockRepo.login(any(), any()))
          .thenAnswer((_) async => const User(id: '1', email: 'a@b.com'));

      final result = await sut.execute('a@b.com', 'password');

      expect(result.id, '1');
      verify(() => mockRepo.login('a@b.com', 'password')).called(1);
    });

    test('throws AuthException on invalid credentials', () async {
      when(() => mockRepo.login(any(), any()))
          .thenThrow(const AuthException('Invalid credentials'));

      expect(
        () => sut.execute('a@b.com', 'wrong'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
```

## Unit Test Skeleton — GetxController

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  late AuthController sut;
  late MockLoginUseCase mockLoginUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    sut = AuthController(mockLoginUseCase);
  });

  tearDown(Get.reset);  // ALWAYS reset GetX between tests

  group('AuthController.login', () {
    test('sets isLoading true then false on success', () async {
      when(() => mockLoginUseCase.execute(any(), any()))
          .thenAnswer((_) async => const User(id: '1', email: 'a@b.com'));

      final loadingStates = <bool>[];
      ever(sut.isLoading, loadingStates.add);

      await sut.login('a@b.com', 'password');

      expect(loadingStates, [true, false]);
      expect(sut.errorMessage.value, isEmpty);
    });

    test('sets errorMessage on failure', () async {
      when(() => mockLoginUseCase.execute(any(), any()))
          .thenThrow(Exception('Network error'));

      await sut.login('a@b.com', 'password');

      expect(sut.errorMessage.value, isNotEmpty);
      expect(sut.isLoading.value, isFalse);
    });
  });
}
```

## Widget Test Skeleton

Use `GetMaterialApp` instead of `MaterialApp` for tests involving GetX:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthController extends GetxController with Mock implements AuthController {}

void main() {
  late MockAuthController mockController;

  setUp(() {
    mockController = MockAuthController();
    Get.put<AuthController>(mockController);
  });

  tearDown(Get.reset);

  testWidgets('shows error message when errorMessage is set', (tester) async {
    mockController.errorMessage.value = 'Invalid credentials';

    await tester.pumpWidget(
      const GetMaterialApp(home: LoginScreen()),
    );
    await tester.pump();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  testWidgets('calls login on button tap', (tester) async {
    when(() => mockController.login(any(), any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      const GetMaterialApp(home: LoginScreen()),
    );

    await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'pass');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    verify(() => mockController.login('a@b.com', 'pass')).called(1);
  });
}
```

## Running Tests

```bash
flutter test                                    # all unit + widget tests
flutter test --coverage                         # with coverage report
flutter test test/features/auth/                # single feature
flutter test --name "LoginUseCase"              # filter by name
flutter test --reporter expanded                # verbose output
genhtml coverage/lcov.info -o coverage/html     # HTML coverage report
flutter test integration_test/                  # integration tests (device required)
flutter analyze                                 # static analysis
```

## Coverage Requirements

Minimum **80%** line coverage overall:
- `domain/use_cases/` — **100%** (pure Dart, fully testable)
- `domain/entities/` — **100%** (test copyWith, equality)
- `data/repositories/` — **80%+** (mock datasource)
- `presentation/controllers/` — **80%+** (mock use cases)
- `presentation/screens/` + `widgets/` — **60%+** (widget tests for key interactions)

## GetX Test Gotchas

- **Always call `Get.reset()` in `tearDown`** — otherwise controllers leak between tests
- **Use `GetMaterialApp` not `MaterialApp`** in widget tests using `Get.find()`
- **Use `ever(controller.obs, callback)` to track observable changes** over time
- **Don't test `Get.toNamed()` directly** — verify the controller called the use case
- **Inject dependencies manually in tests** — don't rely on AppPages bindings

## Reference

See `tdd-workflow` skill for the full RED-GREEN-REFACTOR cycle.
See `flutter-cloner-patterns` skill for project-specific widget patterns.
