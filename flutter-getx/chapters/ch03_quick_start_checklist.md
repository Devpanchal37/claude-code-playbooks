# Chapter 3: Quick Start Checklist

> **Applies to:** Both
> **Prerequisites:** None — this chapter is the starting point
> **Estimated read + setup time:** ~45 minutes

---

## TL;DR

This chapter gets the minimum viable agentic setup working in one session. You create nine things — `CLAUDE.md`, `settings.json`, Claude Mem MCP, the `docs/` folder, four stub files, one agent, and one orchestra entry — and then verify the developer agent fires correctly. Nothing else on day 1. The full system described in the rest of this playbook is built incrementally on top of this foundation.

---

## Before You Start

### Prerequisites

- [ ] Claude Code CLI installed (`claude --version` returns a version number)
- [ ] Project is a git repository (`git status` works in the project root)
- [ ] A basic Flutter project exists (`pubspec.yaml` present)
- [ ] Node.js installed (required for Claude Mem MCP)

### What You Are Building

```
[project-root]/
├── CLAUDE.md                        ← Step 2
├── .claude/
│   ├── settings.json                ← Step 3
│   ├── agents/
│   │   └── developer.md             ← Step 7
│   └── rules/
│       └── common/                  ← empty for now
└── docs/                            ← Steps 5–6
    ├── FR/
    │   └── _pipeline_status.md
    ├── instructions/
    │   ├── ARCHITECTURE.md          ← seeded with GetX structure (Step 6)
    │   └── UI_INSTRUCTION.md        ← seeded with compliance rules (Step 6)
    ├── maps/
    ├── memory/
    │   ├── error_learnings.md
    │   ├── component_registry.md
    │   └── api_registry.md
    └── backend_issues/
```

This is the entire day-1 footprint. Everything else in this playbook is added on top of this after your first feature is working.

---

## The Setup Sequence

Work through these nine steps in order. Each step has a verification — do not proceed to the next step until the verification passes.

---

### Step 1 — Create the directory structure

```bash
mkdir -p .claude/agents
mkdir -p .claude/rules/common
mkdir -p docs/FR
mkdir -p docs/instructions
mkdir -p docs/maps
mkdir -p docs/memory
mkdir -p docs/backend_issues
```

**Verify:** `ls .claude/` shows `agents/`, `rules/`, and nothing else yet. `ls docs/` shows `FR/`, `instructions/`, `maps/`, `memory/`, `backend_issues/`.

---

### Step 2 — Create CLAUDE.md

Create `CLAUDE.md` at the **project root** (not inside `.claude/`). This is the minimum viable content:

```markdown
# CLAUDE.md

## Role

You are the orchestra conductor. You delegate to agents. You do NOT write code
in the main conversation.

All code is written by the developer agent — even single lines, small fixes,
and simple components.

---

## Session Start Protocol

### Tier 1 — Always read (every session)
1. `docs/FR/_pipeline_status.md` — find the current active task
2. `docs/memory/error_learnings.md` — check for patterns that apply to current task

---

## Development Workflow

**CRITICAL: Never write code manually. Always delegate to the developer agent.**

| Request Pattern | Agent | Mode |
|----------------|-------|------|
| "develop [module]" | developer | foreground |
| "implement [feature]" | developer | foreground |
| "add [component]" | developer | foreground |
| "bug:: [description]" | systematic-debugger | foreground |

---

## Critical Rules

### RULE 1 — Never touch native folders

NEVER read, create, edit, or delete any file inside:
- `android/`
- `ios/`

These folders are managed by the Flutter toolchain.
Any change to these folders can break the build in ways that are hard to reverse.

---

## Error Learning Protocol

When human corrects a mistake:
1. Implement the fix
2. Append an entry to `docs/memory/error_learnings.md`
3. Confirm: "Learned. Added to error_learnings.md: [one-line summary]"
```

**Verify:** Run `claude` in the project root. In the first response, Main Claude should acknowledge it read CLAUDE.md (it will often reference the session start protocol or the role definition).

