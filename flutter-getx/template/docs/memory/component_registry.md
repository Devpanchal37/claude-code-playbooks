# Component Registry

> Search this file BEFORE creating any widget, controller, entity, or model.
> If it exists here → REUSE IT. Never recreate.
> Add every reusable component here after each completed feature.

---

## Shared Widgets

| Widget | File | Props | Notes |
|--------|------|-------|-------|
| `PrimaryButton` | `shared/widgets/primary_button.dart` | label, onTap, isLoading | Handles press scale animation |
| `AppTextField` | `shared/widgets/app_text_field.dart` | controller, label, validator | Wraps nb_utils AppTextField |
| `ShimmerLoader` | `shared/widgets/shimmer_loader.dart` | width, height, borderRadius | Use for all loading states |
| `ErrorStateWidget` | `shared/widgets/error_state_widget.dart` | message, onRetry | Standardized error + retry CTA |
| `EmptyStateWidget` | `shared/widgets/empty_state_widget.dart` | message, ctaLabel, onCta | Standardized empty + CTA |
| `CommonAppBar` | `shared/widgets/common_app_bar.dart` | title, leading, actions | Consistent header across screens |

---

## Auth Module

| Component | File | Type | Notes |
|-----------|------|------|-------|
| `AuthController` | `auth/presentation/controllers/auth_controller.dart` | GetX Controller | |
| `AuthBinding` | `auth/presentation/bindings/auth_binding.dart` | Binding | |
| `LoginScreen` | `auth/presentation/screens/login_screen.dart` | Screen | |
| `OnboardingScreen` | `auth/presentation/screens/onboarding_screen.dart` | Screen | Multi-step |

---

## [Feature Module — rename this section]

| Component | File | Type | Notes |
|-----------|------|------|-------|
| `FeatureController` | `feature/presentation/controllers/feature_controller.dart` | GetX Controller | |
| `FeatureBinding` | `feature/presentation/bindings/feature_binding.dart` | Binding | |
| `FeatureScreen` | `feature/presentation/screens/feature_screen.dart` | Screen | 4-state pattern |
| `FeatureCard` | `feature/presentation/widgets/feature_card.dart` | Widget | Reusable item card |

---

## Settings Module

| Component | File | Type | Notes |
|-----------|------|------|-------|
| `SettingsController` | `settings/presentation/controllers/settings_controller.dart` | GetX Controller | |
| `SettingsBinding` | `settings/presentation/bindings/settings_binding.dart` | Binding | |
| `SettingsScreen` | `settings/presentation/screens/settings_screen.dart` | Screen | |
