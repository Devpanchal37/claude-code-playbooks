# Chapter 15: Skills

> **Applies to:** Both
> **Prerequisites:** Chapter 8: Agent Creation Guide
> **Estimated read + setup time:** ~15 minutes

---

## TL;DR

Skills are reusable Markdown prompt templates invoked with `/skill-name`. They run inline inside Main Claude's context — no isolated window, no gates, no background mode. This makes them fast and simple for lightweight recurring tasks, but wrong for anything requiring multi-step logic, classification gates, or context isolation. For this setup, agents handle all core workflows. Skills handle the small, repetitive, inline instructions that don't warrant a full agent.

---

## What This Is

A skill is a Markdown file in `.claude/skills/` with a frontmatter block and a body of instructions. When you type `/skill-name`, Claude Code loads the file and Main Claude follows the instructions inline, in the current conversation.

Skills are not agents. They have no separate context window. They have no gates. They cannot run in the background. Main Claude reads the skill's instructions and acts on them as if you had typed them into the chat — because functionally, that is exactly what happens.

The value of skills is in reuse: you write the instruction once, store it in the file, and invoke it in one keystroke instead of retyping it each session.

### How It Compares to Agents

| | Skills | Agents |
|-|--------|--------|
| Context window | Shared with Main Claude | Isolated — separate from Main Claude |
| Can have gates | No | Yes |
| Background mode | No — always inline | Yes |
| Classification logic | No | Yes |
| Multi-step workflows | No — flat instruction set | Yes |
| Invocation | `/skill-name` (you type it) | Main Claude launches automatically on trigger |
| IDE support | Works in any Claude Code IDE | Claude Code only |
| Best for | Quick inline instruction sets | Complex workflows with decisions and gates |

---

## Why It Exists (The Problem It Solves)

**Without skills:** Frequently used instructions are retyped every session. A developer who runs a compliance check after every widget file must type the full instruction each time. Over a week, this is noise — repeated typing, inconsistent phrasing, and occasional omissions.

**With skills:** The instruction is written once, stored in a file, and invoked with `/compliance-check`. Main Claude follows the same instructions every time. The developer's intent is encoded in the file, not in their memory.

Skills also solve a portability problem. Some IDE integrations — JetBrains, VS Code extension modes, and non-Claude Code AI tools — do not support agents. Agent files are invisible in those environments. Skills, by contrast, are plain slash commands that work across all Claude Code surfaces. If you need the same instruction set in both the terminal and an IDE extension, a skill delivers it.

### What This Does NOT Do

- Skills do not replace agents for complex workflows. An instruction set that needs to classify input, run multiple steps, or produce structured output for another agent is an agent — not a skill.
- Skills do not run automatically on triggers. They only fire when you explicitly type `/skill-name`. If you need something to fire automatically (post-commit, post-file-write, on bug reports), that requires a hook or an agent with an orchestra entry.
- Skills do not have isolated context. If Main Claude's context window is nearly full, the skill's instructions compete with everything else in the conversation. A skill that needs a clean context to work reliably should be an agent instead.

---

## How to Create a Skill

A skill file has two parts: a frontmatter block and a body.

**Frontmatter block** — required at the top of every skill file:

```markdown
---
name: skill-name
description: One sentence describing what this skill does and when to use it
---
```

The `name` field matches the `/skill-name` invocation. Lowercase, hyphen-separated. No spaces.

The `description` field is shown in skill listings and helps Claude Code match skills to relevant contexts.

**Body** — the instruction set Main Claude follows when the skill is invoked. Write it as imperative instructions, the same way you would write agent instructions. Short sentences. Specific steps. No hedging.

---

## Setup

### Prerequisites Check

- [ ] Claude Code CLI installed
- [ ] Project initialized with a `.claude/` directory

### Step-by-Step

**1. Create the skills directory:**

```bash
mkdir -p .claude/skills
```

**2. Create your first skill file:**

Create `.claude/skills/quick-review.md`:

```markdown
---
name: quick-review
description: Run a targeted code quality check on the most recently modified file
---

Review the most recently modified Dart file in this session.

Check only:
1. Null safety — any `!` operator without proof the value is non-null
2. Hardcoded values — strings, colors, or numbers that should be constants
3. Function length — any function exceeding 50 lines
4. Deep nesting — any block exceeding 4 levels of indentation

For each issue found: report the file path, line number, the issue, and the one-line fix.
If no issues are found: report "Clean — no issues in [filename]".
Do not review any other file. Do not suggest refactors beyond these four checks.
```

**3. Verify the skill is discoverable:**

In a Claude Code session, type `/` and look for `quick-review` in the autocomplete list. If it appears, the file is correctly placed and formatted.

**4. Invoke the skill:**

```
/quick-review
```

