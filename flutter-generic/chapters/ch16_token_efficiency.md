# Chapter 16: Token Efficiency & Cost Optimization

> **Applies to:** Both
> **Prerequisites:** Chapter 11: MCP Plugins, Chapter 13: Project Map, Chapter 14: Docs Folder Structure
> **Estimated read + setup time:** ~20 minutes

---

## TL;DR

The most expensive failure mode in agentic development is agents reading files "for context" before doing anything useful. An agent that reads 10 files at session start has consumed 30–50% of its context window before writing a single line of code. This chapter defines the reading hierarchy, the one-read rule, the context budget thresholds, and model selection principles — so your setup produces quality output at a fraction of the token cost of an undisciplined one.

---

## What This Is

Token efficiency is the set of rules that governs what agents read, when they read it, which model they use, and when they stop and compact context. It is not a single feature — it is a discipline enforced across every component: CLAUDE.md rules, agent Pre-Step designs, model selection in agent frontmatter, and orchestra decisions (foreground vs. background).

Left unconfigured, Claude Code agents default to reading broadly. "Let me look at the codebase to understand the structure" sounds reasonable but costs 20k–40k tokens in file reads that produce no direct output. This chapter shows where that cost accumulates and how to eliminate it.

---

## Why It Exists (The Problem It Solves)

**Without token efficiency rules:**

An agent tasked with fixing a navigation bug reads:
- `ARCHITECTURE.md` — to understand the app structure
- `app_pages.dart` — to understand routing
- `app_routes.dart` — to see the route constants
- The screen file — to find the navigation call
- The controller — to check what data is passed
- `error_learnings.md` — just in case

Six reads before it has even classified the bug. Total: ~15k tokens. Then it realizes it needs the console log and asks for it — which is the first thing a correctly configured debugger would have asked.

**With token efficiency rules:**

The same agent runs its DATA GATE first (no file reads), asks for the console log, reads the log, then reads the one file the log points to. Total: ~3k tokens. Same output quality, 80% less cost.

The compound effect: over 50 features and bug fixes, an undisciplined setup burns 5–10x more tokens than a disciplined one — for the same output.

---

## The Reading Hierarchy

Before reading any file, every agent must check whether the information can be retrieved at a lower cost. The hierarchy, from cheapest to most expensive:

```
1. code-review-graph MCP tools    ← pre-indexed relationships, 1 call = impact radius
2. Registries (grep)              ← component_registry.md, api_registry.md
3. project_map.md (read)          ← module map, entity dependency table, blast radius tiers
4. Targeted Grep                  ← grep for specific function/class/constant name
5. Targeted file Read             ← read only the specific file and lines needed
6. Full file Read (last resort)   ← read entire file when targeted reads can't answer the question
```

**Never start at the bottom.** The `get_impact_radius_tool` from the code-review-graph MCP answers "what does changing this entity affect?" in one tool call. Finding the same answer via Grep requires 5–10 calls across multiple files.

> **CRITICAL:** Agents that say "let me read these files for context" before checking the
> graph tools and registries are violating the reading hierarchy. The Pre-Step in every
> agent must enforce: registries first, project map second, targeted reads only.
> If violated: every feature costs 3–5x more tokens than necessary, and context windows
> fill mid-task with prior file content instead of new work.

### When Each Level Is the Right Tool

| Question | Cheapest tool to answer it |
|----------|---------------------------|
| What files are impacted by changing UserEntity? | `get_impact_radius_tool` (graph MCP) |
| Does a ProfileCard widget already exist? | Grep `component_registry.md` |
| What endpoint does the profile screen call? | Grep `api_registry.md` |
| Which modules use the AuthService? | Read `project_map.md` → Entity Dependency Table |
| Where is the `fetchUser()` function defined? | Grep for `fetchUser` in `lib/` |
| What does `ProfileRepository.fetchUser()` do? | Read `profile_repository_impl.dart` — targeted |
| What is the complete structure of the auth module? | Read the auth module folder — full scan |

