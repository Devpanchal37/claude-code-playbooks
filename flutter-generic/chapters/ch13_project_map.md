# Chapter 13: Project Map

> **Applies to:** Both
> **Prerequisites:** Chapter 9: Orchestra Management, Chapter 12: Auto-Memory System
> **Estimated read + setup time:** ~40 minutes

---

## TL;DR

The project map is a Markdown file at `docs/maps/project_map.md` that maps every shared file — API layer, entities, utilities, constants, shared components — to every file in the codebase that depends on it. Before any agent touches a shared file, it reads the map to know the blast radius of the change. A dedicated background agent regenerates the map automatically after every feature. Without it, a field rename in a shared entity silently queues 12 compile errors across 8 screens — discovered only after the change is already made.

---

## What This Is

The project map is a **dependency matrix**, not a file tree. Your IDE already shows you a file tree. What the map shows you is: *"If I change this file, what breaks?"*

It lives at `docs/maps/project_map.md` and is generated entirely by the `project-map` agent — never written manually. The map answers one question for every shared file: which other files import it, what they use from it, and which category of change will break them.

The file has four sections:

1. **Module Inventory** — all modules, their development status, screens owned, and which API groups they consume
2. **User Journey Map** — the complete navigation flow from app launch, showing how modules connect
3. **Entity Dependency Table** — for each shared entity or model, which modules import it
4. **Deep Change Impact Matrix** — the most important section: every shared file classified by blast radius tier, with a callers table and a precise list of what breaks and what doesn't

### How It Compares to the Component Registry

These two documentation files coexist and serve different purposes.

| | `docs/maps/project_map.md` | `docs/memory/component_registry.md` |
|--|---------------------------|--------------------------------------|
| **Managed by** | `project-map` agent | `doc-updater` agent |
| **Tracks** | Shared files → which files import them | Reusable widgets → where they're used |
| **Purpose** | Blast radius before touching shared files | Reuse — find existing widget before creating a new one |
| **Updated when** | After every Tier 3 change | After every new widget is created |
| **Read by** | Developer, code-reviewer, systematic-debugger | Developer (Pre-Step reuse check) |

---

## Why It Exists (The Problem It Solves)

**Without the project map:**

A developer renames a field in `UserEntity` from `profileImageUrl` to `avatarUrl`. It's a 30-second edit. They run `flutter analyze`. Eleven errors. Eight screen files, three controller files, one repository file — all of them reference `profileImageUrl`. The developer spends 40 minutes tracing and fixing every call site. If any call site is in a file they didn't think to check, the bug reaches runtime.

**With the project map:**

Before the rename, the developer agent reads the project map's entry for `UserEntity` during its Pre-Step. The callers table lists 12 files. The Dangerous Changes section explicitly states: "Renaming any field → all 12 call sites break." The developer plans the update to include all 12 files from the start. `flutter analyze` returns clean on the first run.

**The critical insight:** The project map is consulted BEFORE the change, not after. Discovering blast radius after a change means you're already in cleanup mode.

### What This Does NOT Do

- It does not replace `flutter analyze`. The map tells you what will break logically — the compiler tells you what breaks syntactically.
- It does not track feature-local files. A controller that is only used by its own screen is not in the map.
- It does not replace `docs/memory/component_registry.md`. The registry tracks UI widget reuse. The map tracks shared code dependencies.
- It is not manually maintained. Never edit `project_map.md` directly — always let the agent regenerate it.

---

## How It Works

The `project-map` agent operates in two modes depending on when it's invoked.

**Mode 1: Automatic (Quality Loop Phase 4b)**

```
doc-updater (Phase 4a) completes
      ↓
project-map agent launches in background (Phase 4b)
      ↓
Agent reads modified shared files + Dart source tree + FR files + registries
      ↓
Agent extracts public interface (function signatures, field names, constants)
      ↓
Agent greps for all callers / importers of each modified file
      ↓
Agent classifies blast radius tier for each shared file
      ↓
Agent writes updated section(s) in docs/maps/project_map.md
      ↓
Output: summary of updated sections + highest-impact files flagged
```

