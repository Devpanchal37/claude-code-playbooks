# Chapter 14: Docs Folder Structure

> **Applies to:** Both
> **Prerequisites:** Chapter 9: Orchestra Management, Chapter 10: Core Agents Deep Dive
> **Estimated read + setup time:** ~35 minutes

---

## TL;DR

The `docs/` folder is agent-maintained documentation — not files you write manually. Each file has a single owner agent that writes it on a defined trigger. When ownership is violated (an agent writes to a file it does not own), documentation becomes unreliable and agents start making decisions based on stale or contradictory data. Set this structure up at project start, enforce ownership, and your agents will always work from accurate documentation.

---

## What This Is

The `docs/` folder is a structured documentation system where every file is owned, maintained, and read by specific agents. It is not a general-purpose wiki, a place to drop notes, or a manually maintained dev journal.

Every file in this system answers one of three questions agents ask before acting:

1. **What has already been built?** (`FR/_pipeline_status.md`)
2. **What patterns should I follow?** (`instructions/`, `memory/error_learnings.md`)
3. **What exists so I don't duplicate it?** (`memory/component_registry.md`, `memory/api_registry.md`)

The complete folder structure:

```
docs/
├── FR/
│   ├── _pipeline_status.md          ← single source of truth for all work status
│   ├── _fr_template.md              ← reference only (never modified by agents)
│   └── [module]/
│       ├── [Feature]_Flow_Requirements.md
│       ├── [Feature]_API_Requirements.md
│       └── [Feature]_Implementation_Tasks.md
├── instructions/
│   ├── ARCHITECTURE.md              ← manual: folder structure, layer rules
│   ├── UI_INSTRUCTION.md            ← manual: color system, fonts, spacing
│   └── API_INSTRUCTION.md           ← manual: base URL, auth headers, error format
├── maps/
│   └── project_map.md               ← project-map agent only
├── memory/
│   ├── error_learnings.md           ← most important: every non-obvious mistake
│   ├── component_registry.md        ← every reusable widget registered here
│   ├── api_registry.md              ← every API endpoint registered here
│   └── project_overview.md          ← manual: high-level business context
└── backend_issues/
    └── backend_issues.md            ← systematic-debugger (backend bugs only)
```

### How It Compares to the Auto-Memory System

These two systems coexist and serve different purposes.

| | `docs/` folder | `.claude/projects/memory/` |
|--|---------------|---------------------------|
| **Who writes it** | Agents (and 3 manual files) | Main Claude auto-saves |
| **What it stores** | Project registries, FR docs, status, mistakes | User preferences, feedback, session decisions |
| **Readable by** | All agents at any time | Main Claude at session start |
| **Scope** | Project-wide, committed to git | Per-developer, gitignored |
| **Format** | Structured per-file conventions | Free-form Markdown |

---

## Why It Exists (The Problem It Solves)

**Without this structure:**

Agents invent their own documentation approach. One agent creates `COMPONENTS.md` at the root. Another creates `docs/widgets/button.md`. A third stores nothing. By week 3, three separate files describe overlapping information, none of them current. Agents reading these files get contradictory answers and make contradictory decisions. The developer ends up maintaining documentation manually — which defeats the entire purpose of an agentic setup.

**With this structure:**

Every agent knows exactly where to write, exactly where to read, and exactly what format to use. You write nothing in `docs/` except the three manual instruction files. All registries, status tracking, and error records are written and maintained by agents.

The concrete benefit: a new session starts with a fresh context window. The developer agent loads `error_learnings.md` and immediately knows 15 past mistakes to avoid. It loads `component_registry.md` and skips creating a widget that already exists. It loads `api_registry.md` and uses an endpoint implemented 3 features ago. Without these files, every session starts from zero.

### What This Does NOT Do

- It does not replace version control. Git history is authoritative for what code changed. `docs/` is authoritative for what patterns, registries, and business decisions exist.
- It does not replace inline code documentation. These files explain conventions and track state — not what individual functions do.
- It does not auto-update when you write code manually. Agents update these files as part of their post-implementation workflow. If you write code without using the developer agent, you must update the relevant registry files yourself.

---

## How It Works (Ownership Model)

Every file in `docs/` has exactly one owner. Ownership means: **only the owner agent writes to this file**. Other agents may read any file, but only the owner may modify it.

