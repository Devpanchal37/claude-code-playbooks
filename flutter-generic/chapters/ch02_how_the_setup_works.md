# Chapter 2: How the Setup Works

> **Applies to:** Generic
> **Prerequisites:** [Chapter 1: Purpose & Philosophy]
> **Estimated read + setup time:** ~25 minutes (reading only — no hands-on setup in this chapter)

---

## TL;DR

Before configuring any individual component, you need to see how all nine components connect. This chapter is that map. It shows what each component is, what it connects to, and what breaks if it is missing. It also shows what happens inside Claude's reasoning on every single prompt — the six-step sequence that routes your message to the right agent, applies the right gates, and produces verified output. After this chapter you can draw the full system from memory. That understanding is what makes the setup in Chapter 3 stick.

---

## What This Is

Nine components. Three layers. One session lifecycle.

This chapter is not configuration. It is orientation. Every component you configure in the following chapters will make more sense because you can see where it fits in the system before you touch it.

The three layers:

| Layer | Components | Purpose |
|-------|-----------|---------|
| **Configuration** | CLAUDE.md, settings.json, hooks, .claude/rules/ | Defines identity, permissions, automation, and standards |
| **Orchestration** | .claude/agents/, agents.md | Specialized workers and the routing rules that dispatch them |
| **Memory** | docs/ folder, auto-memory/, MCP plugins | Persistent knowledge that survives session boundaries |

---

## Why It Exists (The Problem It Solves)

**Without this chapter:** developers set up individual components in isolation. CLAUDE.md is written but agents.md is missing — Main Claude has identity rules but no routing logic, so agents never fire. Or agents are created but the docs/ folder is absent — agents run but have no memory to read from, so every session starts from zero.

**With this chapter:** you understand which components depend on which before touching any of them. The setup order in Chapter 3 flows from this understanding, not from arbitrary convention.

### What This Does NOT Do

This setup does not automate:

- **Business decisions** — what the product should do, what the user journey should be, what edge cases matter. The human is responsible for these.
- **Design choices** — visual hierarchy, interaction patterns, typography decisions. The ui-design-enforcer asks questions, but the answers must come from the human.
- **Requirement clarity** — if a feature request is ambiguous, agents ask for clarification. They do not invent requirements to fill the gap.
- **Architecture direction** — for genuinely novel architectural decisions, the planner surfaces options and trade-offs. The human chooses.

Everything the setup automates is execution: writing code to a confirmed spec, reviewing code against defined rules, updating documentation, investigating bugs against runtime evidence.

---

## How It Works

### The Nine Components

Each component has one job. Removing any one breaks the system in a specific, diagnosable way.

**Configuration Layer**