---

## The One-Read Rule

Instruction files are read **once per session**, not once per feature.

Files subject to the one-read rule:
- `docs/instructions/ARCHITECTURE.md`
- `docs/instructions/UI_INSTRUCTION.md`
- `docs/instructions/API_INSTRUCTION.md`

These files define the project's standards and conventions. They do not change during a session. Reading them once at session start or task start is correct. Re-reading them "to check compliance" before each feature is not — the rules are the same. Apply from memory.

An agent that re-reads `UI_INSTRUCTION.md` at the start of every screen implementation wastes 2k–5k tokens per feature on content that hasn't changed since it was last read.

**How to enforce the one-read rule in agent files:**

In the agent's Pre-Step, mark instruction files with a session-load check:

```
Pre-Step:
  If UI_INSTRUCTION.md has not been read this session → read it once, cache rules.
  If already read this session → skip. Apply cached rules.
```

This wording tells the agent to track whether the file was read and not repeat it.

---

## The Context Budget Rule

The context window has two operating zones:

| Zone | Context usage | Behavior |
|------|--------------|----------|
| Normal | 0–80% | All task types available. Large-scale work, multi-file features, complex debugging — all fine. |
| Late | 80–100% | Avoid large-scale refactoring, multi-file features, and complex debugging. Prefer: single-file edits, documentation updates, simple one-line fixes. For complex tasks arriving at 80%+: acknowledge the context position, recommend a new session, write a checkpoint. |

**Why the 80% threshold matters:** In the last 20% of the context window, agents start to "forget" rules they read earlier in the session. CLAUDE.md instructions loaded at session start may no longer be fully in context. Agent responses get shorter and less precise. The cost-to-quality ratio inverts: you spend more tokens getting lower quality output.

**How to detect late-zone operation:**
- Agent responses are noticeably shorter than earlier in the session
- An agent repeats a question it already asked
- A rule from CLAUDE.md is being ignored that was followed earlier
- Main Claude asks to re-read files it already read

**What to do when you hit 80%:**

For the current task: if it can be completed in a few more file edits — finish it, then start a new session. If it requires more than 3 files of new work — stop, write a CHECKPOINT entry to `_pipeline_status.md`, and start a new session. The checkpoint prevents losing progress.

Do not attempt a new complex feature in the last 20% of context. The risk of incorrect output is too high.

---

## Model Selection as Token Efficiency

Model selection is not just a quality decision — it is a cost decision. Using the wrong model for a task increases cost without increasing output quality.

| Model | When to use | Example agents |
|-------|-------------|---------------|
| Haiku | Deterministic, rule-following tasks. No judgment required. High invocation frequency. | `doc-updater`, `project-map`, `ui-design-enforcer` |
| Sonnet | Judgment-heavy work — code writing, investigation, code review. Daily primary use. | `developer`, `code-reviewer`, `systematic-debugger`, `fr-analyst` |
| Opus | Architectural decisions. When the quality of reasoning multiplies all subsequent work. | `planner` |

The savings from using Haiku for high-frequency agents compound across a project:

- `doc-updater` runs after every feature implementation. In a 50-feature project, that is 50 invocations. Sonnet cost per invocation vs. Haiku: approximately 3x. Haiku for doc-updater saves ~66% on those 50 runs.
- `project-map` regenerates after every doc-updater run. Same math applies.
- `ui-design-enforcer` runs before every new screen. If the project has 20 screens, 20 invocations at Sonnet cost vs. Haiku cost is a significant difference.

> **NOTE:** Haiku is appropriate for doc-updater and project-map because their task is
> pattern-following — read the registries, update entries in a defined format, nothing more.
> Haiku is NOT appropriate for systematic-debugger (requires judgment about root cause
> evidence) or developer (requires judgment about implementation quality). Mismatch in
> either direction — Opus for formatting, Haiku for architecture — degrades output quality
> or wastes money.

