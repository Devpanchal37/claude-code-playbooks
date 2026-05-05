---
paths:
  - "**/*.dart"
---
# Dart/Flutter Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Dart/Flutter + GetX + Clean Architecture specific content.

## Feature Architecture

Organize each feature as a self-contained Clean Architecture module:

```
lib/src/features/<feature>/
├── data/
│   ├── datasources/        # Remote API (Dio), Local (Hive/SharedPrefs)
│   ├── models/             # JSON-serializable DTOs (fromJson/toJson + toDomain())
│   └── repositories/       # Concrete implementations of domain interfaces
├── domain/
│   ├── entities/           # Pure Dart business objects (@immutable, no Flutter imports)
│   ├── repositories/       # Abstract interfaces (no implementation)
│   └── use_cases/          # Single-responsibility business logic (one execute() each)
└── presentation/
    ├── screens/            # Full-page widgets (GetX route targets)
    ├── widgets/            # Feature-scoped reusable widgets
    └── controllers/        # GetxController subclasses (one per screen)
```

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

## State Management: GetX Controller

One controller per screen:

```dart
// presentation/controllers/auth_controller.dart
class AuthController extends GetxController {
  AuthController(this._loginUseCase);
  final LoginUseCase _loginUseCase;

  // Observable state — use .obs
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final currentUser = Rxn<User>();  // nullable observable

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final user = await _loginUseCase.execute(email, password);
      currentUser.value = user;
      Get.offAllNamed(Routes.home);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
```

Reactive UI via `Obx`:

```dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AuthController>();
    return Scaffold(
      key: const Key('login_screen'),
      body: Obx(() => c.isLoading.value
        ? const Center(child: CircularProgressIndicator())
        : LoginForm(
            errorMessage: c.errorMessage.value,
            onSubmit: c.login,
          ),
      ),
    );
  }
}
```

## Navigation: GetX Routing

```dart
// lib/src/core/routes/routes.dart
abstract class Routes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
}

// lib/src/core/routes/app_pages.dart
abstract class AppPages {
  static final pages = [
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl(Get.find()));
        Get.lazyPut<LoginUseCase>(() => LoginUseCase(Get.find()));
        Get.lazyPut<AuthController>(() => AuthController(Get.find()));
      }),
    ),
  ];
}

// Navigation in widgets and controllers
Get.toNamed(Routes.home);
Get.offAllNamed(Routes.login);
Get.toNamed(Routes.profileEdit, arguments: user);
Get.back();
```

## Dependency Injection: GetX

```dart
// Global/app-level deps (in main.dart or initial binding)
Get.put<DioClient>(DioClient());  // eager

// Feature-level deps (in GetPage binding)
Get.lazyPut<AuthRepository>(() => AuthRepositoryImpl(Get.find<DioClient>()));
Get.lazyPut<LoginUseCase>(() => LoginUseCase(Get.find<AuthRepository>()));
Get.lazyPut<AuthController>(() => AuthController(Get.find<LoginUseCase>()));

// Access anywhere
final controller = Get.find<AuthController>();
```

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