Why ownership matters: when multiple agents write to the same file, each uses its own interpretation of the format, its own scope judgment, and its own understanding of what belongs there. The result is a file that has grown organically but is no longer authoritative for anything. Agents that rely on it for decisions will sometimes get correct answers and sometimes get noise — which is worse than having no file at all, because the noise masks the signal.

The full ownership table is at the end of the Setup section. Before designing any new agent, verify that its instructions reference only the correct owned files for modification.

---

## Setup

### Prerequisites Check

- [ ] `docs/` directory does not yet exist (or you are starting the structure fresh)
- [ ] Flutter project is initialized with git
- [ ] You have decided which module to implement first (needed for `_pipeline_status.md` initial entry)

### Step-by-Step

1. Create the folder structure:

```bash
mkdir -p docs/FR
mkdir -p docs/instructions
mkdir -p docs/maps
mkdir -p docs/memory
mkdir -p docs/backend_issues
```

2. Create all required files as stubs:

```bash
touch docs/FR/_pipeline_status.md
touch docs/FR/_fr_template.md
touch docs/instructions/ARCHITECTURE.md
touch docs/instructions/UI_INSTRUCTION.md
touch docs/instructions/API_INSTRUCTION.md
touch docs/maps/project_map.md
touch docs/memory/error_learnings.md
touch docs/memory/component_registry.md
touch docs/memory/api_registry.md
touch docs/memory/project_overview.md
touch docs/backend_issues/backend_issues.md
```

3. Seed each file with its header and format. The formats are in the subsections below.

4. Commit the empty structure to git so all agents start from the same baseline.

---

### FR/ Folder

The `FR/` folder contains all feature requirements and the pipeline status tracker. It is the contract between what was planned and what was built.

#### \_pipeline\_status.md

The single source of truth for the entire development pipeline. Every feature that has been requested, planned, built, or rejected is tracked here. Agents read this at session start to find the current task. They write to it after every state change.

**Status codes:**

| Code | Meaning |
|------|---------|
| ⏳ PENDING | FR written, not started |
| 🔄 IN_PROGRESS | Currently being implemented |
| 👀 REVIEW | Implementation done, awaiting human validation |
| ✅ DONE | Human approved |
| 🔁 REWORK | Rejected, needs fixes |

**Seeding format:**

```markdown
# 📊 Pipeline Status
> AI updates this after every FR state change.
> Human checks this for overall progress at a glance.

---

## Status Legend

| Icon | Meaning |
|------|---------|
| ⏳ PENDING | Not started |
| 🔄 IN_PROGRESS | AI currently working |
| 👀 REVIEW | Done — waiting for human validation |
| ✅ DONE | Human approved |
| 🔁 REWORK | Rejected — needs fixes |

---

## [ModuleName] Module

| Feature | FR File | Status | Notes |
|---------|---------|--------|-------|
| Feature A | `FR/module/FeatureA_Flow_Requirements.md` | ⏳ PENDING | |
```

**Who writes it:** FR analyst (sets initial PENDING entries), developer agent (transitions to IN_PROGRESS, writes CHECKPOINT entries, sets REVIEW), doc-updater (transitions to DONE after quality loop passes), human (sets REWORK manually when rejecting a review).

**What breaks if it's wrong or missing:** Agents implement features that are already done. Sessions resume from the beginning instead of from a checkpoint. The developer agent cannot find the active task on session start and either asks the human (wasted time) or picks the wrong task.

#### CHECKPOINT Entries

For tasks spanning 4 or more files, the developer agent writes CHECKPOINT entries into the Notes column as each major phase completes. This enables session resumption at any point.

**Format:**

```
[CHECKPOINT] Completed: domain layer (3 files). Next: data layer.
```

**Example Notes column with checkpoints:**

```
[CHECKPOINT] Completed: domain layer (3 files). Next: data layer.
[CHECKPOINT] Completed: data layer (4 files). Next: presentation layer.
```

**Why they matter:** A session interrupted mid-task (context window limit, machine sleep, timeout) has no way to resume at the right point without CHECKPOINT entries. The next session re-reads the entire feature FR, cannot tell what was already done, and either re-implements completed work or asks the human. Both are wasteful. CHECKPOINT entries turn a full restart into a targeted resume.