**Mode 2: On-demand (before touching a shared file)**

```
Developer agent or Main Claude requests blast radius for a specific file
      ↓
project-map reads current project_map.md entry for that file
      ↓
Agent runs targeted grep to verify callers are current
      ↓
Output: targeted blast radius report
      (does NOT rewrite the full map — report only)
```

> **NOTE:** The agent does NOT rewrite the entire map on every run. It updates only the sections that correspond to files that changed. A project with 20 shared files regenerates only the entry that changed — not all 20.

> **CRITICAL:** doc-updater and project-map must run sequentially, never in parallel. The project-map agent reads what doc-updater just wrote (component registry, API registry). Running them in parallel means project-map reads stale registry data.  
> If violated: the Entity Dependency Table will be one feature behind indefinitely.

---

## The Deep Change Impact Matrix

This is the most important section in `project_map.md`. Each entry documents one shared file.

### Entry Format

```markdown
## api_service.dart
**Path:** `lib/src/core/services/api_service.dart`
**Type:** API Layer — HTTP client shared by all features
**Blast Radius Tier:** Tier 1 (entire app affected)
**Last Updated:** 2026-04-20

### Public Interface
| Symbol | Type | Notes |
|--------|------|-------|
| get(endpoint, params) | Future<Response> | Base GET method |
| post(endpoint, body) | Future<Response> | Base POST method |
| authHeader | Map<String, String> | Injected on every request |

### Callers (files that import or use this)
| File | What it uses | Impact if interface changes |
|------|-------------|----------------------------|
| lib/src/features/profile/data/profile_repository.dart | get(), post() | HIGH — all network calls break |
| lib/src/features/chat/data/chat_repository.dart | get(), post() | HIGH — all network calls break |
| lib/src/features/dashboard/data/discover_repository.dart | get() | HIGH — discover feed breaks |
| [6 more files...] | | |

### Safe Changes (won't break callers)
- Adding new optional parameters with default values
- Adding new helper methods that don't change existing signatures
- Improving internal error handling without touching the public API

### Dangerous Changes (will break callers)
- Renaming `get()` or `post()` → all 9 repository files break immediately
- Adding a required parameter → all 9 call sites must be updated
- Changing the `Response` return type → all callers that parse the response break
- Removing `authHeader` → auth stops working on all API calls silently
```

### Blast Radius Tiers

Every shared file is classified into one of four tiers. The tier determines how broadly a change ripples.

| Tier | Label | What it means | Examples |
|------|-------|---------------|---------|
| **Tier 1** | Entire app | Every module depends on this. A breaking change here requires touching files in every feature. | HTTP client, auth session store, color/typography helpers, environment config |
| **Tier 2** | Multiple modules | Used by 3+ modules but not every module. Changes break a specific set of features. | Shared entities (UserEntity), shared API endpoints used by several features, cross-module utilities |
| **Tier 3** | Single module | Used across multiple files within one feature (controller + screen + repository), but not outside that feature. | Module-level base repository, feature-specific model, module-level shared component |
| **Tier 4** | File-local | Defined and consumed in the same file. No external blast radius. | Private helper functions, local formatting constants, file-scoped enums |

> **CRITICAL:** Only Tier 1, 2, and 3 files have entries in the project map. Tier 4 files are file-local — no entry is created for them.

### Change Type × Tier = Actual Risk

The tier tells you how broadly a change spreads. The change type tells you how bad the damage is. Combined:

| Change Type | Tier 1 | Tier 2 | Tier 3 |
|-------------|--------|--------|--------|
| Add new function/field | Low — no existing callers affected | Low | Low |
| Rename function/field | **CRITICAL** — every module breaks | HIGH — multiple modules break | HIGH — one module breaks |
| Change function signature | **CRITICAL** | HIGH | HIGH |
| Remove function/field | **CRITICAL** | HIGH | HIGH |
| Change return type | **CRITICAL** | HIGH | HIGH |
| Add required parameter | **CRITICAL** | HIGH | HIGH |