> **NOTE:** This is intentionally minimal. Resist the urge to add more rules on day 1. You don't yet know which rules your project needs. Add rules as you discover patterns — see [Chapter 4: CLAUDE.md File] for how to grow this file correctly.

---

### Step 3 — Create settings.json

Create `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Read(**)",
      "Write(**)",
      "Edit(**)",
      "Grep(**)",
      "Glob(**)",
      "Bash(flutter analyze)",
      "Bash(flutter test)",
      "Bash(dart format *)",
      "Bash(git status)",
      "Bash(git log*)",
      "Bash(git diff*)",
      "Bash(mkdir*)",
      "Bash(touch*)"
    ]
  }
}
```

**Verify:** Start a new Claude session. When the developer agent runs `flutter analyze` or `dart format`, Claude should not pause to ask permission. If it asks, the tool pattern in the allow list doesn't match — check the exact command format.

> **CRITICAL:** The `Bash(flutter analyze)` pattern only allows that exact command. `Bash(flutter analyze --no-pub)` would be blocked. If agents use flags, add the specific pattern with the flag, or use `Bash(flutter analyze*)` to allow all variants.  
> If violated: agent pauses mid-task waiting for permission, breaking multi-file implementation flows.

See [Chapter 5: settings.json] for the full permissions reference and how to add hooks.

---

### Step 4 — Install Claude Mem MCP

Claude Mem provides persistent cross-session memory. Agents use it to remember past decisions, mistakes, and patterns across sessions.

```bash
claude mcp add claude-mem
```

Follow the prompts to configure the server. After installation, verify it appears in your MCP list:

```bash
claude mcp list
```

**Verify:** In a Claude session, ask: "Search your memory for anything related to this project." Claude should attempt a `smart_search` call — even if it returns empty results, the call itself confirms the MCP is connected.

If the MCP is not connected, agents still work but they lose cross-session memory. They will re-discover known mistakes instead of avoiding them. See [Chapter 11: MCP Plugins] for the full Claude Mem setup and configuration.

---

### Step 5 — Create the docs/ folder stubs

```bash
touch docs/FR/_pipeline_status.md
touch docs/instructions/ARCHITECTURE.md
touch docs/instructions/UI_INSTRUCTION.md
touch docs/instructions/API_INSTRUCTION.md
touch docs/maps/project_map.md
touch docs/memory/error_learnings.md
touch docs/memory/component_registry.md
touch docs/memory/api_registry.md
touch docs/backend_issues/backend_issues.md
```

**Verify:** `ls docs/memory/` shows all three memory files. `ls docs/FR/` shows `_pipeline_status.md`.

---

### Step 6 — Seed the minimum docs files

These files must have their headers before any agent uses them. An agent that opens an empty file may skip it or error silently.

**`docs/FR/_pipeline_status.md`:**

```markdown
# 📊 Pipeline Status
> AI updates this after every FR state change.
> Human checks this for overall progress at a glance.

## Status Legend

| Icon | Meaning |
|------|---------|
| ⏳ PENDING | Not started |
| 🔄 IN_PROGRESS | AI currently working |
| 👀 REVIEW | Done — waiting for human validation |
| ✅ DONE | Human approved |
| 🔁 REWORK | Rejected — needs fixes |

---
```

**`docs/memory/error_learnings.md`:**

```markdown
# 📚 Error Learnings
> AI reads this at EVERY session start before writing any code.
> When human corrects a mistake → add entry here immediately.

---
```

**`docs/memory/component_registry.md`:**

```markdown
# 🧩 Component Registry
> Check here BEFORE creating any widget, controller, entity, or model.
> If it exists here → REUSE IT. Never recreate.
> AI updates this file after EVERY completed feature.

---
```

**`docs/memory/api_registry.md`:**

```markdown
# 🔌 API Registry
> Check here BEFORE implementing any API call.
> If it exists → use the existing implementation. Never duplicate.

---
```

**Verify:** Open `docs/FR/_pipeline_status.md` in your editor. It should have the header and status legend, not be empty.

---

### Step 7 — Create the developer agent

Create `.claude/agents/developer.md`:

```markdown
---
name: developer
description: Flutter implementation specialist. Writes all feature code following CLAUDE.md conventions. Runs flutter analyze after every change. Use for any code writing request — develop, implement, add, create, fix.
tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
model: sonnet
---

# Developer Agent

You are the implementation specialist for this Flutter project.
You write all code. You follow the project conventions exactly.

## Pre-Step (mandatory before any code)

1. Read `docs/memory/error_learnings.md` — apply patterns that match the current task
2. Grep `docs/memory/component_registry.md` for widget types needed in this task
3. Grep `docs/memory/api_registry.md` for endpoints needed in this task
4. Read `docs/FR/_pipeline_status.md` — confirm the active task and its FR files

## Implementation Workflow

1. Read the feature's FR files from `docs/FR/[module]/` if they exist
2. Update `_pipeline_status.md` status to 🔄 IN_PROGRESS
3. Implement the feature following the project's existing conventions
4. After every file written: run `flutter analyze` and fix all issues before continuing
5. Update `_pipeline_status.md` status to 👀 REVIEW when done

## Documentation (mandatory after implementation)

- If new widget created: add entry to `docs/memory/component_registry.md`
- If new API endpoint added: add entry to `docs/memory/api_registry.md`
- If non-obvious issue solved: add entry to `docs/memory/error_learnings.md`

## What You Do NOT Do

- Investigate bugs (that is systematic-debugger's job)
- Make architectural decisions without a plan from the planner agent
- Write FR documents (that is fr-analyst's job)
- Skip `flutter analyze` — it runs after every single file, not just at the end
```

**Verify:** The file exists at `.claude/agents/developer.md`. The frontmatter block is at the top with name, description, tools, and model fields.

---

### Step 8 — Create agents.md with minimum orchestra entry

Create `.claude/rules/common/agents.md`:

```markdown
# Agent Orchestration

## Development Triggers

| Request Pattern | Agent | Mode |
|----------------|-------|------|
| "develop [module]" | developer | foreground |
| "implement [feature]" | developer | foreground |
| "add [component]" | developer | foreground |
| "create [file/class]" | developer | foreground |
| "bug:: [description]" | systematic-debugger → developer | foreground |
| "fix [bug]" (informal) | systematic-debugger → developer | foreground |

**CRITICAL: Never write code manually in the main conversation. All requests above
always go to the developer agent — even single lines, simple fixes, or quick additions.**

## Post-Implementation Quality

After developer agent marks 👀 REVIEW:
- Run `flutter analyze` — must be clean
- Human validates the feature
- If approved: update status to ✅ DONE
```

**Verify:** The file exists at `.claude/rules/common/agents.md` and contains the trigger table.

---

### Step 9 — First test: trigger the developer agent

In your Claude session, type exactly:

```
develop [FeatureName]
```

Replace `[FeatureName]` with a simple module name from your project.

**Expected result:**

1. Main Claude reads `CLAUDE.md` and identifies the `"develop [module]"` trigger
2. Main Claude launches the developer agent (foreground)
3. Developer agent runs its Pre-Step — reads `error_learnings.md`, greps the registries, reads `_pipeline_status.md`
4. Developer agent asks for the FR files or confirms the current task

**If Main Claude writes the code directly instead of launching the agent:**
→ The `agents.md` trigger table is not being read. Check that `CLAUDE.md` references `.claude/rules/common/agents.md` or directly includes the trigger routing logic.

**If the developer agent launches but skips the Pre-Step:**
→ The Pre-Step section is missing or the agent's Pre-Step instructions are not marked as mandatory. Review the agent file — the Pre-Step must be a numbered list, not a paragraph.

---

## Day 1 Scope Boundary

The setup above is complete. The following components exist in this playbook but should **not** be set up on day 1.

