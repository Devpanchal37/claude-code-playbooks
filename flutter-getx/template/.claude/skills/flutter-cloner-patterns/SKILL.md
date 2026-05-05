---
name: flutter-cloner-patterns
description: Flutter/GetX coding patterns, conventions, and Clean Architecture workflows. Reference for controllers, routing, testing, and project structure.
version: 2.0.0
source: project-conventions
---

# Flutter/GetX Clean Architecture Patterns

## Stack

- **Flutter** — UI framework (Material Design / Cupertino)
- **GetX** — State management, navigation, DI, localization
- **Dio** — HTTP client for Laravel REST API
- **flutter_screenutil** — Responsive sizing (`.r`, `.w`, `.h`, `.sp`)
- **flutter_secure_storage** — Secure credential storage
- **mocktail** — Mocking in tests (no codegen required)

## Project Structure

```
lib/
├── main.dart                        # App entry, GetX initialization
├── src/
│   ├── core/
│   │   ├── theme/
│   │   │   ├── color_helper.dart    # All app colors
│   │   │   ├── text_style_helper.dart  # All text styles
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   ├── size_utils.dart      # Responsive sizing helpers
│   │   │   └── validators.dart
│   │   ├── network/
│   │   │   ├── dio_client.dart      # Dio setup, interceptors
│   │   │   └── api_constants.dart   # Base URL, endpoints
│   │   └── routes/
│   │       ├── routes.dart          # Route name constants
│   │       └── app_pages.dart       # GetPage list + bindings
│   ├── shared/
│   │   └── widgets/                 # AppButton, AppTextField, etc.
│   └── features/
│       └── <feature_name>/
│           ├── data/
│           │   ├── datasources/
│           │   ├── models/          # DTOs with fromJson/toJson/toDomain
│           │   └── repositories/    # Concrete implementations
│           ├── domain/
│           │   ├── entities/        # @immutable pure Dart
│           │   ├── repositories/    # Abstract interfaces
│           │   └── use_cases/       # One execute() per use case
│           └── presentation/
│               ├── screens/         # Route target widgets
│               ├── widgets/         # Feature-specific widgets
│               └── controllers/     # GetxController subclasses
```

## Core Conventions

### MUST-DO
- State management: **GetX ONLY** — no setState for feature state, no Riverpod, no Bloc
- Navigation: `Get.toNamed(Routes.xxx)` — never hardcode strings
- Display strings: `locale.xxx` — never hardcode UI text
- Colors: `ColorHelper.xxx`
- Text styles: `TextStyleHelper.xxx`
- Sizing: `16.w`, `8.r`, `14.sp`, `48.h` (flutter_screenutil)
- Standard border radius: **`8.r`**

### File Naming
- All files: `snake_case.dart`
- Controllers: `<feature>_controller.dart`
- Screens: `<feature>_screen.dart`
- Use cases: `<action>_use_case.dart`
- DTOs: `<entity>_model.dart`
- Tests mirror source: `test/features/<feature>/...`

## GetX Controller Pattern

```dart
class HomeController extends GetxController {
  HomeController(this._getPostsUseCase);
  final GetPostsUseCase _getPostsUseCase;

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final posts = <Post>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  Future<void> loadPosts() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      posts.value = await _getPostsUseCase.execute();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
```

## Screen Widget Pattern

```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Scaffold(
      key: const Key('home_screen'),
      appBar: AppBar(title: Text(locale.home)),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.errorMessage.value.isNotEmpty) {
          return Center(child: Text(c.errorMessage.value));
        }
        return ListView.builder(
          itemCount: c.posts.length,
          itemBuilder: (context, i) => PostCard(post: c.posts[i]),
        );
      }),
    );
  }
}
```

## Route Registration

```dart
// routes.dart
abstract class Routes {
  static const home = '/home';
  static const postDetail = '/home/post-detail';
}

// app_pages.dart
GetPage(
  name: Routes.home,
  page: () => const HomeScreen(),
  binding: BindingsBuilder(() {
    Get.lazyPut<PostRepository>(() => PostRepositoryImpl(Get.find()));
    Get.lazyPut<GetPostsUseCase>(() => GetPostsUseCase(Get.find()));
    Get.lazyPut<HomeController>(() => HomeController(Get.find()));
  }),
),
```

## Shared Widget Pattern

```dart
// shared/widgets/app_button.dart
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
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorHelper.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20.r,
                width: 20.r,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, style: TextStyleHelper.buttonLabel),
      ),
    );
  }
}
```

## Testing Patterns

```dart
// Controller unit test
class MockGetPostsUseCase extends Mock implements GetPostsUseCase {}

void main() {
  late HomeController sut;
  late MockGetPostsUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetPostsUseCase();
    sut = HomeController(mockUseCase);
  });

  tearDown(Get.reset);

  test('loads posts on onInit', () async {
    final fakePosts = [const Post(id: '1', title: 'Test')];
    when(() => mockUseCase.execute()).thenAnswer((_) async => fakePosts);

    sut.onInit();
    await Future.delayed(Duration.zero);

    expect(sut.posts, fakePosts);
    expect(sut.isLoading.value, false);
  });
}
```

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

# Codegen (if using freezed/json_serializable)
dart run build_runner build --delete-conflicting-outputs
```

## When to Use ECC Agents

- `/plan` — before starting any new feature
- `/tdd` — test-first widget/unit development
- `/code-review` — before marking a feature done
- `/refactor-clean` — when a file exceeds ~400 lines or has duplication
- `/build-fix` — when `flutter analyze` or `flutter test` fails
- `/verify` — before committing or creating a PR