A Tier 1 rename is the most dangerous operation in the codebase. The project map makes this visible before the change is made.

---

## The Four Sections of project_map.md

### Section 1: Module Inventory

A table of every module in the project with its development status, screens, and API group ownership.

```markdown
## Module Inventory

| Module | Status | Screens | Owned API Group | Phase |
|--------|--------|---------|-----------------|-------|
| Auth | ✅ DONE | Login, OTP, Onboarding 1–4 | Auth, OTP, Profile Setup | Complete |
| Dashboard | 👀 REVIEW | Dashboard (tabs: Home, Profile) | Dashboard, Feed | In Progress |
| Profile | 🔄 IN_PROGRESS | Profile Detail, Edit Profile | User Profile, Photos | In Progress |
| Chat | ⏳ PENDING | Chat List, Chat Room | Conversations, Messages | Pending |
```

Status codes: `⏳ PENDING`, `🔄 IN_PROGRESS`, `👀 REVIEW`, `✅ DONE`, `🔁 REWORK`

### Section 2: User Journey Map

An ASCII flow diagram of the complete navigation from app launch. Every screen and every navigation branch is shown. This is the single document that answers "how does the user get from app open to screen X?"

```markdown
## User Journey Map

[App Launch]
  ↓
[Splash] — session recovery
  ↓
  ├─→ [Auth Flow] — no token
  │    ├→ Login
  │    ├→ OTP Verification
  │    └→ Onboarding Steps 1–4
  │
  └─→ [Dashboard] — token exists
       ├→ Tab 0: Home Feed
       ├→ Tab 1: Profile
       └→ [Profile Detail Screen] (pushed from Tab 0)
```

### Section 3: Entity Dependency Table

A cross-reference table showing which modules import each shared entity. This is the fast answer to "if I add a field to UserEntity, which modules do I need to test?"

```markdown
## Entity Dependency Table

| Entity | Auth | Dashboard | Profile | Chat | Notes |
|--------|------|-----------|---------|------|-------|
| UserEntity | ✅ (login result) | ✅ (card display) | ✅ (edit form) | ✅ (participant) | 4 modules — Tier 2 |
| MessageEntity | ❌ | ❌ | ❌ | ✅ (message list) | 1 module — Tier 3 |
| ConfigEntity | ✅ | ✅ | ✅ | ✅ | All modules — Tier 1 |
```

### Section 4: Deep Change Impact Matrix

Detailed entries for every shared file — the format described above in the Entry Format section. One entry per shared file, with public interface, callers table, safe changes, and dangerous changes.

---

## Setup

### Prerequisites Check

- [ ] `docs/maps/` directory exists in your project
- [ ] You have a list of every shared file in your project (API layer, shared entities, utilities, design tokens, shared components)

### Step 1: Create the Agent File

Create `.claude/agents/project_map.md`:

```markdown
---
name: project-map
description: Regenerate docs/maps/project_map.md after any Tier 3 change that touched a shared file. Produces a blast-radius map of all shared files and their callers. Runs in background after doc-updater (Phase 4b of quality loop).
tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
model: sonnet
---

## Identity

Regenerate `docs/maps/project_map.md` — the blast-radius dependency matrix — after any change to shared files, so the next agent knows the full impact before touching anything.

Does NOT do:
- Update component_registry.md, api_registry.md, or error_learnings.md (that is doc-updater)
- Review code quality
- Run before a change (on-demand mode produces a report only — the map update happens after)
- Create entries for feature-local files

## Shared Files This Agent Maps

[List every shared file here — see Customizing the Agent section]

## Full Workflow

[5-step workflow — see Customizing the Agent section]
```

### Step 2: Define the Shared File List

This is the most critical configuration. Open the agent file and set the shared file list to match your project:

