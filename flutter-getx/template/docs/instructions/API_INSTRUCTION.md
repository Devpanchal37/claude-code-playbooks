# {{APP_NAME}} — API & LOGIC IMPLEMENTATION RULES

> **Single source of truth for implementing API, business logic,
> controllers, and async flows in the {{APP_NAME}} Flutter project.
> Follow strictly.**

------------------------------------------------------------------------

## 1. Before Writing Any Code (MANDATORY)

-   First **understand and confirm** what the user wants.
-   If anything is unclear → **ask questions first**.
-   Suggest **better / cleaner / more scalable** approaches if applicable.
-   Only write code **after requirements are clear**.

------------------------------------------------------------------------

## 2. Core Quality Rules

All code must:

-   Compile and run in Flutter
-   Follow project helpers: `ColorHelper`, `TextStyleHelper`, `SizeUtils`, etc.
-   Be null-safe and type-safe
-   Handle:
    -   Loading states
    -   Empty states
    -   Error states
    -   Edge cases (no data, API fail, validation fail)
-   Use **clean structure** (controllers / screens / models / services)
-   Avoid hardcoding values and strings

------------------------------------------------------------------------

## 3. Project Folder Structure (MANDATORY)

Every feature lives under:

```
lib/src/features/<feature_name>/
  data/
    data_sources/       ← API calls (service layer)
    models/             ← JSON models with fromJson/toJson
    repositories/       ← Repository implementation
  domain/
    entities/           ← Pure Dart entities (no JSON)
    repositories/       ← Abstract repository contracts
  presentation/
    bindings/           ← GetX Bindings (dependency injection)
    controllers/        ← GetX Controllers (state + logic)
    screens/            ← Full screens / views
    widgets/            ← Feature-specific widgets / components
```

Shared/reusable code lives under:

```
lib/src/shared/widgets/    ← Common widgets used across features
lib/src/shared/models/     ← Shared response models
lib/src/theme/             ← ColorHelper, TextStyleHelper, AppTheme
lib/src/core/network/      ← ApiService, ApiConfig (endpoints)
lib/src/core/constants/    ← ImageHelper, StringHelper
lib/src/core/local_storage/ ← HiveUtils, HiveKeys
lib/src/core/env/          ← Env (obfuscated secrets)
lib/src/core/utils/        ← SizeUtils, extensions
lib/src/locale/            ← BaseLanguage, LanguageEn, AppLocalizations
```

------------------------------------------------------------------------

## 4. Routing & Navigation Rules (MANDATORY)

### File Locations

```
lib/src/core/router/
  app_routes.dart     ← All route name constants
  app_pages.dart      ← GetPage list + imports all bindings & views
```

### app_routes.dart Pattern

```dart
part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const splash  = '/splash';
  static const login   = '/login';
  static const home    = '/home';
  // add new routes here
}
```

### app_pages.dart Pattern

```dart
import 'package:get/get.dart';
import '../features/auth/presentation/bindings/login_binding.dart';
import '../features/auth/presentation/screens/login_screen.dart';
// ... all other imports

part 'app_routes.dart';

class AppPages {
  AppPages._();
  static const initialRoute = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    // add new GetPage entries here
  ];
}
```

### Navigation Rules

-   ✅ Always use `Get.toNamed(Routes.routeName)`
-   ✅ Use `Get.offAllNamed(Routes.routeName)` to clear back-stack
-   ✅ Use `Get.offNamed(Routes.routeName)` to replace current
-   ✅ Pass arguments via `arguments: {}` map, read with `Get.arguments`
-   ❌ Never use `Navigator.push` or `Navigator.pushNamed`
-   ❌ Never hardcode route strings — always use `Routes.xxx`

------------------------------------------------------------------------

## 5. Binding Rules (MANDATORY)

Every feature that has a route **must have a Binding**.

### Binding File Pattern

```dart
// lib/src/features/auth/presentation/bindings/login_binding.dart

import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
```

**Rules:**
-   Use `Get.lazyPut<T>()` — creates the controller only when the screen is first accessed
-   If a controller is needed across multiple screens, use `Get.lazyPut<T>(() => ..., fenix: true)`
-   Declare the binding in `app_pages.dart` on the `GetPage`
-   ❌ Never instantiate controllers directly in views (`LoginController()`)

------------------------------------------------------------------------

## 6. Standard Controller Pattern (MANDATORY)

```dart
// lib/src/features/auth/presentation/controllers/login_controller.dart

class LoginController extends GetxController {
  // ── Form ──────────────────────────────────────
  final formKey = GlobalKey<FormState>(debugLabel: 'login_form_key');
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ── State ─────────────────────────────────────
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  // ── Lifecycle ─────────────────────────────────
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // ── Actions ───────────────────────────────────
  Future<void> onLoginTap() async {
    if (!formKey.currentState!.validate()) return;
    if (isLoading.value) return;

    errorMessage.value = '';
    isLoading.value = true;

    try {
      // call service / repository
      Get.offAllNamed(Routes.home);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMessage.value = msg;
      ShowToast.toast(
        title: locale.errorText,
        subTitle: msg.isNotEmpty ? msg : locale.somethingWentWrongText,
        toastType: ToastType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
```

