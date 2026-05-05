# API Registry

> Search this file BEFORE adding any new API call.
> Add every API function here as you implement it. One row per function.
> Always use `ApiConfig.xxx` constants — never hardcode endpoint strings.

---

## Auth

| Function | File | Method | Endpoint | Notes |
|----------|------|--------|----------|-------|
| `sendOtp` | `auth_api.dart` | POST | `/api/auth/otp/send` | |
| `verifyOtp` | `auth_api.dart` | POST | `/api/auth/otp/verify` | Returns token |
| `getProfile` | `auth_api.dart` | GET | `/api/auth/profile` | |
| `logout` | `auth_api.dart` | POST | `/api/auth/logout` | |

## Onboarding

| Function | File | Method | Endpoint | Notes |
|----------|------|--------|----------|-------|
| `onboardingStep1` | `onboarding_api.dart` | PATCH | `/api/onboarding/step-1` | Void response |
| `onboardingStep2` | `onboarding_api.dart` | PATCH | `/api/onboarding/step-2` | Void response |

## [Feature Module — rename this section]

| Function | File | Method | Endpoint | Notes |
|----------|------|--------|----------|-------|
| `getItems` | `feature_api.dart` | GET | `/api/items` | Paginated — page, limit params |
| `getItemById` | `feature_api.dart` | GET | `/api/items/{id}` | |
| `createItem` | `feature_api.dart` | POST | `/api/items` | |
| `updateItem` | `feature_api.dart` | PATCH | `/api/items/{id}` | |
| `deleteItem` | `feature_api.dart` | DELETE | `/api/items/{id}` | |

## Settings / Account

| Function | File | Method | Endpoint | Notes |
|----------|------|--------|----------|-------|
| `updateSettings` | `settings_api.dart` | PATCH | `/api/settings` | |
| `deleteAccount` | `settings_api.dart` | DELETE | `/api/account` | Requires confirmation token |