**How to set model in the agent frontmatter:**

```yaml
---
name: doc-updater
description: Update component_registry.md and api_registry.md after feature implementation
model: haiku
---
```

---

## Background Agent Cost Savings

Background agents run in their own isolated context window. This has two token efficiency benefits:

**Benefit 1 — Main conversation context is preserved.** When `doc-updater` runs in background, its file reads (component_registry.md, api_registry.md, the changed source files) do not appear in Main Claude's context window. Main Claude can continue the next task with a clean slate. The same reads in foreground mode would consume 10k–20k tokens of Main Claude's context.

**Benefit 2 — Background agents can be run in parallel.** When `doc-updater` and `project-map` run sequentially in background (doc-updater first, project-map after it completes), both complete without consuming any of Main Claude's context budget. Main Claude returns to the developer with the next action while both agents work simultaneously in their own windows.

This is why background mode exists as an architectural decision — not just for speed, but for context preservation.

**Which agents must run in background (never foreground):**

| Agent | Why background |
|-------|---------------|
| `doc-updater` | No output needed by Main Claude; reads/writes docs files only |
| `project-map` | No output needed by Main Claude; regenerates one file |

**Which agents must run in foreground (never background):**

| Agent | Why foreground |
|-------|---------------|
| `systematic-debugger` | Main Claude needs the Handoff Brief to launch developer |
| `developer` | Main Claude coordinates the quality loop after it completes |
| `ui-reviewer` | Main Claude needs corrections to pass back to developer |
| `code-reviewer` | Main Claude needs findings to pass back to developer |
| `planner` | Main Claude needs the plan to launch developer with correct context |

---

## What "For Context" Reading Actually Costs

Here is what "reading for context" looks like in token terms. Each scenario shows what an undisciplined agent reads vs. what a disciplined agent reads.

**Scenario: Fix a pagination bug**

| Reading approach | Files read | Tokens consumed | Output quality |
|-----------------|------------|-----------------|----------------|
| Undisciplined: reads feature folder "for context" | 8 files (screen, controller, repository, model, use cases, bindings, routes, registry) | ~25k tokens | Same |
| Disciplined: reads pipeline status → targeted grep → one file | 3 files (error_learnings, targeted grep result, one controller file) | ~4k tokens | Same |

**Scenario: Add a new API endpoint**

| Reading approach | Files read | Tokens consumed |
|-----------------|------------|-----------------|
| Undisciplined: reads all existing API files "to understand the patterns" | 5 repository files + API instruction + registry | ~18k tokens |
| Disciplined: reads api_registry.md (grep) + API_INSTRUCTION.md (once, cached) | 1 grep result | ~2k tokens |

The difference is not reading quality — it is reading discipline. The disciplined agent gets the same answer by looking where the answer is indexed, not by re-reading source files.

---

## Token Budget Per Task

Use these as diagnostic benchmarks. If a task exceeds its budget significantly, something is being read more than necessary.

| Task type | Expected token budget | If over: check |
|-----------|----------------------|----------------|
| Simple bug fix (Tier 1 — widget/UI) | < 5k | Are instruction files being re-read? |
| Logic/state bug fix (Tier 2) | 10k–20k | Is the debugger reading files before the DATA GATE fires? |
| New feature (small, 1-2 screens) | 30k–60k | Are registries being read instead of grepped? |
| New feature (complex, 3+ screens) | 60k–120k | Is architecture.md being re-read per feature? |
| Single task exceeds 200k | Diagnostic: re-reading same files repeatedly | Run `/pipeline-check` and review session log |

---

## Validation

### Test 1: Reading hierarchy compliance

**What to do:** Start a new session, then ask: "Which widgets exist in component_registry.md for the Profile module?"

**Expected result:** Main Claude greps `component_registry.md` — it does NOT read the full `lib/src/features/profile/` directory to find out.

