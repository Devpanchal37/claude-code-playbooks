# Feature: [Feature Name]
# Module: [Module Name]

## Status: PENDING

---

## Business Context
[Why does this feature exist? What problem does it solve?]

---

## User Journey
1. User is on [previous screen]
2. User taps [X]
3. App shows [Y]
4. On success → [navigate to / show]
5. On failure → [show error / stay]

---

## Screens

| Screen | Route | Description |
|--------|-------|-------------|
| [Name]Screen | `Routes.[name]` | [description] |

---

## API

| Action | Method | Endpoint Constant | Request | Response |
|--------|--------|------------------|---------|----------|
| [action] | POST | `ApiConfig.[name]` | `{ field: type }` | `{ field: type }` |

---

## Form Fields

| Field | Validation | Keyboard Type |
|-------|-----------|--------------|
| [field] | required / min X chars | email / text / number |

---

## States to Handle

- [ ] Loading (button spinner)
- [ ] Success ([what happens])
- [ ] Error — API fail (toast)
- [ ] Error — Validation fail (inline)
- [ ] Error — Network fail (generic toast)
- [ ] Empty state ([what to show if list])

---

## Navigation
- On success: `Get.[method](Routes.[name])`
- Back: [describe behavior]

---

## Design Reference
[Screenshot path or Figma link]

---

## Special Business Rules
- [Any non-obvious constraints]

---

## Self-Validation (AI fills before marking REVIEW)

```
[ ] Entity: pure Dart, no JSON, no Flutter imports
[ ] Model: fromJson + toJson + toEntity()
[ ] DataSource: ApiService + ApiConfig.xxx only
[ ] RepositoryImpl: catches errors, returns Entity
[ ] Controller: isLoading + errorMessage + try/catch/finally
[ ] TextEditingControllers disposed in onClose()
[ ] Route in app_routes.dart
[ ] GetPage + Binding in app_pages.dart
[ ] No hardcoded colors / sizes / strings / routes
[ ] Border radius 8.r (unless design says otherwise)
[ ] All states: Loading / Error / Empty / Success
[ ] CommonButton + showLoading + Obx
[ ] locale.xxx for all user-facing text
[ ] component_registry.md updated
[ ] api_registry.md updated
[ ] _pipeline_status.md → REVIEW
```
