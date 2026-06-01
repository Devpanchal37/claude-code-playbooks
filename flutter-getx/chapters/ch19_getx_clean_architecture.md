# Chapter 19: GetX + Clean Architecture

> **Applies to:** Flutter-GetX
> **Prerequisites:** Chapter 8: Agent Creation Guide, Chapter 10: Core Agents Deep Dive
> **Estimated read + setup time:** ~35 minutes

---

## TL;DR

Playbook B is built on a specific, validated architecture: GetX for state management and DI, feature-first folder structure, and three Clean Architecture layers (domain / data / presentation) per module. Every agent in this setup encodes the rules of this architecture — the developer agent enforces widget placement gates, the code-reviewer checks layer boundaries, the planner sequences implementation in the correct dependency order. This chapter explains the architecture, the rules encoded in each agent, and the case scenarios the setup handles.

---

## What Playbook B Provides

Playbook A (Generic Flutter) gives you the agentic setup framework — agents, orchestra, memory, hooks. Playbook B builds on top of that and adds:

| Component | What's added |
|-----------|-------------|
| `CLAUDE.md` | GetX-specific zero-tolerance compliance rules (ColorHelper, locale keys, controller types, font enforcement) |
| `developer.md` agent | Widget placement gate that checks GetX patterns silently before every widget is placed |
| `docs/instructions/ARCHITECTURE.md` | Complete GetX + Clean Architecture conventions: layer rules, file naming, controller disposal, use case granularity |
| `docs/instructions/UI_INSTRUCTION.md` | Project design system: color palette, fonts, spacing scale, locale key format |
| `docs/memory/component_registry.md` | Pre-populated format for GetX widgets and controllers |
| `docs/memory/api_registry.md` | Pre-populated format for HTTP repository methods |
| `systematic-debugger.md` agent | GetX-specific bug classification: controller disposal, `Obx` reactivity, RxList mutation, Socket.IO events, Hive storage |
| `fr-analyst.md` agent | Implementation_Tasks.md that includes locale key enumeration and 5-phase implementation order |

---

## The Architecture

### Feature-First Folder Structure

Every feature lives in its own folder under `lib/src/features/`. Within each feature, the three Clean Architecture layers are enforced:

```
lib/
└── src/
    ├── features/
    │   ├── auth/
    │   │   ├── data/
    │   │   │   ├── datasources/
    │   │   │   │   └── auth_remote_datasource.dart
    │   │   │   ├── models/
    │   │   │   │   └── user_dto.dart
    │   │   │   └── repositories/
    │   │   │       └── auth_repository_impl.dart
    │   │   ├── domain/
    │   │   │   ├── entities/
    │   │   │   │   └── user_entity.dart
    │   │   │   ├── repositories/
    │   │   │   │   └── auth_repository.dart      ← abstract
    │   │   │   └── usecases/
    │   │   │       ├── login_usecase.dart
    │   │   │       └── logout_usecase.dart
    │   │   └── presentation/
    │   │       ├── bindings/
    │   │       │   └── auth_binding.dart
    │   │       ├── controllers/
    │   │       │   └── auth_controller.dart
    │   │       ├── screens/
    │   │       │   └── login_screen.dart
    │   │       └── widgets/
    │   │           └── login_form_widget.dart
    │   └── profile/
    │       └── ...
    └── core/
        ├── routes/
        │   ├── app_pages.dart
        │   └── app_routes.dart
        ├── constants/
        │   └── image_helper.dart
        └── theme/
            └── color_helper.dart
```

### The Three Layers

**Domain layer** — pure Dart. No Flutter imports. No GetX. No HTTP. Contains:
- Entities (`UserEntity`) — immutable data classes. Use `@immutable`.
- Abstract repositories (`AuthRepository`) — the contract, not the implementation.
- Use cases (`LoginUseCase`) — one class, one public method (`call()`), one action.

**Data layer** — implements the domain contracts. Contains:
- DTOs (`UserDTO`) — JSON serialization/deserialization. Never used outside data layer.
- Datasources (`AuthRemoteDatasource`) — raw HTTP calls. No business logic.
- Repository implementations (`AuthRepositoryImpl`) — transforms DTOs into entities, handles errors.

**Presentation layer** — Flutter and GetX. Contains:
- Controllers (`AuthController`) — extends `GetxController`. Holds all state. Calls use cases.
- Bindings (`AuthBinding`) — wires `Get.lazyPut()` for controller and use case dependencies.
- Screens — no logic in `build()`. All logic in controller.
- Widgets — stateless. Receive data from controller via `Obx` or `GetBuilder`.