#### The Three FR Files

Each feature has exactly three FR files, stored in `docs/FR/[module]/`:

**1. `[Feature]_Flow_Requirements.md`**
- User journeys from trigger to completion
- Every UI state for every screen: loading, error, empty, success
- Edge cases and boundary conditions
- Navigation flow between screens
- Any cross-screen state updates triggered by actions in this feature

**2. `[Feature]_API_Requirements.md`**
- Every API endpoint this feature needs
- Request format: method, path, headers, body schema
- Response format: schema, field types, example payload
- Error cases: status codes, error messages, expected client handling

> **CRITICAL:** This file goes to the backend developer **before any Flutter work starts**. Never begin implementing a feature's Flutter code until the backend has confirmed the API requirements are feasible. Building on an unconfirmed API contract is the most expensive mistake in this workflow — see the Backend Verification Loop section below.

**3. `[Feature]_Implementation_Tasks.md`**
- Phase-by-phase breakdown of everything the developer agent must build
- Implementation order: domain first, data second, presentation third
- List of every file to be created or modified
- Testing requirements per phase

#### Backend Verification Loop

The API requirements verification loop is mandatory for every new feature that introduces new endpoints:

```
FR analyst writes [Feature]_API_Requirements.md
      ↓
Human shares API_Requirements.md with backend developer
      ↓
Backend developer reviews feasibility
      ├─ CONFIRMED → Flutter implementation starts
      └─ CHANGES NEEDED → Back to FR analyst
                              ↓
                          FR analyst updates API_Requirements.md
                              ↓
                          Human re-confirms with backend developer
                              ↓
                          Flutter implementation starts
```

**What this loop prevents:** You build 3 screens, a controller, and an API integration against an endpoint that doesn't exist in the form you specified. The backend delivers a different response shape. The entire data layer must be rewritten. A 15-minute backend review would have caught it before a single line was written.

**What "confirmed" means:** The backend developer has reviewed the exact endpoint, request/response schema, and has confirmed they can deliver it. A verbal "sounds fine" is not confirmation. Written sign-off — even a Slack reply saying "this API spec is implementable as written" — counts. Verbal doesn't.

---

### instructions/ Folder

These three files define the standards that every developer agent reads at session start. They are the **only manually maintained files** in the `docs/` system.

| File | What It Defines | Updated When |
|------|----------------|--------------|
| `ARCHITECTURE.md` | Feature folder structure, layer rules, naming conventions, DI patterns | Architecture changes: new folder convention, new layer rule, new naming standard |
| `UI_INSTRUCTION.md` | Color system, typography, spacing scale, component patterns, animation guidelines | Design system changes, new UI pattern established |
| `API_INSTRUCTION.md` | Base URL, authentication headers, request/response format, error handling pattern | New API pattern introduced, auth mechanism changes |

**The one-read-per-session rule:** These files are read ONCE at session start by the developer agent during its Instruction Loading step — not once per feature, not once per file written. The agent caches these rules in its working memory for the entire session. Re-reading them mid-session is pure token waste.

**When to update them:** Only when a system-level convention changes. Adding a new screen that follows existing conventions does not require an update. Introducing a new convention (new animation pattern, new error format, new API auth scheme) requires updating the relevant file.

> **WARNING:** These files are not updated by agents. If you let an agent modify `ARCHITECTURE.md`, it will record its own interpretation based on what it just built — which may not match the project-wide convention. These files are human-controlled contracts.

---

### memory/ Folder

The memory folder is the project's accumulated knowledge — past mistakes, existing components, and existing API implementations. Agents check these files before doing any work, not after.

#### error\_learnings.md

The most important memory file in the system. Every non-obvious mistake or unexpected behavior discovered during implementation is recorded here. The developer agent, systematic-debugger, and any other agent that solves a non-obvious issue during implementation writes to this file.

**Seeding format:**

```markdown
# 📚 Error Learnings
> AI reads this at EVERY session start before writing any code.
> When human corrects a mistake → add entry here immediately.

---
```

**Entry format:**

```markdown
## [YYYY-MM-DD] Short Title

**Mistake/Issue:** What went wrong or was non-obvious.
**Correct approach:** What should be done instead.
**Pattern:** The general rule going forward.
```

