# Chapter 20: Updating the Architecture or State Management

> **Applies to:** Flutter-GetX
> **Prerequisites:** Chapter 19: GetX + Clean Architecture, Chapter 8: Agent Creation Guide
> **Estimated read + setup time:** ~30 minutes

---

## TL;DR

The agents in this setup are not neutral — they encode the current architecture. When you change the folder structure, swap the state management library, or replace a core pattern, the agents will produce code that contradicts your new direction unless you update their instructions. This chapter walks you through exactly which files to change for each type of architectural update, in what order, and how to verify the agents have adopted the new pattern.

---

## What This Is

The Playbook B setup has architectural assumptions baked into at least six places: `ARCHITECTURE.md`, `UI_INSTRUCTION.md`, `CLAUDE.md`, the developer agent, the planner agent, and the code-reviewer agent. These files were written to match one specific stack — GetX for state management, feature-first folder structure, Clean Architecture layers.

Changing any of those assumptions requires updating every place that encodes the old assumption. A partial update is worse than no update — the developer agent uses the old pattern, the code-reviewer flags the new code as a violation, and the planner generates an implementation plan for an architecture that no longer exists.

This chapter covers three types of change:

| Change type | Scope | Files affected |
|------------|-------|----------------|
| **20.1** — Folder architecture | Moderate | ARCHITECTURE.md, developer agent, planner agent, agents.md |
| **20.2** — State management library | Large | ARCHITECTURE.md, UI_INSTRUCTION.md, CLAUDE.md, developer agent, planner agent, code-reviewer agent, error_learnings.md |
| **20.3** — Any other component | Variable | Identify by grep + agent validation |

---

## Why It Exists (The Problem It Solves)

**Without this protocol:** A developer switches from feature-first to module-first folders. They update `ARCHITECTURE.md`. They start developing a new feature and find the developer agent generates files in `lib/src/features/NewModule/` — the old location. The code-reviewer passes it because it matches `ARCHITECTURE.md` at the layer level. Three features later, the codebase has a split structure: old modules in `features/`, new modules in `modules/`. The developer agent has no way to know which structure to use for the next feature.

**With this protocol:** Before writing any new code, the developer updates every agent file that references the old pattern. The migration test verifies the developer agent uses the new structure on the first attempt. No dual-structure drift.

### What This Does NOT Do

This chapter does not cover migrating existing source files from one pattern to another — that is a refactoring task for the `refactor-cleaner` agent. This chapter covers updating the agent instructions and configuration files so that NEW code follows the new pattern. Migrate existing source files separately, after the instructions are updated and verified.

---

## 20.1 — Changing Folder Architecture

### When this applies

You decide to restructure the codebase — for example:
- Feature-first (`lib/src/features/`) to module-first (`lib/src/modules/`)
- Single-layer to multi-package (moving shared entities to a separate Dart package)
- Flat feature folders to nested sub-feature folders

Any change to where files live and how they are grouped counts as a folder architecture change.

### What must change

#### 1. `docs/instructions/ARCHITECTURE.md`

This is the file the developer agent, planner agent, and code-reviewer all read during their instruction loading step. It must be updated first — before any agent files — because the agents derive their path conventions from it.

Update every section that references folder paths:

- **Folder structure diagram:** update the tree to show the new layout
- **Layer placement rules:** "domain entities go in `lib/src/features/[Feature]/domain/entities/`" → update to the new path pattern
- **Canonical reference module:** update the reference module path if it has moved
- **Naming conventions:** if folder names are changing (e.g., `features` → `modules`), update all references

#### 2. Developer agent (`developer.md`)

The developer agent's implementation loop references specific paths in two places:

**Step 2 — Implementation loop:** The agent generates files in a specific order using specific paths. Find every path reference and update it. Search the file for strings like `lib/src/features/`, `domain/entities/`, `data/repositories/` — these are the path segments that embed the current architecture.