| Component | Why to skip | When to add |
|-----------|-------------|-------------|
| `project-map` agent | Needs existing codebase to map | After your first feature is merged |
| `code-review-graph` MCP | Needs code to index | After first feature — see [Chapter 16: Token Efficiency] |
| `ui-reviewer` agent | No screens to review yet | When first screen is complete |
| `code-reviewer` agent | No code to review yet | When first feature is REVIEW |
| `security-reviewer` agent | No auth/API code yet | When first API call is implemented |
| `fr-analyst` agent | Manually written FRs are fine early | When feature volume makes manual FR writing slow |
| `planner` agent | Single features don't need a plan yet | When a feature spans >3 files |
| All `.claude/rules/` files | No patterns established yet | Add a rule when a pattern repeats |
| `systematic-debugger` agent | No complex bugs yet | When first data mismatch bug appears |

**The failure mode of over-setup:** You spend 4 hours configuring 12 agents before writing a single line of code. Three agents conflict with each other. You debug the setup instead of the product. Start with one agent that works, ship one feature, then expand.

---

## You'll Know It's Working When...

Run through this checklist after completing all 9 steps. Each item is a binary pass or fail.

- [ ] `claude` starts in the project root and Main Claude references CLAUDE.md in its first response
- [ ] Typing `develop [module]` launches the developer agent (not Main Claude writing code directly)
- [ ] Developer agent's first action is reading `error_learnings.md` and the registries (Pre-Step)
- [ ] `flutter analyze` runs without Claude asking for permission
- [ ] `docs/FR/_pipeline_status.md` is read when you ask "what is the current task?"
- [ ] Claude Mem MCP responds when you ask Main Claude to search memory (even with empty results)
- [ ] `docs/memory/error_learnings.md` gets a new entry when you correct something the developer agent did wrong

If any item fails, the fix is always in the same place: the component whose job matches the failing item. Developer agent not loading Pre-Step → fix the agent file. `flutter analyze` asking permission → fix settings.json. Pipeline status not found → fix the Session Start Protocol in CLAUDE.md.

---

## Common Day-1 Mistakes

### Mistake 1: Agent file created but never fires

**Symptom:** You type "develop [module]" and Main Claude writes the code itself instead of launching the developer agent.  
**Cause:** The `agents.md` trigger table exists, but CLAUDE.md does not reference it. Main Claude never reads the routing rules.  
**Fix:** Add to CLAUDE.md's development workflow section: "For all code requests, follow the trigger table in `.claude/rules/common/agents.md`." Or add the trigger table directly in CLAUDE.md.

---

### Mistake 2: settings.json permissions too broad

**Symptom:** Running `claude` with an inherited or default settings.json that allows `Bash(**)` — everything. An agent accidentally runs `git reset --hard` or `flutter clean` during a routine task.  
**Cause:** `Bash(**)` is a wildcard that allows any shell command without confirmation.  
**Fix:** Replace `Bash(**)` with specific patterns for every command agents actually need. Add new patterns only when a specific command is blocked and you've verified it's safe.

---

### Mistake 3: CLAUDE.md at the wrong path

**Symptom:** Main Claude starts a session and says it cannot find CLAUDE.md, or ignores project-specific rules entirely.  
**Cause:** `CLAUDE.md` was placed inside `.claude/` instead of at the project root.  
**Fix:** Move `CLAUDE.md` to the project root. Claude Code looks for it at `[project-root]/CLAUDE.md`, not inside subdirectories.

---

### Mistake 4: docs files left empty

**Symptom:** Developer agent's Pre-Step silently passes without actually learning anything. Or agent reports an error opening the file.  
**Cause:** `error_learnings.md`, `component_registry.md`, or `api_registry.md` were created with `touch` but never seeded with their header.  
**Fix:** Add the header to each file (see Step 6). An agent that opens a file and finds it empty may treat it as non-existent or skip it.

---

### Mistake 5: Claude Mem MCP installed but not confirmed

**Symptom:** Agents attempt `smart_search` calls that fail silently. Past learnings from claude-mem are never applied.  
**Cause:** MCP was added to the config but the server process is not running, or the package name is wrong.  
**Fix:** Run `claude mcp list` and verify the claude-mem entry shows as connected. Restart the Claude session after any MCP config change — MCPs are loaded at session start.

---

### Mistake 6: CLAUDE.md over-specified on day 1