**Two triggers — both mandatory:**

1. **Human corrects a mistake:** The agent implements something wrong. The human corrects it. Immediately: implement the fix AND write the error learning. This prevents the same mistake in the next session.

2. **Agent encounters a non-obvious issue:** An agent solves something unexpected during implementation — a package behaved unexpectedly, a state pattern failed in a subtle way, an API response differed from spec. The agent writes the learning without waiting for human correction.

**What "non-obvious" means:** If a future developer with your experience level would make the same mistake without this entry, it belongs here. If the correct approach is obvious from reading the code or the package docs, it does not.

**What breaks if this file is skipped:** The same mistake recurs every 2–3 sessions. The agent makes the mistake, you correct it, the session ends, and the next session starts with no memory of the correction. This file is the only persistent record of corrections between sessions.

#### component\_registry.md

Every reusable widget created in the project is registered here after creation. The developer agent checks this file during its Pre-Step before creating any new widget.

**Seeding format:**

```markdown
# 🧩 Component Registry
> Check here BEFORE creating any widget, controller, entity, or model.
> If it exists here → REUSE IT. Never recreate.
> AI updates this file after EVERY completed feature.

---

## Shared Widgets (`lib/src/shared/widgets/`)

| Widget | File | Key Props | Used In |
|--------|------|-----------|---------|
```

**Example entries:**

```markdown
| `PrimaryButton` | `shared/widgets/primary_button.dart` | `label`, `onTap`, `isLoading`, `variant` | LoginScreen, SignupScreen |
| `UserAvatarWidget` | `shared/widgets/user_avatar_widget.dart` | `imageUrl`, `size`, `fallback` | ProfileScreen, ChatScreen |
```

**The reuse rule:** If a widget matching the needed component exists in the registry, the agent uses it — no exceptions. The agent never creates a `SubmitButton` when a `PrimaryButton` with equivalent props already exists. Duplicate widgets are a maintenance burden: style updates require touching every copy instead of one.

**What breaks if this file is skipped:** Agents create duplicate widgets with slightly different names on every feature. By feature 5, there are 3 different button implementations with different prop APIs. Standardizing them requires a manual refactor pass.

#### api\_registry.md

Every API endpoint implemented in the project is registered here. The developer agent checks this file before implementing any new API call.

**Seeding format:**

```markdown
# 🔌 API Registry
> Check here BEFORE implementing any API call.
> If it exists → use the existing implementation. Never duplicate.

---
```

**Example entries:**

```markdown
## UserModule Endpoints

| Endpoint | Method | Path | Request | Response | Used By |
|----------|--------|------|---------|----------|---------|
| Get User Profile | GET | `/api/v1/users/{id}` | `id` (path param) | `UserEntity` | `ProfileController` |
| Update Profile | PUT | `/api/v1/users/{id}` | `UpdateProfileDto` | `UserEntity` | `EditProfileController` |
```

**The reuse rule:** If the endpoint is already implemented, the agent calls the existing repository method — it does not create a second implementation of the same call. Duplicate endpoint implementations cause bugs when one is updated and the other is not.

---

### maps/ Folder

This folder contains exactly one file: `project_map.md`. It is described in full in [Chapter 13: Project Map]. In the context of the docs folder ownership system, the key rules are:

- **Owner:** `project-map` agent only — never edit manually
- **Updated:** after every Tier 3 change (new feature, shared file modification), triggered after `doc-updater` completes
- **Read by:** developer agent (Pre-Step for shared-file tasks), systematic-debugger (dependency check), code-reviewer (impact scoping)

---

### backend\_issues/ Folder

This folder is written exclusively by the `systematic-debugger` agent when it reaches Case B: **the API response itself is wrong** — not a Flutter-side parsing issue.

**File structure:** ONE file only — `backend_issues.md`. Never create per-issue files.

**Append-only rule:** Every confirmed backend bug is appended to the bottom of `backend_issues.md`. Entries are never edited or removed after creation. The append-only constraint means this file is a reliable audit trail — if an entry exists, the issue was confirmed with log evidence at a specific date.

**Entry format:**

