# Chapter 4: CLAUDE.md File

> **Applies to:** Both
> **Prerequisites:** [Chapter 2: How the Setup Works]
> **Estimated read + setup time:** ~30 minutes

---

## TL;DR

CLAUDE.md is the identity file that Main Claude reads at the start of every session. It defines who Claude is, what it refuses to do, which files to load first, and which agent to launch for each request type. Without it, Main Claude improvises — routing is inconsistent, critical rules are forgotten between sessions, and every developer who types a message gets different behavior. A correct CLAUDE.md has exactly 7 mandatory sections and stays within 500 lines. Everything else belongs in agent files, rules/, or docs/.

---

## What This Is

CLAUDE.md is a Markdown file at the root of your project. Claude Code reads it automatically at the start of every session, before the first user message is processed. It shapes Main Claude's identity for the duration of that session.

Think of it as a constitution, not a manual. A constitution states the fundamental rules that everything else must conform to. A manual explains procedures in detail. CLAUDE.md is the constitution. Agent files, rules/, and docs/ are the manuals.

### How It Compares to Other Config Files

| File | What It Contains | Read by | Frequency |
|------|-----------------|---------|-----------|
| **CLAUDE.md** | Identity, core rules, routing triggers, quick references | Main Claude | Every session, before anything |
| **settings.json** | Permissions, allowed tools, model selection, hook registration | Claude Code runtime | On load |
| **.claude/rules/** | Detailed coding standards with code examples | Agents during Pre-Step | Per task, on demand |
| **Agent files** | Agent-specific gate logic, workflows, output formats | The specific agent when launched | When that agent fires |
| **docs/memory/** | Runtime data — registries, error logs, component inventory | Main Claude + agents | Grepped on demand |
| **docs/instructions/** | Reference documentation — API patterns, UI rules, architecture | Agents during instruction loading | Once per session |

> **NOTE:** The most common CLAUDE.md mistake is writing content that belongs in one of these other files. If a rule needs a paragraph of explanation with examples, it belongs in rules/ or an agent file — not CLAUDE.md.

---

## Why It Exists (The Problem It Solves)

**Without CLAUDE.md:** Main Claude is a generic assistant with no project identity. It does not know what kind of project this is, which agents exist, what it is not allowed to do, or what to read before starting work. Every session is a cold start. Each developer who types a message gets different behavior depending on how they phrase it.

**With CLAUDE.md:** Every session starts with the same defined identity. Main Claude knows it is an orchestrator, not an implementer. It knows which file to read for past mistakes. It knows which agent to launch for a bug report. It knows which rules are non-negotiable regardless of what the user requests.

Concrete failure modes that CLAUDE.md prevents:

| Without This Rule | What Actually Happens |
|------------------|----------------------|
| No session start protocol | Main Claude reads 15–20 files "for context" — 30% of the context window is gone before any work starts |
| No role definition | Main Claude writes code directly instead of delegating — no compliance greps, no quality gates |
| No critical rules | Native folders get modified; hardcoded values enter the codebase silently |
| No routing table | Bug reports trigger feature planning; informal feature descriptions trigger the wrong agent |
| No token efficiency rules | Agents re-read the same instruction files on every feature, not once per session |
| No error learning protocol | Mistakes fixed three sessions ago are repeated in the current session |

### What This Does NOT Do

CLAUDE.md does not:
- Run code, modify files, or launch agents by itself. Main Claude reads it and then acts based on its contents.
- Replace detailed coding standards. Those belong in .claude/rules/ with full examples.
- Store runtime state. Which features are done, which errors occurred — that goes in docs/memory/.
- Define agent behavior. Gate sequences and multi-step workflows belong in the individual agent files.

---

## How It Works

### The Session Reading Sequence

Main Claude reads CLAUDE.md first, then follows the Session Start Protocol inside it to load additional context. The protocol is tiered — not everything is loaded every session, only what the current task requires.

```
Session begins
      ↓
Main Claude reads CLAUDE.md (automatic — every session)
      ↓
Follows Session Start Protocol:
  Tier 1 — always (every session, every task):
    docs/FR/_pipeline_status.md     ← current task + checkpoint lines
    docs/memory/error_learnings.md  ← prevent repeated mistakes
      ↓
  Tier 2 — only when starting or resuming a feature:
    docs/memory/component_registry.md   ← grep before creating new components
    docs/memory/api_registry.md         ← grep before adding new API functions
      ↓
  Tier 3 — only when the task explicitly requires it:
    docs/instructions/UI_INSTRUCTION.md    ← new screen or widget work
    docs/instructions/API_INSTRUCTION.md   ← new API call or endpoint wiring
    docs/instructions/ARCHITECTURE.md      ← unsure about layer or folder placement
      ↓
User message arrives
      ↓
Main Claude consults agents.md routing table:
  Match found → launches correct agent (foreground or background)
  No match    → Main Claude answers directly
```

### The Routing Logic

Every incoming message is classified into one of five types. The Development Workflow Trigger section defines exactly what fires for each type.

| Prompt type | Signal words | What fires |
|------------|-------------|-----------|
| Bug report | `bug::`, `issue::`, "fix", "broken", "not working" | systematic-debugger (always foreground, always first) |
| Build request | "develop", "implement", "build", "add", "create" | developer pipeline (with planner first if no plan exists) |
| Requirement description | Describes behavior without an action verb | fr-analyst (background) |
| Planning request | "plan", "design approach", "how would you structure" | planner (foreground) |
| Informational | "what is", "how does", "explain", "show me" | Main Claude answers directly — no agent launched |

---

## Setup

### Prerequisites Check

- [ ] Project has a `.claude/` directory
- [ ] At least one agent file exists at `.claude/agents/`
- [ ] `docs/FR/_pipeline_status.md` exists
- [ ] `docs/memory/error_learnings.md` exists

### Step-by-Step

Write the 7 mandatory sections in this order. All other content is optional or belongs in another file.

---

**Section 1 — Session Start Protocol**

This section tells Main Claude what to read and when. Without it, Main Claude guesses — usually reading too much (wastes context) or too little (misses critical state).

```markdown
## Session Start Protocol

Read files in tiers. Only load what the current task needs.

### Tier 1 — Always read (every session)
- docs/FR/_pipeline_status.md       → current task + any [CHECKPOINT] lines
- docs/memory/error_learnings.md    → prevent repeated mistakes

### Tier 2 — Read when starting or resuming a feature
- docs/memory/component_registry.md → grep for existing components before creating new
- docs/memory/api_registry.md       → grep for existing endpoints before adding new calls

### Tier 3 — Read only when the task requires it
- docs/instructions/UI_INSTRUCTION.md    → new screen or widget implementation
- docs/instructions/API_INSTRUCTION.md   → new API call or endpoint wiring
- docs/instructions/ARCHITECTURE.md      → uncertain about layer or folder placement

After Tier 1 → ask the human which module to work on, or resume the current IN_PROGRESS task.
```

---

**Section 2 — Role Definition**

This section states that Main Claude is an orchestrator, not an implementer. Without it, Main Claude writes code directly in the main conversation — bypassing every quality gate.

```markdown
## Who You Are

You are the **orchestra conductor** on this project. Your role:
- Understand the human's intent
- Route each request to the correct agent
- Coordinate agent output back to the human
- NEVER write implementation code directly in this conversation

ALL code writing is done by the developer agent — even single lines, small fixes, and simple components. Development requests automatically trigger the developer agent. No exceptions.

The human is the product owner and validator. You are the full engineering team orchestrator.
They say what to build. You determine how and which agent executes it.
```

> **CRITICAL:** If the role definition is missing or says "you are a developer" rather than "you are an orchestrator," Main Claude writes code directly and bypasses the developer agent's gate sequence — including instruction loading, compliance greps, and self-validation.  
> If violated: code enters the codebase with no quality gates applied. Violations are silent — no error is thrown.

---

**Section 3 — Critical Rules**

Non-negotiable constraints. Each rule must state: WHAT is forbidden or required + WHY it exists + CONSEQUENCE OF VIOLATION.

Rules for this section:
- Never more than 3 lines per rule
- Always an imperative: "NEVER", "ALWAYS", "MUST"
- The consequence must be specific and observable — not "things may break"

```markdown
## CRITICAL RULES — Never Violate

### RULE 1 — No Direct Code Writing
NEVER write implementation code in the main conversation.
Reason: Bypasses instruction loading, compliance greps, and self-validation in the developer agent.
If violated: Hardcoded values, missing UI states, and undocumented patterns enter the codebase silently.

### RULE 2 — Confirm Before Building
NEVER start building when the requirement is ambiguous, incomplete, or contradicts a previous decision.
Reason: Code built on wrong requirements must be discarded entirely.
If violated: The session is spent implementing the wrong thing, then re-implementing the right thing.

### RULE 3 — [Your most project-specific constraint]
NEVER [action].
Reason: [why — what happened or what it prevents].
If violated: [specific observable consequence].
```

---

**Section 4 — Development Workflow Trigger**

The routing table. Main Claude consults this section on every non-trivial request. It must cover all common request patterns with explicit trigger → agent → mode mapping.

```markdown
## Development Workflow

| User Request Pattern | Agent | Mode | Condition |
|---------------------|-------|------|-----------|
| `bug:: [description]` | systematic-debugger → developer | foreground | Always — never skip debugger |
| `issue:: [description]` | systematic-debugger → developer | foreground | Always — never skip debugger |
| "develop [module]" | developer | foreground | Implementation plan exists |
| "develop [module]" | planner → developer | foreground | No plan, complex feature |
| "implement [feature]" | developer | foreground | No new screens |
| "implement [feature]" | ui-design-enforcer → developer | foreground | New screen(s) involved |
| "build [system]" | planner → developer | foreground | Always plan new systems first |
| "fix [bug]" (informal) | systematic-debugger → developer | foreground | Treat same as bug:: |
| "plan [feature]" | planner | foreground | Planning only, no build |
| "add [component]" | developer | foreground | Skip planner — minor change |
| ANY other code request | developer | foreground | Never write code manually |
```

After each agent completes, define what Main Claude does next. Without this, the session stalls after the agent finishes.

```markdown
### Post-Agent Actions

| Agent completed | What Main Claude does next |
|----------------|--------------------------|
| systematic-debugger | Read Handoff Brief. If evidence is CONFIRMED → launch developer (Correction Pass). If not confirmed → ask human for missing evidence. |
| planner | Present plan to human. Wait for explicit confirmation. Then launch developer. |
| developer | Run quality loop: ui-reviewer (new screens only) → code-reviewer → security-reviewer (if sensitive surface changed) → doc-updater (background). |
| fr-analyst | Present FR summary to human. Wait for confirmation. Mark pipeline status PENDING. |
```

> **WARNING:** Missing a routing entry means that request type defaults to Main Claude answering directly. If "fix [bug]" is not in the table, informal bug reports bypass systematic-debugger and go straight to implementation — all investigation gates are skipped.  
> Instead: list every common request type, including informal variants of the same request.

---

**Section 5 — UI Compliance Rules (Flutter projects)**

Zero-tolerance violations that apply to every screen in the project. These are in CLAUDE.md — not in a rules/ file — because they apply without exception to every feature, not just one module.

```markdown
## UI Compliance — Zero Tolerance

These violations block delivery. No exceptions.

| Violation | Rule |
|-----------|------|
| Hardcoded color values | Use the project's color constant system |
| Inline strings in widget files | Use the project's locale/i18n key system |
| Unapproved font families | Use only the project-approved font |
| Missing loading state on async screens | Shimmer or skeleton required |
| Missing error state on async screens | Error widget + retry action required |
| Missing empty state on async screens | Empty state widget + call to action required |

Three-layer enforcement:
1. Developer agent enforces at widget-placement time (Widget Placement Gate)
2. UI-reviewer confirms after every implementation pass
3. Code-reviewer blocks merge if any violation is found
```

---

**Section 6 — Error Learning Protocol**

Defines the two triggers that cause errors to be recorded in docs/memory/error_learnings.md. Without this, the file falls behind and agents repeat known mistakes every session.

```markdown
## Error Learning Protocol

Two triggers — both mandatory:

### Trigger 1 — Human Corrects a Mistake
1. Implement the fix
2. Open docs/memory/error_learnings.md
3. Append: `## [YYYY-MM-DD] Short title`
   `**Mistake:** what went wrong`
   `**Correct:** what to do instead`
   `**Pattern:** the general rule going forward`
4. If it violates a global rule → also update the relevant rule file
5. Confirm: "Learned. Added to error_learnings.md: [one-line summary]"

### Trigger 2 — Agent Encounters a Non-Obvious Issue
Any agent that encounters and solves a non-obvious issue MUST update error_learnings.md without waiting for human correction.
Qualifying issues: unexpected package behavior, framework pattern failure, UI state edge case causing visual bug, recurring pattern violation found across multiple files, API response structure differing from expectation.
```

---

**Section 7 — Token Efficiency Rules**

Defines the reading hierarchy and the one-read rule. Without these, agents spend 30–50% of their context loading files before doing any work.

```markdown
## Token Efficiency Rules

1. **code-review-graph MCP installed.** Use for ALL review and impact analysis:
   - Before reviewing: `get_review_context_tool` — reads only changed + impacted files
   - Before refactoring: `get_impact_radius_tool` — know blast radius before touching anything
   - Never read files not in the impact graph for the current task

2. **Read docs/maps/project_map.md before any cross-module analysis.**
   Only fall back to Grep/Glob after checking it. Do not start with a text search and assume you found everything.

3. **Instruction files are read ONCE per session, not once per feature.**
   UI_INSTRUCTION.md, ARCHITECTURE.md, API_INSTRUCTION.md — read once, apply from memory.
   Do not re-read to check compliance. Apply from memory.

4. **Use registries instead of reading source files.**
   component_registry.md and api_registry.md answer "does this already exist?" in one grep.
   Reading source folders for the same question burns 10× more context.
```

---

### Configuration Reference: What Goes Where

Use this decision tree whenever you are deciding where a new rule or instruction belongs.

```
New rule or instruction to write
      ↓
Is it a routing decision?
(when user says X → launch agent Y)
      ├─ YES → CLAUDE.md, Development Workflow Trigger section
      │
      └─ NO
          ↓
         Does it apply to EVERY session, EVERY feature, ZERO exceptions?
              ├─ YES → CLAUDE.md, Critical Rules section
              │
              └─ NO
                  ↓
                 Is it agent-specific logic?
                 (gate sequence, classification, output format, multi-step workflow)
                      ├─ YES → .claude/agents/[agent-name].md
                      │
                      └─ NO
                          ↓
                         Is it a coding standard with code examples?
                         (naming conventions, patterns, anti-patterns)
                              ├─ YES → .claude/rules/[topic].md
                              │
                              └─ NO
                                  ↓
                                 Is it runtime data?
                                 (components that exist, past errors, current task status)
                                      ├─ YES → docs/memory/ (component_registry, error_learnings, etc.)
                                      │
                                      └─ NO → docs/instructions/ (UI_INSTRUCTION, API_INSTRUCTION, ARCHITECTURE)
```

Quick reference table:

| Instruction example | Goes in |
|--------------------|---------|
| "When user says 'develop X' → launch developer agent" | CLAUDE.md, Workflow Trigger section |
| "NEVER modify files in android/ or ios/" | CLAUDE.md, Critical Rules section |
| "All async screens must have 4 UI states" | CLAUDE.md (1-line rule) + docs/instructions/UI_INSTRUCTION.md (full spec) |
| "Use color constants for all color references" | CLAUDE.md (1-line rule) + .claude/rules/ (examples) |
| "Developer agent runs 7 compliance greps after each file" | .claude/agents/developer.md |
| "Return new objects — never mutate in place" | .claude/rules/common/coding-style.md |
| `ProfileWidget` is registered and reusable | docs/memory/component_registry.md |
| "Error: package X must be initialized before Get.put()" | docs/memory/error_learnings.md |

---

## Validation

### Validation Test 1: Role Routing Check

**Purpose:** Verify Main Claude routes a bug report to systematic-debugger, not to direct investigation.

**Trigger:**
Open a new session and type this exactly:
```
bug:: The item count shows 0 even though items are visible on the screen.
```

**Expected result:**
Main Claude launches `systematic-debugger` and passes only:
```
Bug description: The item count shows 0 even though items are visible on the screen.
Screen/module: [inferred from description]
Project root: [project path]
```
Main Claude adds nothing else. No investigation steps, no hypotheses, no file suggestions.

**If Main Claude starts reading files itself instead:**
→ Role Definition section is missing or too weak. Add this explicitly: "ALL bug reports trigger systematic-debugger first. NEVER investigate directly. NEVER add investigation steps to the agent prompt."

**If Main Claude asks "should I use the debugger for this?":**
→ The routing table has conditional language. Remove the "if" language. Make it a hard routing rule: "`bug::` prefix → systematic-debugger. Always."

---

### Validation Test 2: Session Start Compliance

**Purpose:** Verify the tiered reading protocol fires correctly.

**Trigger:**
Open a new session and type:
```
What is the current task?
```

**Expected result:**
Main Claude reads `docs/FR/_pipeline_status.md` and `docs/memory/error_learnings.md` (Tier 1), then reports the current IN_PROGRESS task from the pipeline file. It does not read other files unless they are relevant to the current task.

**If Main Claude reads many other files before answering:**
→ The Session Start Protocol is missing or uses "read everything for context" language. Replace with tiered protocol. Tier 1 is the only unconditional read.

**If Main Claude says "I don't know the current task":**
→ docs/FR/_pipeline_status.md is missing or empty. Create it and add the current task status.

---

### Validation Test 3: Code Delegation Check

**Purpose:** Verify that Main Claude delegates code requests instead of writing code itself.

**Trigger:**
```
Add a loading spinner to the HomeScreen.
```

**Expected result:**
Main Claude launches the `developer` agent. It does not write a code snippet in the response.

**If Main Claude writes the code directly:**
→ Role definition is not explicit enough. Replace with: "NEVER write implementation code in this conversation. All code writing goes to the developer agent. Always. Even for single-line changes."

---

## Common Mistakes

### Mistake 1: Agent Instructions Written in CLAUDE.md

**Symptom:** CLAUDE.md exceeds 500 lines. Gate sequences, output formats, and multi-step agent workflows are described inside CLAUDE.md.

**Cause:** The developer added agent-specific logic to CLAUDE.md instead of the agent file. CLAUDE.md ends up containing Main Claude's rules AND the developer agent's 12-step gate sequence AND the code-reviewer's full checklist.

**Fix:** Move everything agent-specific to `.claude/agents/[name].md`. CLAUDE.md references agents by name and trigger condition. It does not describe internal agent behavior.

Rule of thumb: if a section in CLAUDE.md is longer than 15 lines, it belongs in another file.

---

### Mistake 2: Vague Language That Agents Ignore

**Symptom:** Rules exist in CLAUDE.md but agents do not follow them consistently.

**Cause:** Rules use hedging language: "you should try to", "when possible", "it's generally good practice to", "consider using".

**Fix:** Replace all hedging with imperatives:

| Before (ignored) | After (followed) |
|-----------------|----------------|
| "You should try to delegate code tasks" | "NEVER write code directly. Launch developer agent." |
| "It's good practice to check error_learnings" | "Read docs/memory/error_learnings.md at Tier 1 — every session, before any work" |
| "Consider using the code-review-graph before grepping" | "Use code-review-graph MCP BEFORE Grep or Read for any impact analysis. No exceptions." |
| "You might want to confirm scope before building" | "Stop. Confirm requirement with human. Do not build until confirmed." |

---

### Mistake 3: No Post-Agent Action Defined

**Symptom:** An agent completes and Main Claude stalls. It asks "should I proceed?" or does nothing.

**Cause:** The routing table defines what triggers each agent but not what Main Claude does after the agent finishes.

**Fix:** Add a Post-Agent Actions table immediately after the routing table:

```markdown
| Agent completed | Main Claude does next |
|----------------|----------------------|
| systematic-debugger | Read Handoff Brief → launch developer only if evidence is CONFIRMED |
| planner | Present plan → wait for human confirmation → launch developer |
| developer | Run quality loop: ui-reviewer (new screens) → code-reviewer → doc-updater |
```

Without this, Main Claude treats the agent's completion as the end of the workflow.

---

### Mistake 4: Missing the Confirmation Gate

**Symptom:** Main Claude immediately starts implementing when the user describes a new feature — without waiting for confirmation.

**Cause:** No Confirmation Gate exists in CLAUDE.md. Or the gate has been removed as "too slow."

**Fix:** Add the gate after the routing table:

```markdown
## Confirmation Gate

After presenting any FR proposal, design review, or architectural suggestion:
End the message. Wait for explicit human confirmation before any implementation.

Does NOT apply to: bug fixes, minor changes, or direct build/fix/add requests where scope is clear.
```

The carve-out is necessary. Without it, Main Claude asks "should I proceed?" even for trivial one-line fixes, creating friction that outweighs the benefit.

---

### Mistake 5: CLAUDE.md Exceeds 500 Lines

**Symptom:** CLAUDE.md is 700+ lines. Developers report that Main Claude ignores rules that are "clearly in the file."

**Cause:** Every thought, preference, and edge case has been added to CLAUDE.md over time without pruning. The file has become a document, not a constitution.

**Fix:** Run this audit on every rule in CLAUDE.md:
- "Does Claude need this in every session, for every task?" → Keep in CLAUDE.md
- "Is this a detailed standard better shown with examples?" → Move to `.claude/rules/`
- "Is this agent-specific gate logic?" → Move to the agent file
- "Is this reference documentation agents look up?" → Move to `docs/instructions/`

Run the audit whenever CLAUDE.md exceeds 500 lines. The critical rules that matter most get lost when buried after line 400.

---

## Reference

| Item | Value |
|------|-------|
| Primary file | `CLAUDE.md` at project root |
| Read by | Main Claude — automatically, every session |
| Maximum recommended size | ~500 lines |
| Managed by | Manual (human-maintained) |
| Updated when | New critical rule added, new agent registered, routing pattern changes |
| Key constraint | Only rules that apply to every session with zero exceptions belong here |
| Companion files | `.claude/agents/` (agent logic), `.claude/rules/` (standards), `docs/instructions/` (reference) |

---

*Next: [Chapter 5: settings.json]*
