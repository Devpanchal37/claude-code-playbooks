
# 🧭 {{APP_NAME}} — Flutter UI Master Guidelines

> Use this document for all AI-assisted and manual UI development in the {{APP_NAME}} Flutter project.

---

## 1) 🎯 Core Workflow

**Always provide:**
- ✅ Screenshot (attach directly in chat)

**Process:**
1. Check screenshot for visual meaning
2. Implement pixel-perfect UI
3. Use only existing helpers & components
4. Deliver clean, responsive, maintainable code

---

## 2) 🛑 Rule Before Coding (Mandatory)

Before writing code, ALWAYS:
1. Ask clarifying questions
2. Summarize what you will build
3. Wait for confirmation

---

## 3) 🏗️ Architecture (GetX Only)

- ❌ Never use `setState`
- ✅ Always use GetX (`.obs`, `Obx`, controllers, bindings)

### Feature Folder Structure

```
lib/src/features/<feature_name>/
  data/
    data_sources/       ← API call classes
    models/             ← JSON models (fromJson / toJson)
    repositories/       ← Repository implementation
  domain/
    entities/           ← Pure Dart entities
    repositories/       ← Abstract contracts
  presentation/
    bindings/           ← GetX Bindings
    controllers/        ← GetX Controllers
    screens/            ← Full-page screens
    widgets/            ← Feature-specific widgets
```

### Routing Files

```
lib/src/core/router/
  app_routes.dart   ← Route name constants
  app_pages.dart    ← GetPage list linking routes → bindings → screens
```

### Widget Placement Rule

| Scope | Location |
|---|---|
| Used in one feature only | `features/<name>/presentation/widgets/` |
| Used in 2–3 features | `shared/widgets/` |
| Truly generic / app-wide | `shared/widgets/` |

---

## 4) 🧩 Use Existing Components First

Always check and reuse before creating:

| Old Name (other projects) | Correct Name in {{APP_NAME}} | Location |
|---|---|---|
| `CommanBtn` | `CommonButton` | `shared/widgets/common_button.dart` |
| `AppTextBtn` | `AppTextBtn` | `shared/widgets/common_button.dart` |
| `CommanTextField` | `CommonTextField` | `shared/widgets/common_text_field.dart` |
| `CommonAppBar` | `CommonAppBar` | `shared/widgets/common_app_bar.dart` |
| `AppLoader` | `AppLoader` | `shared/widgets/app_loader.dart` |
| `ImageView` | `ImageView` | `shared/widgets/image_view.dart` |
| `SpinKitLoader` | `SpinKitRing` | `shared/widgets/spin_kit_loader.dart` |

❌ Don't recreate what already exists.

---

## 5) 🎨 Styling Rules (No Exceptions)

### Colors
- ✅ Always use `ColorHelper` from `lib/src/theme/color_helper.dart`
- ❌ Never hardcode colors — `Color(0xFF...)` and `Colors.xxx` are both forbidden anywhere in `lib/`
- ❌ Don't use deprecated `withOpacity`
- ✅ Use `withValues(alpha: …)` or `withAlpha(...)`

### Text
- ✅ Always use `TextStyleHelper` from `lib/src/theme/text_style_helper.dart`
- ❌ Never hardcode `TextStyle(fontSize: …)`
- ❌ `fontFamily` must always be `'{{APP_FONT}}'` — no other font allowed

### Sizing (Responsive)
- ✅ Use `.sp`, `.w`, `.h`, `.r` from `SizeUtils`
- ❌ Never use fixed numbers like `16`, `24`

### Border Radius
- ✅ Standard = `8.r`
- ❌ Don't use `12.r` unless the screen design explicitly says so

### Spacing
- Small: `8.h / 8.w`
- Medium: `16.h / 16.w`
- Large: `24.h / 24.w`

### Zero-Tolerance Violations (project-ending bugs if they reach production)

| Violation | Rule |
|-----------|------|
| `Color(0xFF...)` anywhere in `lib/` | → use `ColorHelper.xxx` |
| `Colors.xxx` anywhere in `lib/` | → use `ColorHelper.xxx` |
| String literals in widget files | → use `locale.xxx` |
| `fontFamily` other than `'{{APP_FONT}}'` | → fix immediately |
| Missing shimmer on initial load | → fix before REVIEW |