Main Claude reads the file and runs the four checks on the most recently modified file. The response is inline — no new agent window opens.

**You'll know it worked when:** Main Claude produces a targeted review of one file covering exactly the four checks defined in the skill — nothing more, nothing less.

---

## When to Create a Skill vs. an Agent

Apply this decision rule before creating either:

```
Does the task need to:
  ├─ Classify the input before deciding what to do? → AGENT
  ├─ Run in background (non-blocking)?             → AGENT
  ├─ Use gates that block progression?             → AGENT
  ├─ Keep an isolated context window?              → AGENT
  └─ Pass its output to another agent?             → AGENT

Is the task:
  ├─ A flat instruction set (do X, check Y, report Z)? → SKILL
  ├─ Something you'd type into the chat manually?       → SKILL
  ├─ Useful across multiple IDE environments?           → SKILL
  └─ Invoked explicitly, never automatically?           → SKILL
```

If ANY of the agent conditions are true → create an agent, not a skill.

---

## Useful Skill Patterns for This Setup

These are skills that complement the agent-based setup without duplicating it:

**`/registry-check`** — grep both registries before a development session to surface reusable components. Useful when Main Claude's context doesn't have the registries loaded yet.

```markdown
---
name: registry-check
description: Grep component_registry.md and api_registry.md for [ComponentName] before creating anything new
---

Read docs/memory/component_registry.md and docs/memory/api_registry.md.
Search both files for: [the name the developer typed after the slash command].
Report: found entries (with file paths) or "not found — safe to create new".
```

**`/pipeline-check`** — show the current status of all FR pipeline entries. Useful for a quick status read at session start without loading the full pipeline file.

```markdown
---
name: pipeline-check
description: Show all in-progress and review pipeline entries from _pipeline_status.md
---

Read docs/FR/_pipeline_status.md.
Filter and display only entries with status IN_PROGRESS, REVIEW, or REWORK.
Format: module → feature → status → any CHECKPOINT lines.
Skip DONE and PENDING entries.
```

**`/compliance-check`** — run the UI compliance grep on a single file. A lightweight check without launching the full developer agent.

```markdown
---
name: compliance-check
description: Check a single Dart file for UI compliance violations (hardcoded colors, wrong fonts, string literals in widgets)
---

Read the file at [path provided after the command].
Check for:
1. Color(0xFF...) or Colors.xxx — must use ColorHelper instead
2. fontFamily other than 'Plus Jakarta Sans'
3. String literals directly in Text() widgets — must use locale keys

Report violations with file:line and the one-line fix.
Report "Clean" if none found.
```

> **NOTE:** These skill bodies use `[placeholder]` syntax where the developer must append
> context after the slash command. Example: `/registry-check ProfileCard`. If the developer
> types `/registry-check` with no argument, the skill cannot complete. Either design your
> skills to work without arguments, or document clearly in the description that an argument
> is required.

---

## Skills for Cross-IDE Portability

If your team uses a mix of Claude Code CLI and IDE extensions (VS Code, JetBrains), some developers may not have access to agents. Skills fill the gap.

For each core agent behavior that needs to work cross-IDE, create a skill that delivers a simplified version of the same instructions. It will lack gates and isolation — but it still encodes the correct behavior as a repeatable instruction set.

**Example: a cross-IDE version of the compliance check**

An agent has a widget placement gate that fires silently on every widget. In a non-Claude Code IDE, that gate doesn't exist. A `/compliance-check` skill invoked manually at the end of a file produces similar output, just without the automatic triggering.

The tradeoff is explicit: skills require the developer to remember to invoke them. Agents require the developer to trust that the gate fires. In production, agents are more reliable. For teams with mixed IDE environments, skills are the practical fallback.

---

## Validation

### Test 1: Skill discovery

**What to do:** Start a Claude Code session in the project. Type `/` in the prompt.

**Expected result:** The autocomplete list shows your skill name(s). If it does not appear, check that the file is in `.claude/skills/` (not `.claude/agents/` or a subdirectory) and that the frontmatter `name` field matches the filename.

**If it doesn't work:** Confirm the file uses `---` fences for frontmatter (not backticks or indentation). Confirm the file is named `[skill-name].md` with hyphens, not underscores.

---

### Test 2: Skill execution stays inline

**What to do:** Invoke `/quick-review` (or any skill you created) during a conversation that already has several messages.

**Expected result:** Main Claude responds inline — in the same conversation, in the same message thread. No new agent window. No "launching agent..." message. The response appears as if you had typed the instructions manually.

**If you see an agent launch instead:** The file is in `.claude/agents/` instead of `.claude/skills/`. Move it to the correct directory.

---

## Common Mistakes

### Mistake 1: Putting agent-level logic in a skill