**If you see full folder reads:** The Pre-Step instruction in the relevant agent (or Main Claude's CLAUDE.md session protocol) is missing the registry-check step. Add: "Before creating any widget, grep component_registry.md first."

---

### Test 2: One-read rule enforcement

**What to do:** In a session, implement two features back-to-back using `develop [Module1]` then `develop [Module2]`.

**Expected result:** `UI_INSTRUCTION.md` and `ARCHITECTURE.md` are loaded once at the start of the first `develop` command. They are NOT re-read at the start of the second `develop` command.

**If you see re-reads:** The developer agent's Pre-Step is missing the session-load check. Add the "if already read this session → skip" condition to its instruction loading gate.

---

## Common Mistakes

### Mistake 1: "Let me read these files to understand the structure"

**Symptom:** At session start or task start, an agent reads 5–10 files across the codebase before doing any work.

**Cause:** No reading hierarchy enforced in the agent's Pre-Step. The agent defaults to broad reads "for safety."

**Fix:** Add to the agent's Pre-Step: "Do not read source files for context. Use the reading hierarchy: graph MCP → registries → project_map → targeted grep → targeted file read. Read only what the specific task requires."

---

### Mistake 2: Instruction files re-read per feature

**Symptom:** `UI_INSTRUCTION.md` appears in the Read tool call log for every screen file written, even within the same session.

**Cause:** The developer agent's instruction loading step has no session-tracking condition. It re-reads on every invocation.

**Fix:** Add a session-load check: "Read UI_INSTRUCTION.md only if not already read this session." In practice, this means reading it once at the first screen of the session and applying cached rules for all subsequent screens.

---

### Mistake 3: Using Sonnet for doc-updater and project-map

**Symptom:** Post-implementation documentation steps cost as much in tokens as the implementation itself.

**Cause:** doc-updater and project-map are running on Sonnet (default) instead of Haiku. They perform pattern-following tasks that do not require Sonnet's reasoning.

**Fix:** Add `model: haiku` to the frontmatter of `doc-updater.md` and `project-map.md`.

---

### Mistake 4: Running doc-updater in foreground

**Symptom:** After every feature, the main conversation is filled with doc-updater's file reads and registry update output. Main Claude's context fills with documentation activity instead of development activity.

**Cause:** doc-updater is configured as foreground in the orchestra. Main Claude waits for it to complete and receives all its output in the main context.

**Fix:** Set doc-updater to background in `agents.md`. Its output is not needed by Main Claude — only the files it produces matter, and those are written directly.

---

### Mistake 5: Starting a complex feature at 80%+ context

**Symptom:** Mid-feature, the developer agent starts repeating itself, "forgets" an architecture rule it followed earlier, or produces shorter, lower-quality responses than it did at the start of the session.

**Cause:** Complex feature was started in the late context zone. The agent is operating with degraded context.

**Fix:** When context approaches 80%, write a CHECKPOINT entry and start a new session for complex work. Single-file edits and documentation updates can continue in the late zone.

---

## Reference

| Item | Value |
|------|-------|
| Reading hierarchy | Graph MCP → registries → project_map → grep → targeted read → full read |
| One-read rule applies to | `ARCHITECTURE.md`, `UI_INSTRUCTION.md`, `API_INSTRUCTION.md` |
| Context budget — normal zone | 0–80% |
| Context budget — late zone | 80–100% (avoid complex work) |
| Background agents | `doc-updater`, `project-map` — never consume main context |
| Model: Haiku | `doc-updater`, `project-map`, `ui-design-enforcer` |
| Model: Sonnet | `developer`, `code-reviewer`, `systematic-debugger`, `fr-analyst` |
| Model: Opus | `planner` |
| Token budget: bug fix | < 5k (Tier 1), 10k–20k (Tier 2) |
| Token budget: new feature | 30k–120k depending on complexity |

---

*Next: Chapter 18: Team Collaboration*