| Component | Location | What It Does | What Breaks Without It |
|-----------|----------|--------------|------------------------|
| **CLAUDE.md** | Project root | Identity file Main Claude reads every session. Defines role, critical rules, workflow triggers, token efficiency rules. | Main Claude improvises — routing is inconsistent, agents fire randomly, critical rules are forgotten between sessions. |
| **settings.json** | `.claude/settings.json` | Permissions for tool use, hook registration, model selection. | Agents interrupted mid-workflow requesting permission for routine reads/writes. Hooks never fire. |
| **Hooks** | Registered in `settings.json` | Shell commands that run automatically before/after tool calls or at session end. | Automation disappears — code graph updates, format checks, and post-session reminders must be triggered manually every time. |
| **.claude/rules/** | `.claude/rules/common/` + language dirs | Layered coding standards all agents follow: immutability, naming, testing, security, git workflow. | Each agent invents its own interpretation of standards. Style and safety rules drift across sessions and agents. |

**Orchestration Layer**

| Component | Location | What It Does | What Breaks Without It |
|-----------|----------|--------------|------------------------|
| **.claude/agents/** | `.claude/agents/[name].md` | One file per specialized agent. Defines identity, gate sequence, tools, model, and output format. | Main Claude handles everything in one context window. Quality degrades, context fills fast, no gates enforce verification. |
| **agents.md (orchestra)** | `.claude/rules/common/agents.md` | Routing rules: which trigger pattern maps to which agent, in which mode (foreground/background). | Agent files exist but never fire. Main Claude does not know when to use them. |

**Memory Layer**

| Component | Location | What It Does | What Breaks Without It |
|-----------|----------|--------------|------------------------|
| **docs/ folder** | `docs/` | Structured documentation maintained by agents — FR files, memory registries, pipeline status, project map. Agents read from here at session start. | Agents have no persistent knowledge of the codebase. Every session re-discovers what already exists. Mistakes repeat. |
| **auto-memory/** | `~/.claude/projects/[project]/memory/` | File-based persistent memory for user preferences, feedback, project context. Separate from agent memory — per-developer, not committed. | Main Claude forgets user preferences, past corrections, and cross-session context on every new conversation. |
| **MCP plugins** | Configured in `settings.json` | External tools that extend Claude Code — Claude Mem (semantic cross-session database), code-review-graph (code structure index). | No searchable memory across projects. No structural code intelligence for impact analysis. |

---

### The Full System Map

```
┌───────────────────────────────────────────────────────────────────┐
│                        Claude Code Session                         │
│                                                                     │
│  CONFIGURATION LAYER                                                │
│  ┌──────────┐  ┌──────────────┐  ┌────────┐  ┌────────────────┐  │
│  │ CLAUDE   │  │ settings.json│  │ hooks  │  │ .claude/rules/ │  │
│  │   .md    │  │              │  │        │  │ common/ + lang/│  │
│  └────┬─────┘  └──────┬───────┘  └───┬────┘  └───────┬────────┘  │
│       │               │              │                │            │
│       └───────────────▼──────────────▼────────────────┘           │
│                        │                                            │
│                 ┌──────▼──────┐                                    │
│                 │ Main Claude │◄── agents.md (routing rules)       │
│                 │ (Conductor) │                                    │
│                 └──────┬──────┘                                    │
│                        │ launches (foreground or background)       │
│  ORCHESTRATION LAYER                                                │
│  ┌─────────────────────▼───────────────────────────────────────┐  │
│  │                   .claude/agents/                            │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐  │  │
│  │  │developer │ │debugger  │ │fr-analyst│ │ reviewers /   │  │  │
│  │  │          │ │          │ │          │ │ doc-updater / │  │  │
│  │  │          │ │          │ │          │ │ planner / ... │  │  │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬────────┘  │  │
│  └───────┼────────────┼────────────┼───────────────┼───────────┘  │
│          │            │            │               │               │
│          └────────────▼────────────▼───────────────┘              │
│                        │ read / write                              │
│  MEMORY LAYER                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │
│  │   docs/      │  │ auto-memory/ │  │      MCP plugins         │ │
│  │ error_learn  │  │ user prefs   │  │  claude-mem (database)   │ │
│  │ registries   │  │ feedback     │  │  code-review-graph       │ │
│  │ pipeline     │  │ project ctx  │  │  (structural index)      │ │
│  │ project_map  │  │              │  │                          │ │
│  └──────────────┘  └──────────────┘  └──────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

---

### The Session Lifecycle

What actually happens from the moment you type a message to the moment code is merged:

```
Developer types a message
         ↓
Main Claude reads CLAUDE.md
(every session, every message — mandatory)
         ↓
Main Claude checks auto-memory
(user preferences, past corrections, project state)
         ↓
Main Claude consults agents.md
Does this message match a trigger pattern?
         ↓
    ┌────┴────┐
   YES        NO
    ↓          ↓
Launches    Main Claude
correct     responds
agent       directly
(foreground
or background)
    ↓
Agent reads its memory
(error_learnings, component_registry,
 api_registry, claude-mem)
    ↓
Agent runs its gate sequence
(cannot be skipped — embedded in agent identity)
    ↓
    ┌────────────────────────┐
    │                        │
Foreground              Background
    ↓                        ↓
Output returns          Agent runs
to Main Claude          independently
    ↓
Main Claude coordinates
next step (correction loop,
quality loop, or summary)
    ↓
doc-updater runs (background)
Updates registries, pipeline status
    ↓
Developer receives final output
```

---

### The 6-Step Internal Reasoning Sequence

Every prompt triggers this sequence inside Claude — silently, before any visible response. Every rule in CLAUDE.md maps to one of these six steps.

```
1. CLASSIFY   → What type of prompt is this?
               (bug report? feature build? planning request? question?)

2. VERIFY     → Do I have enough context to act safely?
               (are memory files loaded? is the task clear? is scope confirmed?)

3. ROUTE      → Which path does this prompt take?
               (which agent? foreground or background? does a plan exist?)

4. GATE CHECK → Does anything block me from proceeding?
               (missing evidence? unconfirmed requirement? context near limit?)

5. ACT        → Execute the routed path
               (launch agent, respond directly, ask clarifying question)

6. VALIDATE   → Did the output meet the standard?
               (run quality loop? mark REVIEW? update documentation?)
```

Understanding these six steps is what makes CLAUDE.md rules legible. Each rule in CLAUDE.md targets a specific step. "Read `error_learnings.md` at session start" targets VERIFY. "Launch systematic-debugger for `bug::` messages" targets ROUTE. "Never proceed past a Confirmation Gate" targets GATE CHECK.

---

### The 5 Prompt Types

At the CLASSIFY step, every incoming message is assigned one of five internal labels. The label determines the entire downstream path.

| Prompt Type | Signal Words | Internal Label | What Fires |
|-------------|-------------|----------------|-----------|
| Bug report | `bug::`, `issue::`, `fix`, "wrong", "broken", "not working" | `BUG` | `systematic-debugger` → developer (correction pass) |
| Feature build | `develop`, `implement`, `build`, `add`, `create` | `BUILD` | plan check → developer pipeline |
| Requirement capture | Describes behavior without action verb | `CAPTURE` | `fr-analyst` |
| Planning request | `plan`, `design approach for`, `how would you structure` | `PLAN` | `planner` |
| Question / info | `what is`, `how does`, `explain`, `show me`, `why` | `INFO` | Main Claude answers directly — no agent |

**The `BUG` label has highest priority.** A message that sounds like a feature request but contains "it's broken" or "fix the" is classified as `BUG` and routes to systematic-debugger first — even if the message also contains BUILD signal words.

**The `CAPTURE` label triggers fr-analyst**, not the developer pipeline. Describing a feature without saying "build it" or "implement it" means you want requirements captured and documented first, not code written immediately. This is intentional — it creates the FR files the developer agent will read later.

> **NOTE:** The `INFO` label is the most underused. If you just want to understand something — how a component works, why a rule exists, what a file contains — phrase it as a question. No agent fires; Main Claude answers directly and cheaply.

---

### Session-Persistent vs. Session-Specific

Not everything survives between sessions. Knowing which components persist and which don't tells you what you can rely on across sessions and what must be explicitly passed.

| Component | Persists Between Sessions | Notes |
|-----------|--------------------------|-------|
| CLAUDE.md | ✅ Yes — read every session | Rules are re-loaded fresh each time |
| settings.json | ✅ Yes | Permissions and hook registration are permanent |
| .claude/rules/ | ✅ Yes | Agents read these on demand |
| .claude/agents/ | ✅ Yes | Agent files are permanent; agent *instances* are session-scoped |
| agents.md | ✅ Yes | Routing rules are permanent |
| docs/ folder | ✅ Yes | Agent-maintained files persist |
| auto-memory/ | ✅ Yes (file-based) | Written to disk — survives all sessions |
| claude-mem MCP | ✅ Yes (database) | Persistent across sessions and projects |
| Todo list | ❌ No — session-specific | Current task progress is lost when session ends |
| Agent context window | ❌ No | Each agent launch starts fresh |
| Mid-task state | ❌ No — unless checkpointed | `[CHECKPOINT]` lines in pipeline_status.md survive |

**The implication for mid-task interruptions:** if a session ends while the developer agent is implementing a 6-file feature, the work done so far is in the files. The agent's reasoning about what to do next is not. This is why agents write `[CHECKPOINT]` lines to `docs/FR/_pipeline_status.md` after every completed file in a large task — so the next session can resume from the exact stopping point.

---

### The Intelligence Hierarchy

Rules override in a specific order. Knowing this hierarchy explains why some rules are in CLAUDE.md and others are in agent files.

```
Level 1: CLAUDE.md rules
  → Override Claude's default behavior for the entire session
  → Apply to Main Claude at all times
  → Example: "Never write code directly — delegate to developer agent"

Level 2: agents.md routing rules
  → Override Main Claude's routing decisions
  → Apply when a trigger pattern is matched
  → Example: "bug:: always goes to systematic-debugger first, never developer"

Level 3: Agent file rules
  → Override Main Claude's instructions when the agent is running
  → Apply only within that agent's context window
  → Example: "DATA GATE fires before file reading — no exceptions"
```

**Why this matters in practice:** CLAUDE.md cannot override an agent's gate sequence. If the systematic-debugger's DATA GATE is written to fire unconditionally, Main Claude cannot instruct the agent to skip it by adding "check the source files first" to the prompt. The gate lives in the agent's identity, not in the prompt. This is by design — it is what makes the gates reliable.

---

### The Reuse-Before-Build System

For any `BUILD` prompt, before the developer agent writes a single file, three checks run:

```
BUILD prompt received
         ↓
1. Component registry check
   grep component_registry.md for the widget/component type
   → Found: use existing component — do not create a duplicate
   → Not found: proceed to create

2. API registry check
   grep api_registry.md for the endpoint pattern
   → Found: use existing API function — do not add a duplicate call
   → Not found: proceed to create

3. Shared model check
   grep shared models for the data shape required
   → Found: use existing entity — do not create a parallel one
   → Not found: proceed to create
```

This is not optional. A codebase where every session creates new widgets for the same purpose — because no agent checked what already exists — becomes unmaintainable within weeks.

---

### The Impact-Before-Change System

Before modifying any existing file, the blast radius must be known. Tools in priority order:

```
1. code-review-graph MCP (if available)
   get_impact_radius_tool — pre-indexed, one call, structural result
         ↓ if not available
2. docs/maps/project_map.md
   Check the Deep Change Impact Matrix — which modules depend on this file?
         ↓ if not covered
3. Grep fallback
   Search for the class/function name across the codebase
```

Starting with grep and working up is the wrong order. The graph and project map give structural impact — callers, dependents, test coverage — in fewer tokens and less time than grep.

---

## Setup

This chapter is orientation only. Hands-on setup begins in [Chapter 3: Quick Start Checklist].

### Required Tools

Before any configuration begins, confirm these are in place:

- [ ] **Claude Code CLI** installed and authenticated (`claude --version` returns a version number)
- [ ] **Git repository initialized** — Claude Code uses the repo root as the project root
- [ ] **Flutter project exists** — `pubspec.yaml` is present at the project root
- [ ] **Claude Mem MCP** available (install instructions in [Chapter 11: MCP Plugins]) — strongly recommended before first use; the setup works without it but has no cross-session semantic memory
- [ ] **code-review-graph MCP** (optional) — gives structural code intelligence for impact analysis and review

### What Gets Created During Setup

The configuration session in Chapter 3 creates this directory structure:

```
[project root]/
  CLAUDE.md
  .claude/
    settings.json
    rules/
      common/
        agents.md
        coding-style.md
        git-workflow.md
        testing.md
        security.md
    agents/
      developer.md
      systematic-debugger.md
      fr-analyst.md
      planner.md
      code-reviewer.md
      doc-updater.md
  docs/
    FR/
      _pipeline_status.md
    memory/
      error_learnings.md
      component_registry.md
      api_registry.md
    instructions/
      ARCHITECTURE.md
      UI_INSTRUCTION.md
      API_INSTRUCTION.md
    maps/
      project_map.md
```

You do not need all of this on Day 1. [Chapter 3] specifies the minimum viable subset and the order to add the rest.

---

## Validation

### Validation Test 1: The Component Map Test

**What to do:** Without looking at this chapter, name the nine components and which layer each belongs to.

**Expected answer:**
- Configuration: CLAUDE.md, settings.json, hooks, .claude/rules/
- Orchestration: .claude/agents/, agents.md
- Memory: docs/, auto-memory/, MCP plugins

**If you couldn't complete it:** Re-read the "Nine Components" section and the system map diagram. The three-layer structure is the organizing principle for everything that follows.

### Validation Test 2: The Route Tracing Test

**What to do:** A developer types: `"develop UserModule"`. Trace the exact path this message takes through the system — step by step, naming the components it touches.

**Expected answer:**
1. Main Claude reads CLAUDE.md (every session)
2. CLASSIFY step: signal word `develop` → `BUILD` label
3. Main Claude checks auto-memory for past decisions on UserModule
4. Main Claude consults agents.md — `BUILD` trigger found
5. Plan check: does `docs/FR/UserModule/*_Implementation_Plan.md` exist?
6. If yes: Main Claude launches developer agent (foreground)
7. Developer agent reads memory (error_learnings, component_registry, api_registry)
8. Developer agent applies reuse-before-build check
9. Developer agent runs gate sequence → writes code → compliance checks
10. Developer agent marks pipeline status REVIEW
11. Main Claude runs quality loop (code-reviewer → doc-updater background)
12. Developer receives final output

**If you couldn't trace it:** Re-read the "Session Lifecycle" diagram and the "5 Prompt Types" table together.

### Validation Test 3: The Automation Boundary Test

**What to do:** Name three things this setup does NOT automate.

**Expected answer (any three):** Business decisions, design choices, requirement clarity, architecture direction, approval of agent output, deciding what to build next.

**If you couldn't answer:** Re-read the "What This Does NOT Do" section. The boundary between what agents execute and what humans decide is the most important boundary in the system.

---

## Common Mistakes

### Mistake 1: Writing CLAUDE.md without agents.md

**Symptom:** CLAUDE.md is complete and detailed, but agents never fire. Main Claude follows the rules but makes routing decisions without any agent ever being launched.  
**Cause:** CLAUDE.md tells Main Claude who it is and what rules to follow. `agents.md` tells it which agents exist and when to use them. Without agents.md, there is no routing — Main Claude improvises.  
**Fix:** Every CLAUDE.md must reference agents.md as the routing authority. Create agents.md before expecting any agent to fire automatically. See [Chapter 9: Orchestra Management].

### Mistake 2: Treating agent files as self-activating

**Symptom:** Developer writes a detailed agent file, tests it manually, and it works — but it never fires on its own in normal sessions.  
**Cause:** Agent files define behavior. They do not define triggers. Triggers live in agents.md. An agent file without an agents.md entry is a Markdown file that never runs.  
**Fix:** Every new agent file creation requires a matching agents.md entry. See [Chapter 9: Orchestra Management] for the exact format.

### Mistake 3: Using foreground mode for everything

**Symptom:** Session feels slow. Main Claude waits for doc-updater and project-map agents before presenting results, even though their output isn't needed to answer the developer.  
**Cause:** Foreground mode blocks Main Claude until the agent completes. Appropriate for agents whose output is needed before the next step. Wasteful for documentation and mapping agents whose output is needed eventually but not immediately.  
**Fix:** doc-updater and project-map always run in background mode. Agents whose output feeds the next step (systematic-debugger → developer, planner → developer, reviewer → correction loop) run foreground. See [Chapter 9: Orchestra Management].

### Mistake 4: Skipping the memory layer

**Symptom:** Setup works for one session. By session 5, agents are repeating mistakes from session 2, creating widgets that already exist, and re-opening architectural debates that were already resolved.  
**Cause:** The orchestration layer (agents) depends on the memory layer (docs/, auto-memory/, claude-mem) to carry knowledge across sessions. An agent that has no memory to read starts every session from zero.  
**Fix:** Create `error_learnings.md`, `component_registry.md`, and `api_registry.md` before running any agent. Install claude-mem MCP before the first complex session. See [Chapter 11: MCP Plugins] and [Chapter 14: Docs Folder Structure].

---

## [Flutter-GetX Specifics]

The nine components are identical in this playbook. Two aspects of the setup have GetX-specific content already wired in:

**An additional rules layer:** `.claude/rules/flutter/` contains a `coding-style.md` that extends the common coding standards with GetX-specific rules — permanent controllers, Obx reactivity scope, `RxList` mutation patterns. This file is read by the developer agent and code-reviewer before any Flutter file is touched.

**Flutter-specific instruction files in docs/instructions/:** This playbook's setup includes three developer-maintained files in `docs/instructions/` that are absent from a generic setup:

| File | Contents |
|------|----------|
| `ARCHITECTURE.md` | Feature-first folder structure, three-layer Clean Architecture, GetX binding and controller conventions |
| `UI_INSTRUCTION.md` | Color system, typography rules, spacing, shimmer states, animation standards |
| `API_INSTRUCTION.md` | HTTP client patterns, response handling, endpoint registration convention |

These files are read by the developer agent during its instruction-loading gate (Step 0 — before any code is written). They are maintained by the human developer, not by agents, because they define project-specific standards that agents enforce but do not invent.

---

## Reference

| Item | Value |
|------|-------|
| **Three layers** | Configuration · Orchestration · Memory |
| **Nine components** | CLAUDE.md, settings.json, hooks, .claude/rules/, .claude/agents/, agents.md, docs/, auto-memory/, MCP plugins |
| **Session lifecycle entry point** | Every message → CLASSIFY → VERIFY → ROUTE → GATE CHECK → ACT → VALIDATE |
| **Prompt type that fires no agent** | `INFO` — questions answered directly by Main Claude |
| **Prompt type with highest priority** | `BUG` — always routes to systematic-debugger first |
| **Intelligence hierarchy** | CLAUDE.md → agents.md → agent file (most specific wins) |
| **Checkpoint format** | `[CHECKPOINT] ModuleName — ✅ filename.dart \| next: nextfile.dart` |
| **Hands-on setup** | [Chapter 3: Quick Start Checklist] |

---

*Next: [Chapter 3: Quick Start Checklist]*
