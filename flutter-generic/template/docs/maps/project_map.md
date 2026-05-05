# {{APP_NAME}} — Project Map

> Auto-generated and maintained by the `project-map` agent.
> Update after every major feature addition or module change.

---

## Module Inventory

| Module | Status | Screens | Controllers | Key Entities |
|--------|--------|---------|-------------|-------------|
| Auth | ⚪ — | — | — | UserEntity |
| [Feature] | ⚪ — | — | — | — |
| Settings | ⚪ — | — | — | — |

---

## User Journey Map

```
[Entry Point]
     ↓
[Auth / Onboarding]
     ↓
[Core Feature — Main Screen]
     ↓
[Key Action Screen]
     ↓
[Result / Feedback Screen]
```

> Replace with your app's actual navigation flow.

---

## Key Entity Registry

> List every shared entity and which modules consume it.

| Entity | Defined In | Consumed By | Key Fields |
|--------|-----------|-------------|-----------|
| `UserEntity` | `auth/domain/entities/` | auth, settings, [feature] | id, name, email |
| `[FeatureEntity]` | `[feature]/domain/entities/` | [feature] | — |

---

## Module Dependency Map

```
auth ─────────────→ [feature module]
                         ↓
                    settings
```

> Update with your actual module dependency arrows.

---

## API Ownership Map

| Module | Endpoints |
|--------|-----------|
| Auth | `/api/auth/**` |
| [Feature] | `/api/[feature]/**` |
| Settings | `/api/settings/**`, `/api/account/**` |

---

## Socket Events (if applicable)

| Event | Direction | Handler | Module |
|-------|-----------|---------|--------|
| `[event_name]` | server → client | `[controller]` | [module] |

---

## Change Impact Matrix

> Fill in as your app grows. Helps answer: "if I change X, what breaks?"

| Entity / Method | Consumers | Risk if Changed |
|-----------------|-----------|----------------|
| `UserEntity.id` | auth, settings, [feature] | HIGH — used everywhere |
| `[FeatureEntity.field]` | [feature] | LOW — isolated |