```markdown
## Shared Files This Agent Maps

lib/src/core/services/api_service.dart           → HTTP client, used by all repositories
lib/src/core/utils/app_constants.dart             → App-wide constants
lib/src/shared/entities/user_entity.dart          → User data shape, used by 4+ modules
lib/src/core/helpers/color_helper.dart            → Design tokens, used by all widgets
lib/src/shared/widgets/primary_button.dart        → Shared UI component
```

> **WARNING:** If you add a new shared file but don't add it to this list, the agent will never map it. Updating this list is part of the "create new shared file" workflow — not optional.

### Step 3: Add the 5-Step Workflow to the Agent

The agent follows five steps on every run:

```markdown
## Full Workflow

STEP 1: Read current docs/maps/project_map.md (understand existing structure, note stale entries)

STEP 2: For each shared file that changed, extract its public interface:
  - Functions: extract signatures (name, parameters, return type)
  - Models/Entities: extract field names and types
  - Constants: extract constant names
  - Components: extract constructor signature and required parameters

STEP 3: Find all callers for each changed file:
  grep -rn "import.*[shared_file_name]" lib/ --include="*.dart"
  grep -rn "[ClassName]" lib/ --include="*.dart"   # for entities
  grep -rn "[functionName](" lib/ --include="*.dart"  # for specific functions

STEP 4: Build the impact matrix entry:
  - Classify tier (Tier 1–3) based on how many modules import the file
  - Build callers table (file path, what it uses, impact severity)
  - List Safe Changes (won't break callers)
  - List Dangerous Changes (will break callers — be specific)

STEP 5: Write updated section(s) to docs/maps/project_map.md
  - Update only changed file sections (do not rewrite the entire map)
  - Update the Shared Files Index table at the top (caller count, last updated)
  - Output a summary of what sections were updated
```

### Step 4: Register in agents.md

In `.claude/rules/common/agents.md`, add the Phase 4b entry in the quality loop:

```markdown
## Post-Implementation Quality Loop

| Phase | Agent | Mode | When |
|-------|-------|------|------|
| 4a | doc-updater | background | Always after Tier 3 |
| 4b | project-map | background | After doc-updater; always for Tier 3 changes |

## Sequential Execution (must not be parallelized)
- doc-updater → project-map (project-map reads what doc-updater writes)
```

### Step 5: Add the Pre-Step to the Developer Agent

In `.claude/agents/developer.md`, add this to the Pre-Step section:

```markdown
### Pre-Step: Project Map Check (shared files only)

If this task modifies any shared file (shared entity, API service, utility, shared component):
1. Read `docs/maps/project_map.md` once
2. Find the entry for the shared file being modified
3. Read the Callers table — note every file that will be affected
4. Read the Dangerous Changes list — confirm what breaks
5. Adjust the implementation plan to include all affected callers

One Read is sufficient for the entire map — do not re-read per shared file.
```

---

## The One-Read Rule

The project map is designed to be consumed in a single Read operation. One file — one read — answers cross-module blast-radius questions for every shared file in the project.

**Never start with Grep/Glob for cross-module analysis.** Grep finds files that literally contain the searched string — it misses indirect dependencies (a file that imports a file that uses the changed symbol). The project map explicitly traces these indirect chains because the agent follows import paths, not just string matches.

Use Grep/Glob as a fallback only when the project map doesn't have an entry for the specific file in question.

---

## Validation

### Validation Test 1: Map Has Correct Structure

**What to do:** Read `docs/maps/project_map.md`.

**Expected result:** The file contains all four sections: Module Inventory, User Journey Map, Entity Dependency Table, Deep Change Impact Matrix. Each shared file in your project has an entry in the Matrix.

**If the file doesn't exist:**
→ The project-map agent hasn't run yet. Ask Main Claude: "Trigger the project-map agent to generate the initial map from scratch."

**If sections are missing:**
→ Check the agent file's STEP 5 template to verify it writes all four sections.

### Validation Test 2: Callers Table Is Accurate

**What to do:** Pick one known shared file. Manually grep for its importers:

```bash
grep -rn "import.*your_shared_file" lib/ --include="*.dart"
```