```markdown
## [YYYY-MM-DD] [Short Title]

**Screen/Feature:** Which screen or feature this affects
**Description:** What the user sees that is wrong
**Endpoint:** `METHOD /api/v1/path`
**Expected:** What the response should contain
**Actual:** What the response actually contains (from API log)
**Evidence:** [Paste the exact API response log line here]
**Status:** Open
```

**Purpose:** This file is what the team shares with the backend developer. It contains only confirmed backend bugs — not hypotheses, not Flutter-side issues. Every entry has the API response log as evidence. The backend developer can reproduce the issue without needing additional context or a screen recording.

**When this folder is NOT used:** If `systematic-debugger` determines the bug is Flutter-side (the API response is correct but Flutter is parsing or displaying it wrong), no entry is created. That is a Case A bug — the developer agent fixes it in Flutter code.

> **CRITICAL:** Only `systematic-debugger` writes to `backend_issues.md`. If you find yourself writing to this file manually, or asking another agent to write to it, you have skipped the systematic-debugger's evidence confirmation step. An entry without confirmed API log evidence is not a bug report — it is a hypothesis, and hypotheses in this file mislead the backend team.

---

### Protected Files Ownership Table

Every file has exactly one owner. Ownership means write permission. All agents may read any file, but only the owner may write to it.

| File | Owner | When Written | Format |
|------|-------|--------------|--------|
| `FR/_pipeline_status.md` | FR analyst (initial) + developer + doc-updater | Every FR state change, every checkpoint | Status table; CHECKPOINT in Notes column |
| `FR/[module]/[Feature]_Flow_Requirements.md` | FR analyst | FR generation | User journeys, UI states, edge cases |
| `FR/[module]/[Feature]_API_Requirements.md` | FR analyst | FR generation | Endpoint specs, request/response schemas |
| `FR/[module]/[Feature]_Implementation_Tasks.md` | FR analyst | FR generation | Phase-by-phase task list |
| `instructions/ARCHITECTURE.md` | **Human** | Manual, on architecture change | Folder structure, layer rules, naming |
| `instructions/UI_INSTRUCTION.md` | **Human** | Manual, on design system change | Color system, typography, spacing |
| `instructions/API_INSTRUCTION.md` | **Human** | Manual, on API pattern change | Base URL, auth, error format |
| `maps/project_map.md` | `project-map` agent | After every Tier 3 change | Dependency matrix, blast radius tiers |
| `memory/error_learnings.md` | Developer agent + systematic-debugger + human | After non-obvious issue or human correction | `## [date] Title` + Mistake/Correct/Pattern entries |
| `memory/component_registry.md` | `doc-updater` | After every new widget created | Table: widget, file, props, used-in |
| `memory/api_registry.md` | `doc-updater` | After every new endpoint implemented | Table: endpoint, method, path, request, response, used-by |
| `memory/project_overview.md` | **Human** | Manual, initial setup and major pivots | Business context, product goals |
| `backend_issues/backend_issues.md` | `systematic-debugger` (Case B only) | After backend bug confirmed with log evidence | Date + title, Evidence entry |

**Why violating ownership breaks things:**

If `doc-updater` writes to `error_learnings.md`, it records only what it "noticed" from reading the output files — not what the developer agent actually discovered during the implementation process. These entries lack the "why it was non-obvious" context that makes them useful. Future agents read these entries and apply rules that don't match the actual situation.

If the developer agent writes to `component_registry.md` directly (instead of via doc-updater), the registry may be written mid-implementation before the widget API is finalized. The doc-updater writes after the full quality loop completes, when the final widget API is confirmed stable. Premature registry entries cause agents to reuse components with the wrong props.

---

## Validation

### Validation Test 1: Pipeline Status Is Found at Session Start

**Purpose:** Verify that `_pipeline_status.md` is set up with correct format and Main Claude reads it at session start.

**Trigger:** Start a new session and ask Main Claude: "What is the current task status?"

**Expected result:** Main Claude reads `docs/FR/_pipeline_status.md` and reports the features listed with their status codes. It does not guess or say "I don't see a status file."

**If you see instead:** "I couldn't find any pipeline status" or Main Claude makes up a status:
→ Verify the file exists with the correct header. Check that CLAUDE.md's Session Start Protocol explicitly names this file in Tier 1 (always read).

---