> **CRITICAL:** Dependencies only flow inward. Presentation → Domain is allowed.
> Data → Domain is allowed. Domain → Data is NEVER allowed. Domain → Presentation
> is NEVER allowed. If a domain entity needs something from the data layer, it belongs
> in a use case or repository — not in the entity itself.

---

## GetX-Specific Rules Encoded in the Agents

These are the rules every agent enforces. Knowing them prevents the violations before they happen.

### Rule 1: Controller disposal — permanent vs. non-permanent

**Non-permanent controllers** (default) are disposed when the route is popped from the navigation stack. Use for: screens reached via `Get.to()` or `Get.toNamed()` that will be popped.

**Permanent controllers** must be used for any controller that powers a tab in an `IndexedStack`. IndexedStack tabs are never popped — GetX's auto-disposal would destroy the controller while the tab is still visible.

```dart
// CORRECT — tab controller in a dashboard binding
Get.put(HomeTabController(), permanent: true);
Get.put(ProfileTabController(), permanent: true);

// CORRECT — push-and-pop route controller
Get.lazyPut(() => ProfileDetailController());

// WRONG — permanent on a push-and-pop route (memory leak)
Get.put(ProfileDetailController(), permanent: true);

// WRONG — non-permanent on an IndexedStack tab (controller disposed while tab is active)
Get.lazyPut(() => HomeTabController());
```

The developer agent's widget placement gate checks this silently every time a controller is registered.

---

### Rule 2: RxList full replacement — `.assignAll()` not `=`

Assigning a new list to an `RxList` with `=` creates a new `RxList` object. Any `Obx` widget that had a reference to the old list is now listening to an orphaned object and will never update.

```dart
// CORRECT
items.assignAll(newList);

// WRONG — creates a new RxList, Obx loses its reference
items = newList.obs;

// WRONG — same problem
items = RxList<ItemEntity>(newList);
```

The code-reviewer agent flags this pattern in all controller files.

---

### Rule 3: `Obx` closure — observables must be read inside the closure

`Obx` is only reactive to observables read within its own builder closure. Observables read in a parent widget and passed as arguments to a child are NOT reactive — they are evaluated once at build time.

```dart
// CORRECT — observable read inside Obx closure
Obx(() => Text(controller.profileName.value))

// CORRECT — Obx wrapping a widget that reads the observable itself
Obx(() => ProfileNameWidget(name: controller.profileName.value))

// WRONG — observable passed as constructor argument outside an Obx
Text(controller.profileName.value)  // This widget never rebuilds

// WRONG — Obx that passes an RxList directly to a ListView
Obx(() => ListView(children: controller.items))  // items.obs not read — non-reactive
```

The developer agent's widget placement gate checks that every `Obx` reads at least one `.value` or observable directly in its closure.

---

### Rule 4: Use case granularity — one use case, one action

Use cases are not service classes. Each use case has one public method — `call()` — and does one thing.

```dart
// CORRECT
class LoginUseCase {
  Future<UserEntity> call(String email, String password) async { ... }
}

class LogoutUseCase {
  Future<void> call() async { ... }
}

// WRONG — this is a service, not a use case
class AuthUseCase {
  Future<UserEntity> login(String email, String password) async { ... }
  Future<void> logout() async { ... }
  Future<void> refreshToken() async { ... }
}
```

The planner agent enforces this when generating the domain layer file list in the implementation plan.

---

### Rule 5: No logic in `build()`

Controllers hold all state and all logic. `build()` is a pure description of the UI.

```dart
// CORRECT
class ProfileScreen extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => controller.isLoading.value
        ? const LoadingWidget()
        : ProfileBody(),
      ),
    );
  }
}

// WRONG — logic in build()
Widget build(BuildContext context) {
  final user = Get.find<AuthController>().user.value;
  if (user.profileComplete) {
    // business logic here
  }
}
```

---

## The 5-Phase Implementation Order

Implementation_Tasks.md for every GetX feature phases work in this exact order. Each phase depends on the previous one being complete.