**Expected result:** Every file returned by grep appears in the project map's Callers table for that file.

**If grep returns files not in the map:**
→ The agent's STEP 3 grep patterns missed some files. Update the grep patterns in the agent file to match your project's import style. Trigger regeneration.

### Validation Test 3: Agent Fires After Tier 3 Change

**What to do:** Complete a Tier 3 feature. Observe the quality loop output. Confirm the project-map agent launched in background after doc-updater completed.

**Expected result:** Agent runs in Phase 4b. `docs/maps/project_map.md` is updated with new or modified entries.

**If the agent didn't fire:**
→ Check the agents.md registration for Phase 4b. Verify doc-updater's completion output triggers project-map.

---

## Common Mistakes

### Mistake 1: Manually editing project_map.md

**Symptom:** An entry is outdated. Developer edits one line directly to fix it.

**Cause:** The map looks like a normal Markdown file — it feels editable.

**Fix:** Never edit `project_map.md` directly. The next agent run will overwrite manual changes. Fix the source (the shared file list in the agent, or the grep patterns) and trigger regeneration.

---

### Mistake 2: Forgetting to add new shared files to the agent's list

**Symptom:** A new shared service was created and used in 5 modules. Three months later, a developer changes its interface. None of the 5 callers appear in the project map because the file was never added to the agent's list.

**Cause:** The agent only maps files in its configured shared file list. New files are invisible to it until added.

**Fix:** Update the agent's shared file list immediately whenever a new shared service, entity, or utility is created. Add this to the developer agent's completion checklist: "If I created a shared file → update the project-map agent's shared file list."

---

### Mistake 3: Running project-map in parallel with doc-updater

**Symptom:** The Entity Dependency Table is consistently one feature behind — it never reflects the most recently added module.

**Cause:** project-map reads the registries that doc-updater just wrote. Running them in parallel means project-map reads the old files.

**Fix:** Enforce sequential execution in agents.md. doc-updater must complete before project-map launches. Never use parallel mode for these two agents.

---

### Mistake 4: Using Grep instead of the project map for cross-module analysis

**Symptom:** Developer grepped for `UserEntity` and found 4 files. Changed the entity's field. 7 compile errors — 3 files weren't found by grep because they imported `UserEntity` via an intermediate file.

**Cause:** Grep searches string literals. It finds direct imports but misses indirect dependencies.

**Fix:** Read the project map first for cross-module questions. Grep is a fallback for files the map doesn't yet cover — not a replacement for the map.

---

### Mistake 5: Not consulting the map before modifying a Tier 1 file

**Symptom:** Developer makes what seems like a small behavioral change to the HTTP client. Multiple features fail at runtime, not at compile time.

**Cause:** Tier 1 files are touched by every module. A behavioral change (not a signature change) breaks callers in ways the compiler can't detect. The project map's Dangerous Changes list for Tier 1 files must include behavioral changes, not just signature changes.

**Fix:** For Tier 1 files, consult the project map before ANY change — including changes that don't alter the public API signature. Update the agent's STEP 4 to include runtime behavioral changes in the Dangerous Changes list for Tier 1 files.

---

## Reference

| Item | Value |
|------|-------|
| Map file | `docs/maps/project_map.md` |
| Managed by | `project-map` agent — never manually edited |
| Agent file | `.claude/agents/project_map.md` |
| Runs in | Background, Phase 4b (after doc-updater completes) |
| On-demand mode | Read map + targeted grep before a planned change — no map rewrite |
| Read by | Developer agent (Pre-Step), systematic-debugger (dependency check), code-reviewer (impact scoping) |
| One-read rule | Cross-module questions answered in one Read — do not use Grep first |
| Tier 1 | Entire app — HTTP client, auth session, design tokens, env config |
| Tier 2 | Multiple modules — shared entities, cross-module API functions |
| Tier 3 | Single module — module-level base repository, feature-specific model |
| Tier 4 | File-local — no entry in the map |

---

*Next: Chapter 14: Docs Folder Structure*