**Widget placement gate:** This gate checks that files are placed in the correct layer. If the layer path changes, the gate's pass/fail condition references the old path. Update the path pattern the gate uses to validate file placement.

**Before editing, read the entire developer agent file and note every location where a folder path appears.** Do not update just the obvious ones — the gate descriptions often reference paths in their example output, and those must match the actual paths too.

#### 3. Planner agent (`planner.md`)

The planner generates an implementation plan that lists files by path. The plan format section in the planner agent contains a path template:

```
Plan format:
  domain layer files:
    lib/src/features/[Feature]/domain/entities/[feature]_entity.dart
    lib/src/features/[Feature]/domain/usecases/[action]_usecase.dart
    ...
```

Update every path in this template to match the new structure.

Also check: if the planner has a canonical reference to the example module (`lib/src/features/Auth/` or similar), update that to the new path.

#### 4. `agents.md` (the orchestra file)

Check `agents.md` for any path-specific trigger rules or scope contracts. These are typically written as part of the reviewer gate scopes:

```
Changed files: lib/src/features/[Module]/presentation/...
```

If any scope description in `agents.md` uses feature-first paths as examples, update those examples to the new structure. If paths appear as literal conditions in any rule (e.g., "if the changed file is in `lib/src/features/`"), update the condition.

### What does NOT change

| File | Why it stays the same |
|------|-----------------------|
| `CLAUDE.md` core rules | Critical rules (no `Color(0xFF...)`, no string literals) are architecture-independent |
| Gate logic in agents | DATA GATE, compliance grep, instruction loading gate — none of these reference paths |
| `docs/memory/error_learnings.md` | Mistake entries are about behavior, not file locations |
| `docs/memory/component_registry.md` | Component entries include paths, but the registry format itself doesn't change |
| `docs/FR/` files | FR files document requirements; they don't enforce file paths |
| Memory system (claude-mem MCP, auto-memory) | Memory stores patterns and decisions, not paths |

### Update order

Follow this order strictly. Updating agents before ARCHITECTURE.md means agents are temporarily referencing an instruction file that contradicts the new structure.

```
1. Update ARCHITECTURE.md with new folder structure
      ↓
2. Update developer agent (implementation loop + widget placement gate)
      ↓
3. Update planner agent (plan template paths)
      ↓
4. Update agents.md (scope examples)
      ↓
5. Run validation test (see Validation section)
```

### Risk: hardcoded path assumptions

Every agent file should be checked for hardcoded path segments. Run this search on all four agent files before and after the update:

```
grep -n "lib/src/features" .claude/agents/developer.md
grep -n "lib/src/features" .claude/agents/planner.md
grep -n "lib/src/features" .claude/agents/code-reviewer.md
grep -n "lib/src/features" .claude/rules/common/agents.md
```

If grep returns lines you did not update, those are missed references that will generate files in the wrong location. Update every match.

---

## 20.2 — Changing State Management

### When this applies

You decide to replace GetX as the state management and DI library. Common replacements: Riverpod, Bloc, Provider. The principles below apply to any target library — examples use Riverpod as the destination.

### Scope assessment

This is the largest type of change in this chapter. GetX patterns are referenced in at least six distinct places:

| Location | What it references |
|----------|--------------------|
| `ARCHITECTURE.md` | Controller lifecycle, `Binding`, `Get.put()`, `Get.find()`, routing |
| `UI_INSTRUCTION.md` | `Obx`, `GetX<>()`, reactive variable access patterns |
| `CLAUDE.md` | UI compliance rules: `Obx`, `GetX`, `Get.put(permanent: true)` |
| `developer.md` agent | Widget placement gate: checks for `Obx`, controller references, binding registration |
| `planner.md` agent | Implementation plan step: "Create binding → Register with GetX → Create controller" |
| `code-reviewer.md` agent | Review criteria: checks for correct GetX disposal, binding registration, `Obx` scope |
| `docs/memory/error_learnings.md` | GetX-specific entries (RxList mutation, `Obx` child widgets, `permanent: true` rule) |