```
Phase 1 — Models
  Entity classes (domain/entities/)
  DTO classes (data/models/)
  Model key constants (Hive box names, preference keys)
  ↓ domain layer must exist before data can reference it

Phase 2 — API Layer
  Abstract repository interface (domain/repositories/)
  Repository implementation (data/repositories/)
  Datasource (data/datasources/)
  Endpoint wiring in api_registry.md
  ↓ repository must exist before controller can call it

Phase 3 — Screens
  Controller (presentation/controllers/)
  Binding (presentation/bindings/)
  Screen file (presentation/screens/)
  Widget files (presentation/widgets/)
  ↓ locale keys must be registered before widget strings are final

Phase 4 — Locale Keys
  Add all new locale.xxx keys to the localization files
  Add English values
  ↓ navigation must be registered last — it references all of the above

Phase 5 — Navigation
  Route constant in app_routes.dart
  GetPage entry in app_pages.dart (includes Binding reference)
  Update any existing screen that navigates to this new screen
```

> **CRITICAL:** Never implement Phase 3 (Screens) before Phase 1 and 2 are complete.
> Controllers that reference non-existent use cases or repositories cause cascading
> compile errors that are slow to debug. The planner agent enforces this sequence
> in every implementation plan it produces.

---

## Locale and Model Key Planning (FR Stage)

Before any code is written, Implementation_Tasks.md must enumerate all new keys. This prevents hardcoded strings, key collisions in Hive, and missing translatable text.

### New Locale Keys Required (table format)

Appended to the end of every Implementation_Tasks.md that introduces user-visible text:

```markdown
## New Locale Keys Required

| Key | English value | Used in |
|-----|--------------|---------|
| locale.filterTitle | "Filter Profiles" | FilterBottomSheet |
| locale.filterAgeRange | "Age Range" | FilterBottomSheet |
| locale.filterApply | "Apply Filters" | FilterBottomSheet |
| locale.filterReset | "Reset" | FilterBottomSheet |
```

### New Model Keys Required (table format)

Appended when the feature uses Hive, SharedPreferences, or any keyed storage:

```markdown
## New Model Keys Required

| Class | Constant name | Storage scope | Value stored |
|-------|--------------|--------------|-------------|
| FilterKeys | activeFilters | Hive: settingsBox | Serialized FilterPrefsModel |
| FilterKeys | lastFilterUpdate | Hive: settingsBox | DateTime ISO string |
```

**Why at FR stage, not implementation stage:** If keys are planned during implementation, developers hardcode strings under time pressure, create key name collisions across features, and miss translatable strings. These are expensive to fix after the fact — search-and-replace across 10+ files vs. a 2-minute table at requirements time.

---

## Cross-Screen Event Planning

When a feature updates state across multiple screens simultaneously, the event name must be agreed in Flow_Requirements.md before implementation starts.

In GetX, cross-screen broadcasts typically use `Get.find<AnotherController>().someMethod()` or a shared event bus pattern. If the emitter and the listener use different method or event names, they never connect — and this class of bug is invisible until integration testing.

### Cross-Screen Events Table (in Flow_Requirements.md)

```markdown
## Cross-Screen Events

| Event name | Fired by | Consumed by | Effect on consumer |
|-----------|---------|-------------|-------------------|
| onConnectionAccepted | ConnectionController | DiscoverController | Remove accepted card from stack |
| onConnectionAccepted | ConnectionController | NotificationController | Decrement badge count |
| onProfileUpdated | ProfileEditController | ProfileController | Reload profile data |
```

This table is generated by the fr-analyst agent for any feature where a state change in one screen must propagate to another.

> **CRITICAL:** Never let two developers independently implement the event emitter and
> the event listener for the same logical action. The sender and receiver must agree on
> the method or event name before either writes a single line. The cross-screen events
> table is that agreement.

---

## Case Scenarios the Setup Handles

This table shows every scenario the agent setup covers — what fires, what the output is, and what you do next.