Every controller must:

-   Have `RxBool isLoading` and `RxString errorMessage`
-   Use `try / catch / finally` with loading reset in `finally`
-   Dispose all `TextEditingController` and `FocusNode` in `onClose()`
-   Validate forms **before** API calls
-   Clear `errorMessage` before a new request

------------------------------------------------------------------------

## 7. API Endpoint Rule (MANDATORY)

-   **Every API endpoint MUST be added to:**

        lib/src/core/network/api_configs.dart

-   **NEVER** hardcode endpoint strings in services.
-   Always use:

    ```dart
    ApiConfig.yourEndpointName
    ```

------------------------------------------------------------------------

## 8. ApiService Usage Rules

-   Use only `ApiService` methods: `get`, `post`, `put`, `patch`, `delete`, `uploadImage`
-   Auth token injection is handled centrally — do not add it per-call
-   Always parse response into a model immediately
-   Always reference endpoints via `ApiConfig.xxx`

------------------------------------------------------------------------

## 9. Localization Rule (MANDATORY)

-   **ALL user-facing text MUST use localization keys**
-   If a key does not exist:
    1.  Add getter to `lib/src/locale/languages.dart`
    2.  Implement it in `lib/src/locale/languages_en.dart`
-   Naming: camelCase, must end with `Text` — e.g. `noItemsFoundText`, `errorText`

❌ Never write:
```dart
Text("No items found")
```

✅ Always write:
```dart
Text(locale.noItemsFoundText)
```

------------------------------------------------------------------------

## 10. Toast & User Feedback (MANDATORY)

-   Use: `ShowToast.toast(...)`
-   For: Success, Error, Info
-   Titles and messages must be localized

------------------------------------------------------------------------

## 11. Button Loader Rule (MANDATORY)

Whenever a button triggers async/API work:

-   Use `CommonButton(showLoading: ...)`
-   Wrap button in `Obx()`
-   Set `isLoading.value = true` before API
-   Always reset in `finally { isLoading.value = false; }`
-   Clear `errorMessage.value = ''` before new request

------------------------------------------------------------------------

## 12. Loading / Error / Empty / Success State Rules

### State Order in UI

1.  Loading (show shimmer)
2.  Error (if failed and no data)
3.  Empty (if success but no data)
4.  Success (show data)

### Shimmer Rules

-   ✅ Show shimmer on: initial load, retry, reload
-   ❌ Do NOT show shimmer on: pull-to-refresh, pagination load-more

------------------------------------------------------------------------

## 13. Pagination vs Non-Pagination

### Use Pagination When:
Large lists, infinite scroll, feeds, discovery cards, etc.

```dart
RxList<Model> items = <Model>[].obs;
int page = 1;
bool isLastPage = false;
```

### Use Non-Pagination When:
Single item, profile, settings, details.

```dart
Rx<Model?> data = Rx<Model?>(null);
```

------------------------------------------------------------------------

## 14. Form Validation Rules

-   Always validate before API call:
    ```dart
    if (!formKey.currentState!.validate()) return;
    ```
-   Use localized validation messages
-   Disable submit button if form invalid or `isLoading == true`

------------------------------------------------------------------------

## 15. Absolute Don'ts

❌ No hardcoded endpoints  
❌ No hardcoded user-facing text  
❌ No missing loading handling  
❌ No missing error handling  
❌ No skipping localization  
❌ No forgetting to dispose controllers  
❌ No shimmer on refresh/pagination  
❌ No `Navigator.push` — use `Get.toNamed()` only  
❌ No controller instantiation in views without Binding  

------------------------------------------------------------------------

## 16. Quick Checklist (Before Submitting Code)

-   [ ] Route added to `app_routes.dart`
-   [ ] `GetPage` added to `app_pages.dart` with binding
-   [ ] Binding file created with `Get.lazyPut<Controller>()`
-   [ ] Endpoint added to `lib/src/core/network/api_configs.dart`
-   [ ] No hardcoded strings in UI (use `locale.xxx`)
-   [ ] Button uses `CommonButton(showLoading:...)` + `Obx`
-   [ ] `try / catch / finally` used correctly
-   [ ] Loading resets in `finally`
-   [ ] Error + Empty + Success states handled
-   [ ] Localization keys added if needed
-   [ ] Controllers dispose all resources in `onClose()`
-   [ ] Correct template (pagination vs non-pagination)

------------------------------------------------------------------------

## Final Rule

> **This file overrides all other patterns. Always follow these rules
> when writing API, controller, or business logic code for {{APP_NAME}}.**
