---
paths:
  - "**/*.dart"
---
# Dart/Flutter Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Dart/Flutter `{{ARCHITECTURE}}` specific content.

## Feature Architecture

<!-- ═══════════════════════════════════════════════════════════
  Replace this block with your project's feature folder layout.
  Must match {{ARCHITECTURE}} chosen in TEMPLATE_SETUP.md.

  Example A: Clean Architecture
    lib/src/features/<feature>/
    ├── data/
    │   ├── datasources/        # Remote API (Dio), Local (Hive/SharedPrefs)
    │   ├── models/             # JSON DTOs (fromJson/toJson + toDomain())
    │   └── repositories/       # Concrete implementations of domain interfaces
    ├── domain/
    │   ├── entities/           # Pure Dart business objects (@immutable, no Flutter imports)
    │   ├── repositories/       # Abstract interfaces (no implementation)
    │   └── use_cases/          # Single-responsibility logic (one execute() each)
    └── presentation/
        ├── screens/            # Full-page widgets (route targets)
        ├── widgets/            # Feature-scoped reusable widgets
        └── controllers/        # State holders — one per screen ({{STATE_MANAGEMENT}})

  Example B: MVVM
    lib/src/features/<feature>/
    ├── model/                  # Data classes + repository
    ├── viewmodel/              # {{STATE_MANAGEMENT}} state holders
    └── view/                   # Screens and feature widgets

  Example C: Simple layered
    lib/src/features/<feature>/
    ├── services/               # Business logic + API calls
    ├── controllers/            # {{STATE_MANAGEMENT}} state holders
    └── screens/                # UI only
  ═══════════════════════════════════════════════════════════ -->

## Repository Pattern

```dart
// 1. Abstract interface in domain/repositories/
abstract interface class AuthRepository {
  Future<User> login(String email, String password);
  Future<void> logout();
}

// 2. Concrete implementation in data/repositories/
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);
  final AuthRemoteDatasource _remote;

  @override
  Future<User> login(String email, String password) async {
    final dto = await _remote.login(email, password);
    return dto.toDomain();
  }

  @override
  Future<void> logout() => _remote.logout();
}

// 3. Fake for tests
class FakeAuthRepository implements AuthRepository {
  @override
  Future<User> login(String email, String password) async =>
      User(id: '1', email: email, name: 'Test User');
  @override
  Future<void> logout() async {}
}
```

## Use Case Pattern

One use case = one business action = one `execute()` method:

```dart
// domain/use_cases/login_use_case.dart
class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<User> execute(String email, String password) =>
      _repository.login(email, password);
}
```

## State Management

<!-- ═══════════════════════════════════════════════════════════
  {{STATE_MANAGEMENT}} STATE HOLDER PATTERN
  
  Add your state holder code pattern here (one per screen).
  
  Riverpod example:
    class AuthNotifier extends AsyncNotifier<AuthState> {
      @override
      Future<AuthState> build() async => const AuthState.initial();
      
      Future<void> login(String email, String password) async {
        state = const AsyncValue.loading();
        state = await AsyncValue.guard(() async {
          final user = await ref.read(authRepositoryProvider).login(email, password);
          return AuthState.authenticated(user);
        });
      }
    }
    
    // Widget:
    class LoginScreen extends ConsumerWidget {
      @override
      Widget build(BuildContext context, WidgetRef ref) {
        final authState = ref.watch(authNotifierProvider);
        return authState.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => ErrorWidget(e.toString()),
          data: (state) => LoginForm(onSubmit: ref.read(authNotifierProvider.notifier).login),
        );
      }
    }
  
  Bloc example:
    class AuthBloc extends Bloc<AuthEvent, AuthState> {
      AuthBloc(this._loginUseCase) : super(const AuthInitial()) {
        on<LoginRequested>(_onLoginRequested);
      }
      
      Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
        emit(const AuthLoading());
        try {
          final user = await _loginUseCase.execute(event.email, event.password);
          emit(AuthAuthenticated(user));
        } catch (e) {
          emit(AuthError(e.toString()));
        }
      }
    }
    
    // Widget:
    BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => switch (state) {
        AuthLoading() => const CircularProgressIndicator(),
        AuthError(:final message) => ErrorWidget(message),
        AuthAuthenticated(:final user) => HomeView(user: user),
        _ => LoginForm(onSubmit: (e, p) => context.read<AuthBloc>().add(LoginRequested(e, p))),
      },
    )
  ═══════════════════════════════════════════════════════════ -->

## Navigation: Route Constants

<!-- ═══════════════════════════════════════════════════════════
  {{ROUTING_SOLUTION}} ROUTING PATTERN
  
  Add your routing setup here.
  
  GoRouter example:
    // lib/src/core/routes/app_routes.dart
    abstract class AppRoutes {
      static const splash = '/';
      static const login = '/login';
      static const home = '/home';
    }
    
    // lib/src/core/routes/app_router.dart
    final appRouter = GoRouter(
      routes: [
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      ],
    );
    
    // Navigate in widgets:
    context.go(AppRoutes.home);
    context.push(AppRoutes.profile, extra: user);
    context.pop();
  
  auto_route example:
    @AutoRouterConfig()
    class AppRouter extends RootStackRouter { ... }
    
    // Navigate:
    context.router.push(const HomeRoute());
    context.router.replace(const LoginRoute());
  ═══════════════════════════════════════════════════════════ -->

## Dependency Injection

<!-- ═══════════════════════════════════════════════════════════
  {{DI_SOLUTION}} DEPENDENCY INJECTION PATTERN
  
  Add your DI setup here.
  
  get_it + injectable example:
    // lib/src/core/di/injection.dart
    @InjectableInit()
    void configureDependencies() => getIt.init();
    
    @injectable
    class AuthRepositoryImpl implements AuthRepository {
      AuthRepositoryImpl(this._remote);
      final AuthRemoteDatasource _remote;
    }
    
    // Access:
    final repo = getIt<AuthRepository>();
  
  Riverpod example:
    final authRepositoryProvider = Provider<AuthRepository>((ref) {
      return AuthRepositoryImpl(ref.read(httpClientProvider));
    });
    
    final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
      return LoginUseCase(ref.read(authRepositoryProvider));
    });
  ═══════════════════════════════════════════════════════════ -->

## Data Transfer Objects (DTOs)

```dart
// data/models/user_model.dart — serialization lives here
@immutable
class UserModel {
  const UserModel({required this.id, required this.email, required this.name});
  final String id;
  final String email;
  final String name;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};

  User toDomain() => User(id: id, email: email, name: name);
}

// domain/entities/user.dart — NO fromJson, pure Dart
@immutable
class User {
  const User({required this.id, required this.email, required this.name});
  final String id;
  final String email;
  final String name;

  User copyWith({String? id, String? email, String? name}) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    name: name ?? this.name,
  );
}
```

## Remote Datasource Pattern

```dart
// data/datasources/auth_remote_datasource.dart
abstract interface class AuthRemoteDatasource {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  const AuthRemoteDatasourceImpl(this._client);
  final DioClient _client;

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
```

## Sealed Classes for State

```dart
sealed class AuthState {
  const AuthState();
}
class AuthInitial extends AuthState { const AuthInitial(); }
class AuthLoading extends AuthState { const AuthLoading(); }
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}
class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
```

## Extension Methods

```dart
extension StringValidation on String {
  bool get isValidEmail => RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(this);
  bool get isNotBlank => trim().isNotEmpty;
}
```