**Three-layer defense — no exceptions:**
- Developer agent enforces these at widget-placement time (Widget Placement Gate)
- UI-reviewer agent confirms after implementation
- Code-reviewer blocks merge if found

---

## 6) 🖼️ Assets & Text

### Images
- ✅ Use `ImageHelper` from `lib/src/core/constants/image_helper.dart`
- ✅ Use `ImageView` widget for all asset / network / SVG images
- ❌ Don't hardcode asset paths like `'assets/png/logo.png'`

### Text / Strings
- ✅ Use `locale.someText` from `BaseLanguage.of(context)`
- ❌ Don't hardcode strings like `"Home"`, `"Cancel"`, `"Error"`

---

## 7) 🔀 Navigation Rules

- ✅ Use `Get.toNamed(Routes.routeName)` — navigate forward
- ✅ Use `Get.offNamed(Routes.routeName)` — replace current screen
- ✅ Use `Get.offAllNamed(Routes.routeName)` — clear stack entirely
- ✅ Pass arguments: `Get.toNamed(Routes.x, arguments: {'key': value})`
- ✅ Read arguments: `final args = Get.arguments ?? {};`
- ❌ Never use `Navigator.push` or `Navigator.pushNamed`
- ❌ Never hardcode route strings — always use `Routes.xxx`

---

## 8) 🧠 State Management Rules

### Static / Hardcoded Data
- ✅ Use static strings directly in the screen
- ❌ Don't create `.obs` for static/fake values
- Always add comment:

```dart
'12,500 USD' // Static - Replace with data model later
```

### Use Observables ONLY when:
- Data comes from an API or Hive
- User interaction changes the UI state
- Real dynamic updates are needed (e.g. chat messages stream)

### Standard Binding Pattern

```dart
// features/auth/presentation/bindings/login_binding.dart
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
```

### Standard Controller Pattern

```dart
// features/auth/presentation/controllers/login_controller.dart
class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>(debugLabel: 'login_form_key');
  final emailController = TextEditingController();

  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> onLoginTap() async {
    if (!formKey.currentState!.validate()) return;
    if (isLoading.value) return;
    errorMessage.value = '';
    isLoading.value = true;
    try {
      // API call here
      Get.offAllNamed(Routes.home);
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }
}
```

---

## 9) 🚫 Common Mistakes to Avoid

- Using `setState` anywhere
- Hardcoding colors, text styles, or sizes
- Using `withOpacity` (use `withValues(alpha:...)` instead)
- Hardcoding route strings instead of `Routes.xxx`
- Using `Navigator.push` instead of `Get.toNamed`
- Creating feature observables for static text
- Using `12.r` border radius (standard is `8.r`)
- Forgetting to dispose controllers in `onClose()`
- Skipping bindings when adding new routes
- Recreating `CommonButton`, `CommonTextField`, or `ImageView`

---

## 10) ✅ Pre-Code Checklist

Before generating code, confirm:
- [ ] Requirements are clear and confirmed
- [ ] Existing components reused (not recreated)
- [ ] GetX used (no setState)
- [ ] `ColorHelper`, `TextStyleHelper`, `ImageHelper` used
- [ ] Responsive units used (`.sp`, `.w`, `.h`, `.r`)
- [ ] Border radius = `8.r` (unless design says otherwise)
- [ ] No hardcoded strings — use `locale.xxx`
- [ ] Controllers dispose resources in `onClose()`
- [ ] Route added to `app_routes.dart`
- [ ] `GetPage` added to `app_pages.dart` with binding
- [ ] Binding registered with `Get.lazyPut<Controller>()`

---

## 11) 🏁 Golden Rules (Short Version)

- Ask first. Code later.
- Reuse before creating.
- No hardcoding. Ever.
- GetX only. No setState.
- Helpers for everything: colors, text, images, sizes.
- `8.r` is the standard radius.
- Static UI ≠ observable state.
- Follow structure. Always.
- Routes via `Routes.xxx` only.
- Every route needs a Binding.