| Scenario | What you type | What fires | Output | Your next action |
|----------|-------------|-----------|--------|-----------------|
| New feature (has FR plan) | `develop [ModuleName]` | developer agent | All files written, REVIEW checkpoint | Run quality loop |
| New feature (no FR plan) | Feature description (no action verb) | fr-analyst | 3 FR files in docs/FR/ | Confirm API with backend, then `develop` |
| Complex feature (>3 modules) | Feature description | fr-analyst → planner | FR files + implementation plan | Confirm plan, then `develop` |
| Runtime bug — data mismatch | `bug:: [description]` | systematic-debugger → DATA GATE | "⏸️ DATA MISMATCH — share console log" | Paste console log |
| Runtime bug — UI only | `bug:: [description]` | systematic-debugger → FAST TRACK | Handoff Brief with file:line | developer applies minimal fix |
| Runtime bug — logic/state | `bug:: [description]` | systematic-debugger → FULL INVESTIGATION | Confirmed Handoff Brief | developer applies fix if Flutter-side |
| Backend-side bug confirmed | `bug:: [description]` | systematic-debugger | Handoff Brief, root cause = backend | Log to backend_issues.md, no Flutter fix |
| Cross-module entity change | Agent reads project_map.md first | developer agent | All impacted files updated | code-reviewer reviews all impacted files |
| Auth token handling | `develop AuthToken` | ui-design-enforcer → developer → security-reviewer | Secure implementation | Confirm security-reviewer findings |
| Socket.IO event bug | `bug:: [description]` | systematic-debugger → Socket.IO branch | DATA GATE fires (event payload mismatch) | Paste socket event log |
| Hive storage bug | `bug:: [description]` | systematic-debugger → Hive branch | Check key constants vs. stored key | Paste relevant log |
| Pagination state bug | `bug:: [description]` | systematic-debugger → state investigation | Handoff Brief: controller load-more logic | developer fixes RxList or pagination state |
| GetX controller disposal bug | `bug:: [description] + Context: [permanent/non-permanent]` | systematic-debugger → lifecycle branch | Root cause: disposal type mismatch | developer fixes controller registration |
| flutter analyze failing | "flutter analyze is failing with N errors: [paste]" | build-error-resolver | Minimal diffs to fix compile errors | Verify clean analyze |

---

## GetX Onboarding — What to Set Up First

If this is a new project using Playbook B, complete this sequence before writing any features.

### Step 1 — Complete the generic setup

Follow [Chapter 3: Quick Start Checklist] completely. The generic setup (CLAUDE.md, settings.json, docs/ folder, developer agent, orchestra) is the foundation. Playbook B adds GetX-specific content on top of it.

### Step 2 — Create or customize ARCHITECTURE.md

Create `docs/instructions/ARCHITECTURE.md` with:
- The feature-first folder structure (show the exact path pattern)
- The three layers with one-sentence descriptions of what belongs in each
- The five GetX-specific rules from this chapter (controller disposal, RxList, Obx, use case granularity, no logic in build)
- The canonical reference module: after implementing the first complete feature correctly, document it here. Every subsequent Implementation_Tasks.md references it.

### Step 3 — Create UI_INSTRUCTION.md

Create `docs/instructions/UI_INSTRUCTION.md` with:
- Color system (reference ColorHelper — never define colors here directly)
- Font: `Plus Jakarta Sans` is the project font. No other font allowed.
- Locale key format: `locale.[screenName][ElementName]` (e.g., `locale.loginEmailLabel`)
- Shimmer required on all initial async loads
- The four required async states for every screen: Loading → Error → Empty → Success

### Step 4 — Update the developer agent with project-specific constraints

Open `.claude/agents/developer.md`. In the Widget Placement Gate section, add the project-specific checks:
- Which color constant class is used (e.g., `ColorHelper`)
- Which locale object is used (e.g., `locale.xxx`)
- What the font family name is (`Plus Jakarta Sans`)

### Step 5 — Set the canonical reference module

After your first feature is complete and passes the full quality loop:
1. Add to `ARCHITECTURE.md`: "Canonical reference module: `lib/src/features/[first_module]/`"
2. The fr-analyst and planner agents will reference this in all subsequent Implementation_Tasks.md files

### Step 6 — Verify with a test feature

Run a test scenario end-to-end:
1. Type a feature description (no action verb) — fr-analyst should generate 3 FR files
2. Type `develop [ModuleName]` — developer agent should produce all 5 phases in order
3. Confirm `flutter analyze` is clean after implementation
4. Run the quality loop manually: ask Main Claude to run ui-reviewer → code-reviewer

---

## Validation

### Test 1: Architecture layer compliance

**What to do:** Implement a minimal feature (one screen, one endpoint) using `develop [TestModule]`.

**Expected result:** Files are created in the correct layers:
- `lib/src/features/[module]/domain/entities/` — entity file
- `lib/src/features/[module]/domain/usecases/` — use case files (one per action)
- `lib/src/features/[module]/data/repositories/` — repository implementation
- `lib/src/features/[module]/presentation/controllers/` — controller
- `lib/src/features/[module]/presentation/bindings/` — binding
- `lib/src/features/[module]/presentation/screens/` — screen

**If files are in wrong layers:** Read `ARCHITECTURE.md` and verify the developer agent's Pre-Step includes "read ARCHITECTURE.md at session start." The agent must have this file loaded before writing any files.

---

### Test 2: GetX compliance enforcement