A partial update — where you change `ARCHITECTURE.md` but leave the developer agent's widget placement gate checking for `Obx` — causes the developer agent to silently reject new Riverpod widgets as compliance violations. The agent will report a passing flutter analyze but the widget tree will be wrong.

### What to update

#### 1. `docs/instructions/ARCHITECTURE.md`

Replace the GetX-specific layer descriptions with the equivalent Riverpod descriptions:

| Remove (GetX) | Add (Riverpod) |
|--------------|----------------|
| Controller classes (`extends GetxController`) | Notifier classes (`extends Notifier<T>` or `extends AsyncNotifier<T>`) |
| `Binding` classes (`extends Bindings`) | Provider file (contains the provider declaration) |
| `Get.put(...)` and `Get.find<T>()` | `ProviderScope` at root, `ref.watch(...)` / `ref.read(...)` in widgets |
| `Get.toNamed(routeName)` navigation | Navigation package of your choice (GoRouter, Auto Route) |
| Route registration pattern | GoRouter / Auto Route pattern |

Update the folder structure diagram to replace `controllers/` and `bindings/` with the Riverpod equivalents:

```
presentation/
  providers/           ← was: controllers/ + bindings/
    user_provider.dart
  screens/
    user_screen.dart
  widgets/
    user_card.dart
```

#### 2. `docs/instructions/UI_INSTRUCTION.md`

Remove the section on reactive widget patterns that reference `Obx` and `GetX<T>`. Add the Riverpod equivalent:

```
# Remove
- Use Obx(() => ...) to watch observables
- Use GetX<ControllerName>(builder: ...) for controller-scoped widgets
- Never put logic inside Obx — only read the observable

# Add
- Use Consumer(builder: (context, ref, child) => ...) to watch providers
- Use ConsumerWidget instead of StatelessWidget when the widget reads a provider
- ref.watch rebuilds the widget; ref.read does not
```

#### 3. `CLAUDE.md` UI compliance rules

The zero-tolerance compliance table references GetX-specific APIs. Update the relevant rows:

```
# Remove these rows from the compliance table:
- Obx(() => ...) used outside its reactive closure → violation
- Get.put(permanent: true) missing on IndexedStack controllers → violation

# Add:
- ConsumerWidget used instead of StatelessWidget when widget reads provider → required
- ProviderScope missing from app root → violation (app won't compile, but note it)
```

Remove the code conventions rule about `Get.put(permanent: true)` for IndexedStack tabs and replace it with the Riverpod equivalent scoping rule.

#### 4. Developer agent (`developer.md`)

The widget placement gate checks for GetX-specific patterns. Update the gate's checklist:

```
# Widget placement gate — remove:
- Does this widget read a controller via Obx? → check GetX registered in binding
- Is the controller permanent for tab screens? → verify Get.put(permanent: true)

# Widget placement gate — add:
- Does this widget read a provider? → check ConsumerWidget or Consumer wrapper
- Is the provider scoped correctly? → verify ProviderScope is above this widget in the tree
```

Also update the implementation loop step that generates the binding file. Replace:

```
Create [Feature]Binding:
  - Register controller with Get.put()
  - Or Get.lazyPut() for lazy initialization
```

With:

```
Create [Feature]Provider:
  - Declare StateNotifierProvider / AsyncNotifierProvider
  - Export from providers/ file
  - No manual DI registration needed — Riverpod handles scoping via ProviderScope
```

#### 5. Planner agent (`planner.md`)

Update the implementation plan template. The step that creates bindings and registers controllers must become the step that creates provider files:

```
# Remove from plan template:
Phase 3: Presentation
  - Create [Feature]Controller (extends GetxController)
  - Create [Feature]Binding (extends Bindings)
  - Register binding in GetMaterialApp route

# Add:
Phase 3: Presentation
  - Create [feature]_provider.dart (AsyncNotifierProvider or StateNotifierProvider)
  - Create [Feature]Screen as ConsumerWidget
  - Register route in GoRouter (or chosen routing package)
```

#### 6. Code-reviewer agent (`code-reviewer.md`)

The code-reviewer checks for correct pattern adherence. Update the review criteria:

```
# Remove GetX-specific checks:
- Verifies Binding class registers all controllers used in the screen
- Checks RxList mutations use .assignAll(), not =
- Verifies IndexedStack controllers use permanent: true

# Add Riverpod-specific checks:
- Verifies ConsumerWidget is used when widget reads a provider
- Checks that ref.watch is used in build() and ref.read in callbacks
- Verifies providers are declared at the correct scope (not inside build())
```

#### 7. `docs/memory/error_learnings.md`

Mark GetX-specific entries as superseded. Do not delete them — they document real mistakes that happened. Add a one-line note above each GetX entry:

```
## [SUPERSEDED — GetX removed] [Date] RxList must use .assignAll() not =
```

This preserves the historical record while preventing agents from applying old rules to new code. The developer agent reads `error_learnings.md` during its Pre-Step — a superseded entry prevents it from treating the old rule as active.

### What stays the same

| Component | Why it doesn't change |
|-----------|----------------------|
| Clean Architecture layers (domain / data / presentation) | Layer separation is framework-independent |
| Domain use cases (`LoginUseCase`, `FetchProfileUseCase`) | Use cases are pure Dart — no framework dependency |
| Repository pattern | Repositories return entities; the state management layer consumes them |
| TDD approach (RED → GREEN → REFACTOR) | Testing strategy is independent of the state management library |
| Gate logic in all agents | DATA GATE, compliance grep, instruction loading gate — none reference GetX APIs |
| Memory system | Claude Mem and auto-memory store decisions, not library-specific patterns |
| `docs/FR/` files | FR files document requirements, not implementation patterns |
| `docs/backend_issues/` folder | Backend issue tracking is independent of frontend state management |

### Update order

```
1. Update ARCHITECTURE.md (authoritative source — agents derive from this)
      ↓
2. Update UI_INSTRUCTION.md (design system + reactive widget patterns)
      ↓
3. Update CLAUDE.md (zero-tolerance compliance table)
      ↓
4. Update developer agent (widget placement gate + implementation loop)
      ↓
5. Update planner agent (implementation plan template)
      ↓
6. Update code-reviewer agent (review criteria)
      ↓
7. Mark superseded entries in error_learnings.md
      ↓
8. Run migration test (see Validation section)
```

> **CRITICAL:** Do not update agents before updating ARCHITECTURE.md. Agents reference ARCHITECTURE.md as their authoritative source. If an agent is updated to generate Riverpod code while ARCHITECTURE.md still describes GetX patterns, the code-reviewer will flag every new widget as a violation.  
> If violated: the developer agent generates correct Riverpod code, the code-reviewer rejects it, and the agent loop stalls waiting for a fix that isn't needed.

---

## 20.3 — Updating Any Other Component

### When this applies

You change a pattern, library, or convention that is not the folder structure or state management. Examples:

- Replacing `http` package with `dio` for HTTP
- Replacing `hive_flutter` with `isar` for local storage
- Changing the localization approach (e.g., from `flutter_localizations` + string files to `slang`)
- Replacing `shadcn_ui` with a different UI component library
- Changing the environment variable approach

### The general protocol

Every component referenced by name in the agent setup must be updated when that component changes. The steps are the same regardless of what the component is:

**Step 1 — Identify every reference**

Run a grep across all agent files, CLAUDE.md, and instruction files for the old component name:

```bash
grep -rn "hive" .claude/agents/
grep -rn "hive" CLAUDE.md
grep -rn "hive" docs/instructions/
```