### Validation Test 2: Component Registry Reuse Check Fires

**Purpose:** Verify that the developer agent checks `component_registry.md` before creating any new widget.

**Setup:** Seed `component_registry.md` with at least one entry (e.g., a `PrimaryButton`). Then ask the developer agent to implement a screen that needs a button.

**Expected result:** The developer agent's Pre-Step either reads or greps `component_registry.md`. If a matching component exists, the agent references the existing widget instead of creating a new one.

**If you see instead:** The developer creates a new button widget without mentioning the registry:
→ Review the developer agent's Pre-Step instructions. The reuse check must be explicit: "Before creating any widget, grep `component_registry.md` for the component type. If a match exists, use it."

---

### Validation Test 3: Error Learning Written After Correction

**Purpose:** Verify the error learning protocol fires when you correct a mistake.

**Trigger:** Let the developer agent produce an output with something wrong, then correct it: "That's incorrect because [reason]. The right approach is [correct]."

**Expected result:** Before moving on to the next step, the agent appends a correctly formatted entry to `docs/memory/error_learnings.md` with the date, title, Mistake/Issue, Correct approach, and Pattern fields.

**If you see instead:** The correction is acknowledged verbally but nothing is written to the file:
→ Add a mandatory trigger to CLAUDE.md: "When human corrects any mistake → immediately append to `error_learnings.md` before doing anything else."

---

### Validation Test 4: Backend Verification Gate Acknowledged

**Purpose:** Verify that the workflow acknowledges the backend verification requirement before development starts on a feature with new endpoints.

**Trigger:** Ask the FR analyst to generate requirements for a new feature. When the three FR files are produced, check whether the workflow mentions backend review of `API_Requirements.md` before implementation starts.

**Expected result:** Either a confirmation gate in CLAUDE.md explicitly pauses and asks "Has backend confirmed the API requirements?", or the developer agent checks for a confirmation note in the FR file before beginning.

**If you see instead:** Developer agent launches immediately after FR generation with no mention of backend verification:
→ Add a confirmation gate to CLAUDE.md between FR generation and development start: "For new features with new API endpoints — confirm with human that backend has reviewed `API_Requirements.md` before launching developer agent."

---

## Common Mistakes

### Mistake 1: Writing to a file owned by another agent

**Symptom:** A registry entry has the wrong format, describes things that don't exist yet, or is inconsistent with other entries in the same file.  
**Cause:** A non-owner agent wrote to the file. Each agent uses its own format interpretation and scope judgment when writing outside its lane.  
**Fix:** Identify which agent wrote the incorrect entry (check git blame or session history). Delete it. Re-run the correct owner agent to regenerate the entry in the proper format.

---

### Mistake 2: Instructions files re-read on every feature instead of once per session

**Symptom:** High token usage on sessions that implement multiple features. The developer agent reads `UI_INSTRUCTION.md` and `ARCHITECTURE.md` repeatedly within the same session.  
**Cause:** Developer agent instructions say "read the instruction files" without specifying "once per session."  
**Fix:** Update the developer agent's Instruction Loading step: "Read `UI_INSTRUCTION.md`, `ARCHITECTURE.md`, `API_INSTRUCTION.md` once at session start. Cache these in working memory. Do not re-read them during the session."

---

### Mistake 3: Skipping the backend verification loop

**Symptom:** A feature is 70% implemented when the backend informs you that the API endpoint will have a different response shape.  
**Cause:** Implementation started before the backend confirmed the API requirements file.  
**Fix:** For the current feature: negotiate the response shape and update the data layer. For future features: enforce the verification gate in CLAUDE.md as a mandatory step between FR generation and implementation start.

---

### Mistake 4: Creating per-issue files in backend\_issues/

**Symptom:** The `backend_issues/` folder contains 15 files: `bug_1.md`, `profile_loading_issue.md`, `checkout_error_2026.md`, etc.  
**Cause:** Agent or human created a new file per issue instead of appending to `backend_issues.md`.  
**Fix:** Consolidate all entries into `backend_issues.md` in the correct format. Delete the per-issue files. Add an explicit rule to the systematic-debugger agent: "Always append to `docs/backend_issues/backend_issues.md`. Never create new files in this folder."

---

### Mistake 5: Missing CHECKPOINT entries for long tasks

