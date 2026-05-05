
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

## 3) 🏗️ Architecture

<!-- ═══════════════════════════════════════════════════════════
  Fill in your state management rules here.
  Replace with your {{STATE_MANAGEMENT}} conventions.
  ═══════════════════════════════════════════════════════════ -->

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
    bindings/           ← DI bindings ({{DI_SOLUTION}})
    controllers/        ← State holders ({{STATE_MANAGEMENT}})
    screens/            ← Full-page screens
    widgets/            ← Feature-specific widgets
```

### Routing Files

```
lib/src/core/router/
  app_routes.dart   ← Route name constants
  app_pages.dart    ← Route list linking routes → DI bindings → screens
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

<!-- ═══════════════════════════════════════════════════════════
  Fill in your {{ROUTING_SOLUTION}} navigation rules here.
  
  Always navigate using route constants — never hardcoded strings.
  Examples:
    GoRouter:    context.go(AppRoutes.home)
    auto_route:  context.router.push(const HomeRoute())
    GetX:        Get.toNamed(Routes.home)
  ═══════════════════════════════════════════════════════════ -->

- ❌ Never hardcode route strings — always use the project's route constants

---

## 8) 🧠 State Management Rules

<!-- ═══════════════════════════════════════════════════════════
  Fill in your {{STATE_MANAGEMENT}} patterns here.
  
  Include:
  - When to use reactive/observable state vs static values
  - Standard DI binding pattern for your stack
  - Standard state holder pattern (controller/notifier/bloc/cubit)
  
  See .claude/rules/dart/patterns.md for multi-stack examples.
  ═══════════════════════════════════════════════════════════ -->

---

## 9) 🚫 Common Mistakes to Avoid

- Using raw `setState` for feature state (use `{{STATE_MANAGEMENT}}` instead)
- Hardcoding colors, text styles, or sizes
- Using `withOpacity` (use `withValues(alpha:...)` instead)
- Hardcoding route strings — always use route constants
- Navigating with raw `Navigator.push` for named routes
- Creating reactive state for static/hardcoded values
- Forgetting to dispose text controllers and animation controllers
- Skipping DI bindings when adding new routes
- Recreating existing shared widgets from `shared/widgets/`

---

## 10) ✅ Pre-Code Checklist

Before generating code, confirm:
- [ ] Requirements are clear and confirmed
- [ ] Existing components reused (not recreated)
- [ ] `{{STATE_MANAGEMENT}}` used — no raw setState for feature state
- [ ] Color constants, text style constants used — no hardcoded values
- [ ] Responsive units used (`.sp`, `.w`, `.h`, `.r` or project convention)
- [ ] Standard border radius used (see UI_INSTRUCTION.md section 5)
- [ ] No hardcoded UI strings — use the localization accessor
- [ ] State holders dispose resources (animation controllers, text controllers)
- [ ] Route constant added to routes file
- [ ] Route registered in router with DI bindings

---

## 11) 🏁 Golden Rules (Short Version)

- Ask first. Code later.
- Reuse before creating.
- No hardcoding. Ever.
- `{{STATE_MANAGEMENT}}` only. No raw setState for feature state.
- Helpers for everything: colors, text, images, sizes.
- Standard border radius (see section 5).
- Static UI ≠ observable state.
- Follow structure. Always.
- Routes via route constants only — never hardcoded strings.
- Every route needs a DI binding.