Every line returned is a required update. There are no optional ones — if a file references the old component by name, an agent will use that reference to generate code or make review decisions.

**Step 2 — Update instruction files first**

Follow the same principle as 20.1 and 20.2: update the instruction files (`ARCHITECTURE.md`, `UI_INSTRUCTION.md`) before updating agent files. Agents derive their behavior from the instruction files.

**Step 3 — Update agent files**

For each agent file with references:

- **Developer agent:** update the instruction loading step (what it reads), the widget placement gate (if the component has UI-level patterns), and the implementation loop (the file generation steps)
- **Code-reviewer agent:** update the review criteria for the component
- **Planner agent:** update the implementation plan template for any phases that reference the component

**Step 4 — Update `error_learnings.md`**

Mark component-specific entries as superseded using the same format as 20.2.

**Step 5 — Run a validation test**

Create a minimal new feature that uses the new component. Verify the developer agent generates code for the new component, not the old one. Verify the code-reviewer does not flag the new code as a violation.

### Scope estimation table

Use this to estimate how many files need updating:

| Component type | Typical files to update | Notes |
|---------------|------------------------|-------|
| UI component library (e.g., `shadcn_ui`) | UI_INSTRUCTION.md, developer agent, code-reviewer | Low impact if components are wrapped in your own widgets |
| HTTP client (e.g., `http` → `dio`) | ARCHITECTURE.md, developer agent, API_INSTRUCTION.md | Medium impact — data layer only |
| Local storage (e.g., `hive` → `isar`) | ARCHITECTURE.md, developer agent, code-reviewer, error_learnings.md | Medium impact — data layer + type system |
| Localization approach | CLAUDE.md, developer agent, UI_INSTRUCTION.md | High impact — affects every screen |
| Routing library | ARCHITECTURE.md, developer agent, planner agent | High impact — affects every feature |

---

## Validation

### Validation Test 1: Folder Architecture Change

**Purpose:** Verify the developer agent generates files in the new folder structure, not the old one.

**Setup:** Complete all steps in section 20.1. Have at least one existing module in the OLD folder structure — this tests that the agent uses the new structure for new work, not the old structure for consistency with what's already there.

**Trigger:**
```
develop [NewTestModule]
```

Replace `[NewTestModule]` with a module name that has no existing files anywhere in `lib/`.

**Expected result:**
- The developer agent's implementation loop creates files under the NEW path structure
- No files are created under `lib/src/features/` if you migrated away from feature-first
- `flutter analyze` runs clean

**If you see old paths:**
→ The developer agent's implementation loop still has old path references. Re-read the developer agent file and run the grep from the Risk section to find the missed references.

---

### Validation Test 2: State Management Change

**Purpose:** Verify the developer agent generates new-library code and the code-reviewer does not reject it.

**Setup:** Complete all steps in section 20.2 in the specified order. Do not have any existing Riverpod (or new library) files in the project yet — this test is for a fresh module.

**Trigger:**
```
develop [NewTestModule]
```

**Expected result:**
- Developer agent generates provider files, not GetX controller/binding files
- No `extends GetxController`, no `Get.put()`, no `Obx()` in generated code
- Code-reviewer runs without flagging the new code as a violation
- `flutter analyze` runs clean

**If you see GetX code generated:**
→ The developer agent's widget placement gate or implementation loop still references GetX patterns. Re-read the developer agent file and grep for `GetxController`, `Obx`, `Get.put`, `Binding` — update every match.

**If code-reviewer rejects valid new code:**
→ The code-reviewer's review criteria still includes GetX compliance checks. Update the code-reviewer agent's criteria section.

---

### Validation Test 3: Other Component Change (General)

**Purpose:** Verify the developer agent uses the new component in generated code.

**Trigger:**
```
develop [NewTestModule]
```

