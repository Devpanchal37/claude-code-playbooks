---
description: Enforce TDD workflow for Flutter/Dart. Write use case tests FIRST, then controller tests, then widget tests. RED → GREEN → REFACTOR. 80%+ coverage.
---

# TDD Command — Flutter/GetX

This command invokes the **tdd-guide** agent to enforce test-driven development for Flutter features.

## What This Command Does

1. **Write use case test** (domain layer, RED)
2. **Implement use case** (GREEN)
3. **Write controller test** (presentation layer, RED)
4. **Implement controller** (GREEN)
5. **Write widget test** (RED)
6. **Implement screen/widget** (GREEN)
7. **Refactor** while keeping all tests green
8. **Verify coverage** — 80%+ overall, 100% for use cases

## When to Use

Use `/tdd` when:
- Implementing a new feature (start with use case)
- Fixing a bug (write failing test that reproduces the bug first)
- Adding a new screen (write widget test before building it)
- Refactoring existing code (tests protect against regressions)

## TDD Layer Order

```
1. domain/use_cases/<action>_use_case_test.dart   ← Start here
2. presentation/controllers/<name>_controller_test.dart
3. presentation/screens/<name>_screen_test.dart
```

## TDD Cycle

```
RED      → Write failing test
GREEN    → Write minimal code to pass
REFACTOR → Improve code, keep tests passing
REPEAT   → Next layer / next scenario
```

## Example: Login Feature

### Step 1: Use Case Test (RED)
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

  test('returns User on valid credentials', () async {
    when(() => mockRepo.login(any(), any()))
        .thenAnswer((_) async => const User(id: '1', email: 'a@b.com'));

    final result = await sut.execute('a@b.com', 'password');
    expect(result.id, '1');
  });
}
```

### Step 2: Run Tests — Verify FAIL
```bash
flutter test test/features/auth/domain/use_cases/login_use_case_test.dart
# FAIL: LoginUseCase not implemented
```

### Step 3: Implement Use Case (GREEN)
```dart
// lib/src/features/auth/domain/use_cases/login_use_case.dart
class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<User> execute(String email, String password) =>
      _repository.login(email, password);
}
```

### Step 4: Run Tests — Verify PASS
```bash
flutter test test/features/auth/domain/use_cases/login_use_case_test.dart
# PASS
```

### Step 5: Controller Test (RED) → Implement (GREEN)
```dart
// test/features/auth/presentation/controllers/auth_controller_test.dart
class MockLoginUseCase extends Mock implements LoginUseCase {}

test('sets isLoading true then false on success', () async {
  when(() => mockUseCase.execute(any(), any()))
      .thenAnswer((_) async => const User(id: '1', email: 'a@b.com'));

  final loadingStates = <bool>[];
  ever(sut.isLoading, loadingStates.add);
  await sut.login('a@b.com', 'password');

  expect(loadingStates, [true, false]);
});
```

### Step 6: Check Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
# Target: 100% for use cases, 80%+ overall
```

## Key Rules

- **NEVER** skip the RED phase — run the test and verify it fails before implementing
- **NEVER** write more code than needed to make the test pass
- **ALWAYS** call `Get.reset()` in `tearDown` for GetX controller tests
- **USE** `GetMaterialApp` not `MaterialApp` in widget tests with GetX
- **MOCK** at the boundary (mock use cases in controller tests, mock controllers in widget tests)

## Related

- Use `/plan` first to understand the feature structure
- Use `/build-fix` if compilation errors occur during testing
- Use `/code-review` after all tests pass

## Related Agents & Skills

This command invokes the `tdd-guide` agent.
Reference skill: `tdd-workflow`
