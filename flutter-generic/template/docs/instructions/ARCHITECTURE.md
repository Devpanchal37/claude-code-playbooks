# Project Architecture Guide — {{ARCHITECTURE}}

> **Setup:** Replace this file's content to match your chosen `{{ARCHITECTURE}}` from `TEMPLATE_SETUP.md`.
> The sections below show **Clean Architecture** as an example. Adapt or replace them with your architecture's layers.

---

## Architecture Overview

<!-- ═══════════════════════════════════════════════════════════
  Describe your {{ARCHITECTURE}} pattern here in 2-3 sentences.
  What are the layers? What is the guiding principle?

  Example A: Clean Architecture
    Every feature is broken down into three layers: Domain, Data, and Presentation.
    Business logic never knows about HTTP or Flutter. The UI never makes API calls.

  Example B: MVVM
    Every feature has three parts: View (UI), ViewModel (state + logic), Model (data + repository).
    Views observe ViewModels reactively. No business logic in Views.

  Example C: Simple layered
    Every feature has Screens (UI), Controllers (state), and Services (logic + API).
    Screens never call Services directly — they go through Controllers.
  ═══════════════════════════════════════════════════════════ -->

---

## Layer Definitions

<!-- ═══════════════════════════════════════════════════════════
  Define each layer in your {{ARCHITECTURE}} below.
  Replace the Clean Architecture example with your own layers.
  ═══════════════════════════════════════════════════════════ -->

> **Example — Clean Architecture:**

### Layer 1: `domain/`
**Purpose:** The heart of your feature. Contains pure business rules.
**Rule:** Must **never** import Flutter, HTTP, or JSON packages. Pure Dart only.

- **`domain/entities/`** — Pure Dart data classes; no `fromJson`/`toJson`
- **`domain/repositories/`** — Abstract interfaces defining available data operations
- **`domain/use_cases/`** — Single-responsibility business logic (`execute()` method each)

### Layer 2: `data/`
**Purpose:** Handles the "outside world" — APIs, local storage, databases.

- **`data/models/`** — DTOs with `fromJson/toJson` + `toDomain()` conversion
- **`data/data_sources/`** — Classes that make HTTP calls or read from local storage
- **`data/repositories/`** — Concrete implementations of `domain/repositories/` interfaces

### Layer 3: `presentation/`
**Purpose:** UI and state management.

- **`presentation/controllers/`** — `{{STATE_MANAGEMENT}}` state holders; one per screen
- **`presentation/screens/`** — Full-page widgets (route targets); observe controller state
- **`presentation/widgets/`** — Feature-scoped reusable UI components

---

## Build Order (Layer Sequence)

<!-- ═══════════════════════════════════════════════════════════
  Define which layer to build first, second, third.
  This drives the implementation order in developer.md and planner.md.

  Example A: Clean Architecture
    1. Domain (pure Dart — no Flutter needed to test it)
    2. Data (depends only on domain interfaces)
    3. Presentation (depends on use cases via state holder)

  Example B: MVVM
    1. Model (data classes + repository)
    2. ViewModel (depends on Model)
    3. View (observes ViewModel)

  Example C: Simple layered
    1. Services (business logic + API)
    2. Controllers (depends on Services)
    3. Screens (depends on Controllers)
  ═══════════════════════════════════════════════════════════ -->

---

## Request Flow Example

<!-- ═══════════════════════════════════════════════════════════
  Trace a concrete user action (e.g. "User taps Login") through
  every layer so developers understand how data flows.

  Example A: Clean Architecture — "User clicks Login"
    1. LoginScreen → calls AuthController.login(email, password)
    2. AuthController → shows loading spinner
    3. AuthController → calls LoginUseCase.execute(email, password)
    4. LoginUseCase → calls AuthRepository.login() [abstract interface]
    5. AuthRepositoryImpl → calls AuthRemoteDataSource.login()
    6. AuthRemoteDataSource → HTTP POST to /api/login → returns UserModel
    7. AuthRepositoryImpl → converts UserModel → UserEntity, returns it up
    8. LoginUseCase → returns UserEntity to AuthController
    9. AuthController → stops spinner, navigates to HomeScreen
  ═══════════════════════════════════════════════════════════ -->

---

## 4. Dart / Flutter Code Conventions

### Naming
- File names: `snake_case.dart`
- Classes: `PascalCase`
- Constants: `lowerCamelCase`
- Private members: `_prefix`

### Widget Rules
- One widget class per file; file name matches class name in snake_case
- Always use `const` constructors and `super.key` on widgets
- No logic in `build()` — all logic belongs in the controller layer

### Dart Safety
- Never use `!` (null bang) without proof the value is non-null
- Prefer `final` over `var`
- Use `@immutable` on entities and DTOs

### State Holder Lifecycle

<!-- ═══════════════════════════════════════════════════════════
  Document your state management lifecycle rules here.
  
  Examples:
  
  Riverpod:
    - Tab/persistent state: use keepAlive modifier on the provider
    - Push-and-pop state: use autoDispose providers — they dispose on last listener removal
  
  Bloc:
    - Tab/persistent state: provide BlocProvider high in the widget tree (e.g. MaterialApp level)
    - Push-and-pop state: provide BlocProvider at the route level; it disposes when the route pops
  
  GetX:
    - IndexedStack tab controllers: Get.put(..., permanent: true) — never auto-disposed
    - Push-and-pop controllers: Get.lazyPut via Bindings — non-permanent
  ═══════════════════════════════════════════════════════════ -->