**Expected result:**
- Developer agent uses the new component (e.g., `dio` for HTTP calls, `isar` for local storage)
- Old component is not imported in any generated file
- `flutter analyze` runs clean

**If the old component appears in generated code:**
→ Run the grep from Step 1 in section 20.3 again. Find the missed reference in the developer agent and update it.

---

## Common Mistakes

### Mistake 1: Updating ARCHITECTURE.md but not the agent files

**Symptom:** `ARCHITECTURE.md` describes the new pattern. The developer agent generates code in the old pattern. The code-reviewer may or may not catch it depending on which file it reads.

**Cause:** Developers update the documentation correctly but assume agents will "pick up" the change automatically. Agents read instruction files during their Pre-Step, but they also have hardcoded path patterns and code generation templates in their own files.

**Fix:** After updating `ARCHITECTURE.md`, run the grep commands from section 20.1 or 20.2 on all agent files. Update every match.

---

### Mistake 2: Updating agents in the wrong order

**Symptom:** The code-reviewer flags new code as a violation even though the developer agent generated it correctly.

**Cause:** The developer agent was updated to generate new patterns, but the code-reviewer was not updated. The code-reviewer still checks for GetX (or feature-first) compliance.

**Fix:** Follow the update order in the relevant section. Instructions files first, then developer agent, then planner, then code-reviewer. The code-reviewer is last because it validates the output of the developer — it must be aligned with what the developer is now generating.

---

### Mistake 3: Deleting GetX error_learnings entries instead of marking them superseded

**Symptom:** A GetX-specific mistake reappears in a new module — the team forgot why the old convention existed, so the same failure mode reappears.

**Cause:** Error learnings were deleted when the state management was changed, removing the institutional knowledge of why certain patterns were dangerous.

**Fix:** Mark entries as superseded, never delete them. Use the `[SUPERSEDED — GetX removed]` prefix. The historical record is valuable even after the library is replaced.

---

### Mistake 4: Not running the validation test before writing new features

**Symptom:** Two or three features are built after the architecture change, and all of them have mixed patterns — some files follow the new structure, some follow the old, because the developer agent was not fully updated.

**Cause:** The validation test was skipped to save time. The partial update was not caught until it had propagated across multiple modules.

**Fix:** The validation test takes 5 minutes. Run it as the final step of every architectural update. The `develop [NewTestModule]` trigger and the file inspection that follows is the only reliable way to confirm that all agent files are in sync.

---

### Mistake 5: Forgetting `agents.md` during a folder architecture change

**Symptom:** The developer agent and planner generate files in the correct new location. But reviewer gate scope contracts in `agents.md` reference the old paths — the code-reviewer is scoped to `lib/src/features/` and misses files in `lib/src/modules/`.

**Cause:** `agents.md` contains scope examples that are easy to overlook because they look like documentation rather than active instructions. But Main Claude uses those scope examples to tell code-reviewer and security-reviewer exactly which files to review.

**Fix:** After updating the agent files, grep `agents.md` for folder path references. Update every scope example to the new path pattern.

---

## Reference

| Item | Value |
|------|-------|
| Files to update (folder architecture) | `ARCHITECTURE.md`, `developer.md`, `planner.md`, `agents.md` |
| Files to update (state management) | `ARCHITECTURE.md`, `UI_INSTRUCTION.md`, `CLAUDE.md`, `developer.md`, `planner.md`, `code-reviewer.md`, `error_learnings.md` |
| Update order rule | Instruction files first, agent files second, code-reviewer last |
| Validation command | `develop [NewTestModule]` — inspect generated files for old patterns |
| Grep to find missed references | `grep -rn "[old_pattern]" .claude/agents/ CLAUDE.md docs/instructions/` |
| What never changes | Gate logic, domain/data/presentation layers, TDD approach, memory system, FR docs structure |

---

*Next: [Chapter 21: Mistakes & Lessons Learned]*
