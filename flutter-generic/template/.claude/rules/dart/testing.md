---
paths:
  - "**/*_test.dart"
  - "**/test/**"
  - "**/integration_test/**"
---
# Dart/Flutter Testing

> This file extends [common/testing.md](../common/testing.md) with Dart/Flutter specific content.

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

## Unit Test Skeleton — State Holder

<!-- ═══════════════════════════════════════════════════════════
  {{STATE_MANAGEMENT}} STATE HOLDER TEST PATTERN
  
  Replace this block with your project's state holder test skeleton.
  
  Riverpod example (AsyncNotifier):
    void main() {
      late ProviderContainer container;
      
      setUp(() {
        container = ProviderContainer(overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ]);
        addTearDown(container.dispose);
      });
      
      test('transitions to authenticated on login success', () async {
        final notifier = container.read(authNotifierProvider.notifier);
        await notifier.login('a@b.com', 'password');
        
        final state = container.read(authNotifierProvider);
        expect(state.value, isA<AuthAuthenticated>());
      });
    }
  
  Bloc / Cubit example:
    void main() {
      late AuthBloc sut;
      late MockLoginUseCase mockLoginUseCase;
      
      setUp(() {
        mockLoginUseCase = MockLoginUseCase();
        sut = AuthBloc(mockLoginUseCase);
      });
      
      tearDown(() => sut.close());
      
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] on login success',
        build: () => sut,
        act: (bloc) => bloc.add(LoginRequested('a@b.com', 'password')),
        expect: () => [const AuthLoading(), isA<AuthAuthenticated>()],
      );
    }
  
  Provider (ChangeNotifier) example:
    void main() {
      late AuthController sut;
      
      setUp(() => sut = AuthController(MockLoginUseCase()));
      
      test('isLoading goes true then false on success', () async {
        final states = <bool>[];
        sut.addListener(() => states.add(sut.isLoading));
        await sut.login('a@b.com', 'password');
        expect(states, [true, false]);
      });
    }
  ═══════════════════════════════════════════════════════════ -->

## Widget Test Skeleton

<!-- ═══════════════════════════════════════════════════════════
  {{STATE_MANAGEMENT}} WIDGET TEST PATTERN
  
  Replace this block with your project's widget test skeleton.
  Note: some state management packages require a specific root widget for tests.
  
  Riverpod example:
    testWidgets('shows error message on auth failure', (tester) async {
      final container = ProviderContainer(overrides: [
        authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
      ]);
      
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const LoginScreen()),
      );
      await tester.pump();
      
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  
  Bloc example:
    testWidgets('calls login on button tap', (tester) async {
      final mockBloc = MockAuthBloc();
      
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: mockBloc,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      
      await tester.tap(find.byKey(const Key('login_button')));
      verify(() => mockBloc.add(any())).called(1);
    });
  
  Provider example:
    testWidgets('shows loading indicator while logging in', (tester) async {
      final mockController = MockAuthController();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthController>.value(
          value: mockController,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  ═══════════════════════════════════════════════════════════ -->

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

## State Management Test Gotchas

<!-- ═══════════════════════════════════════════════════════════
  {{STATE_MANAGEMENT}} TEST GOTCHAS
  
  Add package-specific testing gotchas here.
  
  Riverpod:
    - Always call container.dispose() in tearDown — prevents memory leaks
    - Use ProviderContainer overrides for injecting mocks, not Provider.scope
    - ref.read in tests is fine; ref.watch outside a widget requires a listener
  
  Bloc:
    - Always call bloc.close() in tearDown — closes the stream
    - Use blocTest from bloc_test package for event-to-state assertion
    - Don't use expect() on state stream directly — use blocTest or emitsInOrder
  
  Provider:
    - ChangeNotifier tests: addListener before the action, verify after
    - Don't test navigation calls directly — verify the state changed correctly
  
  GetX:
    - Always call Get.reset() in tearDown — controllers leak between tests
    - Use GetMaterialApp not MaterialApp in widget tests using Get.find()
    - Inject dependencies manually in tests — don't rely on AppPages bindings
  ═══════════════════════════════════════════════════════════ -->

## Reference

See `tdd-workflow` skill for the full RED-GREEN-REFACTOR cycle.
See `flutter-generic-patterns` skill for project-specific widget patterns.