**What to do:** After the developer agent writes a controller file, check it for violations:
- Any `RxList` assigned with `=` instead of `.assignAll()`
- Any controller in an IndexedStack registered without `permanent: true`

**Expected result:** Zero violations. The developer agent's widget placement gate prevents these during writing.

**If violations exist:** The widget placement gate in the developer agent does not include GetX-specific checks. Add them to the gate's checklist in `developer.md`.

---

### Test 3: Locale key planning in FR output

**What to do:** Describe a feature with user-visible text to Main Claude (no action verb). After fr-analyst generates the files, open the Implementation_Tasks.md file.

**Expected result:** The file ends with a "New Locale Keys Required" table listing all new `locale.xxx` keys with their English values and screen usage.

**If the table is missing:** The fr-analyst agent's implementation tasks template is not including locale key enumeration. Add the table format to the agent's output template section.

---

## Common Mistakes

### Mistake 1: Implementing screens before the domain layer exists

**Symptom:** Controller references a use case that doesn't exist yet. Compile error on the next `flutter analyze`.

**Cause:** Developer skipped Phase 1 (Models) and Phase 2 (API layer) and went directly to Phase 3 (Screens).

**Fix:** The implementation must follow phases 1 → 2 → 3 → 4 → 5 in order. If the developer agent skipped phases, check whether the Implementation_Tasks.md file had the 5-phase ordering. If it did and the agent skipped anyway — add to the developer agent: "Do not start Phase 3 until Phase 1 and Phase 2 are written and confirmed."

---

### Mistake 2: Non-permanent controller on an IndexedStack tab

**Symptom:** Tab controller state resets when switching between tabs. Debug logging shows controller `onClose()` being called while the tab is still visible.

**Cause:** Controller registered with `Get.lazyPut()` or `Get.put()` without `permanent: true` in the dashboard binding.

**Fix:** Change the registration to `Get.put([Controller](), permanent: true)`. Check `component_registry.md` — add a note to the dashboard binding entry: "All tab controllers must be permanent."

---

### Mistake 3: Using `=` instead of `.assignAll()` for RxList

**Symptom:** A list widget never updates after an API call that returns new data, even though the API call succeeds and the data is correct.

**Cause:** Controller does `items = apiResponse.data.obs` — creating a new RxList that the Obx widget is not listening to.

**Fix:** Replace with `items.assignAll(apiResponse.data)`. Add to `error_learnings.md` so the systematic-debugger checks this pattern for list-not-updating bugs.

---

### Mistake 4: String literals in widget files

**Symptom:** UI compliance grep finds `Text("Filter Profiles")` in a screen file. UI reviewer flags it.

**Cause:** Locale key was not planned at FR stage. Developer hardcoded the string during implementation.

**Fix:** Add the locale key to the localization file. Replace the hardcoded string with `locale.filterTitle`. Update the Implementation_Tasks.md "New Locale Keys Required" table. For the next feature — plan all locale keys at FR stage, not implementation stage.

---

### Mistake 5: Hardcoded color in a widget file

**Symptom:** UI compliance grep finds `Color(0xFF2D2D2D)` or `Colors.grey[800]` in a screen file. Developer agent's widget placement gate should have caught this — it didn't.

**Cause:** The widget placement gate in `developer.md` does not include `ColorHelper` as the required color source, or the gate instruction is in paragraph form and the agent treated it as advisory.

**Fix:** In `developer.md`, the color check must be in a bulleted list under a `DO NOT:` heading — not embedded in a paragraph. Format: "DO NOT write `Color(0xFF...)` or `Colors.xxx` anywhere. Every color must come from `ColorHelper.xxx`."

---

## Reference

| Item | Value |
|------|-------|
| Architecture type | Feature-first, three layers (domain / data / presentation) |
| Implementation order | Phase 1 Models → Phase 2 API → Phase 3 Screens → Phase 4 Locale keys → Phase 5 Navigation |
| Controller: IndexedStack tab | `Get.put(..., permanent: true)` — mandatory |
| Controller: push-and-pop route | `Get.lazyPut(() => ...)` — standard |
| RxList full replacement | `.assignAll(newList)` — never `= newList` |
| Obx rule | Must read observable directly in its own closure |
| Use case rule | One class, one public method (`call()`), one action |
| FR planning: locale keys | Table in Implementation_Tasks.md before implementation |
| FR planning: cross-screen events | Table in Flow_Requirements.md before implementation |
| Canonical reference module | Set in ARCHITECTURE.md after first completed feature |

---

*Next: Chapter 20: Updating the Architecture or State Management*