**Symptom:** The skill's instructions reference multiple steps that depend on each other, but Main Claude sometimes skips steps or does them in the wrong order.

**Cause:** Skills are flat instruction sets. Multi-step logic with dependencies is agent territory. Without gates, Main Claude treats all steps as advisory and may combine or skip them based on context.

**Fix:** If the task has a "do X only after Y is confirmed" requirement — it needs a gate. Create an agent instead.

---

### Mistake 2: Expecting a skill to fire automatically

**Symptom:** Developer writes a skill expecting it to run after every file write or every commit. It never fires automatically.

**Cause:** Skills are manually invoked. Automatic post-tool behaviors require hooks (see [Chapter 6: Hooks]) or orchestra entries (see [Chapter 9: Orchestra Management]).

**Fix:** If you want the behavior to fire automatically: register a PostToolUse hook in `settings.json`, or create an agent with an orchestra trigger. Keep the skill if you also want a manual invocation option.

---

### Mistake 3: Skills with no arguments that assume context they don't have

**Symptom:** `/compliance-check` runs but reports "I need the file path to check" — Main Claude doesn't know which file to review.

**Cause:** The skill body references information the developer was supposed to provide (a file path, a component name) but the skill has no way to receive it as a structured argument.

**Fix:** Either (a) design the skill to work on the most recently mentioned file in the conversation, or (b) update the description to require an argument: "Usage: `/compliance-check [file path]`". Document what happens if no argument is provided.

---

### Mistake 4: Creating a skill for something that happens once

**Symptom:** The skill folder fills up with one-off scripts that haven't been used in weeks.

**Cause:** Skills have a maintenance cost — they accumulate and become noise. Creating a skill for a task you did once "in case it's useful later" is premature.

**Fix:** Threshold for skill creation: the task happens in at least 3 sessions per week, or it requires more than 4 lines of instruction that you've been retyping. Below that threshold, just type the instruction.

---

## [Flutter-GetX Specifics]

GetX + Clean Architecture introduces several recurring checks that are worth encoding as skills. These are too lightweight for a full agent, but common enough that typing them every session creates friction.

---

### GetX Compliance Skills

**`/getx-check`** — quick scan of a single Dart file for GetX anti-patterns:

```markdown
---
name: getx-check
description: Check a single Dart file for GetX pattern violations (controller type, Obx wrapping, RxList mutation)
---

Read the file at [path provided after the command].

Check for:
1. IndexedStack tab controllers — must use Get.put(..., permanent: true).
   Any controller used in an IndexedStack that is NOT permanent is a violation.
2. Obx usage — Obx() must directly read an observable in its own closure.
   Any Obx that passes the observable to a child widget is a violation.
3. RxList full replacement — must use .assignAll(), never direct = assignment.
   Any RxList variable followed by = [] or = list is a violation.
4. Controller disposal — Get.find() in a widget that does not have a corresponding
   Get.put() or binding is a potential violation.

Report violations with file:line and the one-line fix.
Report "Clean" if none found.
```

---

**`/binding-check`** — verify that a new screen has a corresponding binding registered in `app_pages.dart`:

```markdown
---
name: binding-check
description: Check that a screen file has a matching Binding class and is registered in app_pages.dart
---

The screen file is: [path provided after the command].

1. Read the screen file. Find the controller class name used in GetBuilder or Obx.
2. Search lib/ for a Binding class that puts() that controller.
3. Read lib/src/core/routes/app_pages.dart. Check that the screen's route includes
   the binding class.

Report:
- Binding class found: [ClassName] at [file path]
- Route entry found in app_pages.dart: yes / no
- If route entry missing: the exact GetPage entry that should be added

Do not modify any files. Report only.
```

---

### Using Skills as Cross-IDE Fallbacks for GetX Rules

The developer agent's widget placement gate enforces GetX compliance silently — no output unless a violation is found. In IDE environments where the developer agent doesn't run, the equivalent manual invocation is:

```
/getx-check lib/src/features/[module]/presentation/screens/[screen_name].dart
```

This produces the same compliance output as the gate, but requires manual invocation. Document this in your team's onboarding for developers using non-Claude Code IDEs.

---

## Reference

| Item | Value |
|------|-------|
| File location | `.claude/skills/[skill-name].md` |
| Invocation | `/skill-name` in any Claude Code session |
| Frontmatter fields | `name`, `description` |
| Context | Shared with Main Claude — NOT isolated |
| Background mode | Not available — always inline |
| Auto-trigger | Not available — manual invocation only |
| Agent vs. skill decision | Gates / background / classification needed → agent. Flat inline instructions → skill. |
| GetX skills | `/getx-check [file]`, `/binding-check [file]` |

---

*Next: Chapter 16: Token Efficiency & Cost Optimization*