**Symptom:** A 6-file implementation session is interrupted. The next session starts from scratch because there is no record of what was completed.  
**Cause:** Developer agent completed each phase without writing CHECKPOINT entries to `_pipeline_status.md`.  
**Fix:** Add to the developer agent's per-feature loop: "After completing each file in a 4+ file task, append a CHECKPOINT entry to the Notes column of `_pipeline_status.md`: `[CHECKPOINT] Completed: [phase]. Next: [what remains].`"

---

### Mistake 6: error\_learnings.md not checked at session start

**Symptom:** The same class of mistake recurs across sessions (wrong state pattern, hardcoded value, wrong widget usage).  
**Cause:** Developer agent's Pre-Step does not explicitly check `error_learnings.md`.  
**Fix:** Add to the developer agent's Pre-Step: "Read `docs/memory/error_learnings.md`. Grep for the current module or feature name. Apply any matching patterns before writing any code."

---

### Mistake 7: Manually editing project\_map.md

**Symptom:** After a manual edit to `project_map.md`, the blast radius tiers are inconsistent with the actual codebase. An agent reads the map, gets wrong dependency data, and misses a call site during a refactor.  
**Cause:** Developer edited the map directly instead of letting the `project-map` agent regenerate it.  
**Fix:** Revert the manual edit. Trigger the `project-map` agent to regenerate the map from current source. Add a rule to CLAUDE.md: "Never manually edit `docs/maps/project_map.md`. Trigger `project-map` agent regeneration instead."

---

## [Flutter-GetX Specifics]

### Implementation\_Tasks.md Extensions

In Flutter + GetX + Clean Architecture projects, every `[Feature]_Implementation_Tasks.md` must include two additional tables that are not required in generic Flutter projects.

#### New Locale Keys Required

```markdown
## New Locale Keys Required

| Key | English Value | Screen(s) Used |
|-----|--------------|----------------|
| `featureName_title` | "Feature Title" | FeatureNameScreen |
| `featureName_emptyState` | "Nothing here yet" | FeatureNameScreen |
| `featureName_errorRetry` | "Try again" | FeatureNameScreen |
| `featureName_loadingHint` | "Loading..." | FeatureNameScreen |
```

**Why at FR stage:** If locale keys are not planned before implementation starts, developers hardcode strings directly in widget files. Hardcoded strings are a zero-tolerance UI compliance violation in this stack. Planning all keys at FR stage ensures the developer agent registers every key in the localization file before placing any string in a widget — a post-hoc hunt for hardcoded strings is expensive and easy to miss.

#### New Model Keys Required

```markdown
## New Model Keys Required

| Class | Constant | Storage Scope | Value |
|-------|----------|---------------|-------|
| `FeatureModelKeys` | `kFeatureId` | Hive `featureBox` | `'feature_id'` |
| `FeatureModelKeys` | `kFeatureStatus` | Hive `featureBox` | `'feature_status'` |
| `SettingsModelKeys` | `kFeatureEnabled` | Hive `settingsBox` | `'feature_enabled'` |
```

**Why at FR stage:** Key name collisions between Hive boxes cause silent data corruption — one feature reads or overwrites another feature's stored value. Planning all keys in advance with their storage scope prevents two features from using the same key string for different data.

---

### 5-Phase Implementation Order

In `[Feature]_Implementation_Tasks.md`, all work must be phased in this exact order. The developer agent follows this sequence without deviation:

```
Phase 1 — Models
  Entity classes, DTOs, model key constants
  Domain layer: pure Dart, no Flutter dependencies
  
Phase 2 — API Layer
  Repository interface (domain)
  Repository implementation (data)
  Data source calls, endpoint wiring
  
Phase 3 — Screens
  Controller, bindings
  Screen file(s), widget tree
  
Phase 4 — Locale Keys
  Register all new keys in the localization ARB/Dart files
  Verify every string in Phase 3 screens has a corresponding key

Phase 5 — Navigation
  Register routes in app_pages.dart / app_routes.dart
  Update any screens that navigate to new routes
```