**Symptom:** CLAUDE.md grows to 200+ lines before the first feature is built. Half the rules are hypothetical ("if we ever add X, do Y"). Agents spend 30% of their context loading rules that never fire.  
**Cause:** Trying to write all rules upfront instead of adding them reactively.  
**Fix:** Delete any rule that has not yet been violated or needed. A rule earns its place in CLAUDE.md by solving a real problem. Every speculative rule is noise.

---

## What to Add Next (After Day 1)

Add these components in this order — only after the previous one is working reliably.

| When | Add | Why |
|------|-----|-----|
| After first feature ships | `code-reviewer` agent | First real code to review |
| After first bug appears | `systematic-debugger` agent | First data mismatch to investigate |
| After second feature | `fr-analyst` agent | Manual FR writing is getting slow |
| After third feature | `project-map` agent | Shared entities need blast-radius tracking |
| After first complex feature (>3 files) | `planner` agent | Need structured plans before coding |
| After first screen is built | `ui-reviewer` agent | Visual review before marking REVIEW |
| When agents make repeated mistakes | Add to `docs/memory/error_learnings.md` | Build up the correction history |
| When a rule repeats 3+ times | Add to `.claude/rules/common/` | Encode the pattern as a permanent rule |

Each addition follows the same pattern: create the agent file → register it in `agents.md` → add its trigger to CLAUDE.md if needed → test it with one real scenario. See [Chapter 8: Agent Creation Guide] for the creation process and [Chapter 9: Orchestra Management] for registration.

---

## [Flutter-GetX Specifics]

### Two Additional Files That Must Be Seeded on Day 1

In the generic setup, `docs/instructions/ARCHITECTURE.md` and `docs/instructions/UI_INSTRUCTION.md` are created as empty stubs and filled in over time. In the GetX + Clean Architecture stack, these two files are read by the developer agent on day 1 — before the first line of code is written. They must contain real content from the start, or the developer agent will invent its own folder structure and UI conventions.

**Why day 1, not later:** The developer agent's Instruction Loading step reads these files before implementing any screen or feature. An empty `ARCHITECTURE.md` means the agent doesn't know whether to use feature-first or layer-first folders, what the domain/data/presentation split looks like, or where to register GetX routes. It will guess — and the first feature will establish a pattern that is wrong and expensive to undo.

#### Seed `docs/instructions/ARCHITECTURE.md` with the GetX feature-first structure:

```markdown
# Architecture

## Folder Structure (Feature-First)

lib/
  src/
    core/
      constants/         ← app-wide constants, color helpers, image helpers
      theme/             ← ThemeData, color extensions
      locale/            ← localization ARB/Dart files
    features/
      [feature_name]/
        domain/
          entities/      ← pure Dart, immutable, no Flutter dependency
          repositories/  ← abstract interface only
          usecases/      ← one use case per file, one method per use case
        data/
          models/        ← DTO + fromJson/toJson + copyWith
          repositories/  ← implements domain repository interface
          datasources/   ← raw HTTP calls, Hive reads/writes
        presentation/
          controllers/   ← GetX controller, RxT observables, calls use cases
          screens/       ← one file per screen
          widgets/       ← screen-specific widgets only
          bindings/      ← GetX binding, registers controller and dependencies
    shared/
      widgets/           ← reusable across features

## Implementation Order (Non-Negotiable)

Always implement in this order:
1. Domain layer (entity → repository interface → use cases)
2. Data layer (model → datasource → repository implementation)
3. Presentation layer (controller → binding → screen → widgets)
4. Locale keys (register all new keys)
5. Navigation (register routes in app_pages/app_routes)

## GetX-Specific Rules

- IndexedStack tab controllers: always `Get.put(..., permanent: true)`
- Push-and-pop route controllers: never permanent
- RxList replacement: use `.assignAll()`, never `=` assignment
- One use case = one action (LoginUseCase not AuthUseCase)
- No logic in `build()` — all logic in controller
```

#### Seed `docs/instructions/UI_INSTRUCTION.md` with the zero-tolerance compliance rules:

```markdown
# UI Instructions

## Zero-Tolerance Violations

These are rejected immediately — no exceptions:

| Violation | Rule |
|-----------|------|
| `Color(0xFF...)` anywhere in lib/ | Use ColorHelper.xxx |
| `Colors.xxx` anywhere in lib/ | Use ColorHelper.xxx |
| String literals in widget files | Use locale.xxx |
| `fontFamily` other than the project font | Fix immediately |
| Missing shimmer on initial data load | Fix before REVIEW |

## ColorHelper

All colors come from `lib/src/core/constants/color_helper.dart`.
Never reference a color by hex value. Never use Flutter's built-in Colors class.

## Async Screen States (Required on Every Data Screen)

Every screen that loads data must implement all four states:
1. Loading → shimmer skeleton matching the success layout
2. Error → error message + retry button
3. Empty → empty state illustration + call-to-action
4. Success → the actual content

A screen with only Success state is incomplete.

## Font

The project uses a single font family for all text.
Never override fontFamily in any TextStyle.
```

**Verify:** Open each file in your editor and confirm the content is present. Run `claude` and ask: "What folder structure should I use for a new feature?" Main Claude should describe the feature-first GetX structure from `ARCHITECTURE.md`, not invent its own.

---

### ui-design-enforcer in the Day-1 Orchestra

In the GetX setup, add one extra row to your `agents.md` trigger table:

```markdown
| "develop [module]" (new screens) | ui-design-enforcer → developer | foreground |
```

The full updated Development Triggers table for the GetX setup:

```markdown
## Development Triggers

| Request Pattern | Agent | Mode |
|----------------|-------|------|
| "develop [module]" (new screens) | ui-design-enforcer → developer | foreground |
| "develop [module]" (no new screens) | developer | foreground |
| "implement [feature]" | ui-design-enforcer → developer | foreground |
| "add [component]" | developer | foreground |
| "create [file/class]" | developer | foreground |
| "bug:: [description]" | systematic-debugger → developer | foreground |
| "fix [bug]" (informal) | systematic-debugger → developer | foreground |
```

**Why ui-design-enforcer is day 1 in GetX:** The design enforcer runs four mandatory questions before any screen code is written: what tone, what makes it feel intentional, which UI constraints apply. In the GetX stack, the zero-tolerance violations (colors, fonts, locale keys) are enforced by the developer agent's Widget Placement Gate — but that gate operates best when the design direction is already committed. A developer agent that knows "this is a data-dense actionable screen with dark primary background" will place components with intention. A developer agent that just received "develop ProfileScreen" without design direction will produce a generic CRUD layout that passes the compliance gate but fails the design benchmark.

The ui-design-enforcer agent is created following the same process as the developer agent. See [Chapter 10: Core Agents Deep Dive — Section 10.5] for the full agent definition.

---

## Reference

| Item | Day-1 location | Status after Step 9 |
|------|---------------|---------------------|
| `CLAUDE.md` | Project root | ✅ Created with minimum content |
| `.claude/settings.json` | `.claude/` | ✅ Created with minimum permissions |
| Claude Mem MCP | Installed via `claude mcp add` | ✅ Installed and confirmed |
| `docs/` folder | Project root | ✅ Created with all subdirectories |
| `_pipeline_status.md` | `docs/FR/` | ✅ Seeded with header |
| `error_learnings.md` | `docs/memory/` | ✅ Seeded with header |
| `component_registry.md` | `docs/memory/` | ✅ Seeded with header |
| `api_registry.md` | `docs/memory/` | ✅ Seeded with header |
| `developer.md` | `.claude/agents/` | ✅ Created with Pre-Step and workflow |
| `agents.md` | `.claude/rules/common/` | ✅ Created with trigger table |
| `ARCHITECTURE.md` | `docs/instructions/` | ✅ **Seeded with GetX feature-first structure** |
| `UI_INSTRUCTION.md` | `docs/instructions/` | ✅ **Seeded with zero-tolerance compliance rules** |

---

*Next: Chapter 4: CLAUDE.md File*