**Why this order is non-negotiable:** Domain entities must exist before data layer repository implementations can reference them. Controllers must exist before screens can use them. Locale keys must be registered before the localization file is compiled. Navigation routes must be registered before any `Get.toNamed()` calls are valid. A developer agent that implements Phase 3 before Phase 1 will encounter missing import errors on every file, causing it to guess at solutions instead of following a clean dependency chain.

**How to write it in the FR file:** Each phase is a numbered header with a sub-list of every file to create or modify:

```markdown
## Implementation Phases

### Phase 1 — Models
- [ ] Create `lib/src/features/feature_name/domain/entities/feature_entity.dart`
- [ ] Create `lib/src/features/feature_name/data/models/feature_model.dart`
- [ ] Create `lib/src/core/constants/feature_model_keys.dart`

### Phase 2 — API Layer
- [ ] Add `getFeatureItem(String id)` to `FeatureRepository` interface
- [ ] Implement in `FeatureRepositoryImpl`
- [ ] Add endpoint constant to `ApiConfig`

### Phase 3 — Screens
- [ ] Create `FeatureController` with required observables
- [ ] Create `FeatureBinding`
- [ ] Create `FeatureScreen`

### Phase 4 — Locale Keys
- [ ] Add all keys from "New Locale Keys Required" table to `languages_en.dart`
- [ ] Add corresponding keys to all other language files

### Phase 5 — Navigation
- [ ] Add route constant to `AppRoutes`
- [ ] Add `GetPage` entry to `AppPages`
- [ ] Update any callers that navigate to this screen
```

---

### Cross-Screen Events Table in Flow\_Requirements.md

For features that update state across multiple screens — for example, an action in one screen that removes a card from a list in another screen, or an update that refreshes a badge count elsewhere — add a Cross-Screen Events table to `[Feature]_Flow_Requirements.md`.

```markdown
## Cross-Screen Events

| Event Name | Fired By | Consumed By | Trigger Condition |
|------------|----------|-------------|-------------------|
| `onItemAccepted` | `ItemDetailController` | `BrowseListController` | User taps Accept button |
| `onProfileUpdated` | `EditProfileController` | `ProfileController` | User saves profile changes |
| `onUnreadCountChanged` | `ChatController` | `NavigationController` | New message received |
```

**Why at FR stage:** If two developers independently name the same logical event differently, the controller that fires it and the controller that listens for it never connect. This class of bug is invisible until integration testing because each screen appears to work correctly in isolation. Agreeing on event names before any code is written prevents the mismatch entirely.

**Why this is GetX-specific:** Cross-screen state broadcasting via EventBus is a GetX pattern. Other state management approaches (Riverpod, BLoC) use different mechanisms (providers, streams) for cross-widget communication, and the specific solution depends on the mechanism. This table only makes sense when the team has agreed on the GetX EventBus pattern for cross-screen updates.

---

## Reference

| Item | Value |
|------|-------|
| Root folder | `docs/` |
| Pipeline status | `docs/FR/_pipeline_status.md` |
| FR files location | `docs/FR/[module]/` (3 files per feature) |
| Instructions (manual) | `docs/instructions/` — ARCHITECTURE.md, UI_INSTRUCTION.md, API_INSTRUCTION.md |
| Memory folder | `docs/memory/` |
| Project map | `docs/maps/project_map.md` |
| Backend issues | `docs/backend_issues/backend_issues.md` |
| Status codes | ⏳ PENDING → 🔄 IN_PROGRESS → 👀 REVIEW → ✅ DONE → 🔁 REWORK |
| Checkpoint format | `[CHECKPOINT] Completed: [phase]. Next: [next phase].` |
| Error learning format | `## [YYYY-MM-DD] Title` + `**Mistake/Issue:**` + `**Correct approach:**` + `**Pattern:**` |
| Component registry format | Table: Widget \| File \| Key Props \| Used In |
| Ownership rule | One owner per file. Only the owner writes to it. All agents may read. |
| GetX: Locale keys table | Required in every Implementation_Tasks.md under "New Locale Keys Required" |
| GetX: Model keys table | Required in every Implementation_Tasks.md under "New Model Keys Required" |
| GetX: Implementation phases | Models → API → Screens → Locale Keys → Navigation |
| GetX: Cross-screen events | Table in Flow_Requirements.md: Event \| Fired By \| Consumed By \| Trigger |

---

*Next: Chapter 15: Skills*
