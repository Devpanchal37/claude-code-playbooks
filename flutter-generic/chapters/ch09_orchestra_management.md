# Chapter 9: Orchestra Management

> **Applies to:** Both
> **Prerequisites:** [Chapter 8: Agent Creation Guide]
> **Estimated read + setup time:** ~35 minutes

---

## TL;DR

`agents.md` is the routing file that tells Main Claude which agent to launch for every type of user message, in what mode, and in what order. Without it, agents exist as isolated files that never fire — or fire inconsistently based on Claude's judgment. With it, every message type has a defined path: bug reports always go to the debugger, feature descriptions always go to the FR analyst, development requests always check for a plan before launching the developer. This chapter covers how to write, maintain, and keep a working orchestra.

---

## What This Is

The orchestra is a single file: `.claude/rules/common/agents.md`. It is not a config file — there is no YAML or JSON that Claude interprets mechanically. It is a Markdown document of trigger tables, flow sequences, and tier rules that Main Claude reads as prose and applies directly. Main Claude reads it like an instruction manual every session and uses it to decide what to do with every incoming message.

Think of it as the traffic controller between the human and the specialist agents. The human sends a message. Main Claude reads agents.md, classifies the message, and routes it to the correct agent with the correct mode, in the correct order, passing only the correct context.

Without agents.md, Main Claude has to guess all of this. It might use agents sometimes and skip them other times. It might fire the wrong agent on a bug report. It might skip the quality loop after implementation. The orchestra makes all of these decisions deterministic.

### How agents.md Fits in the Setup

```
User types message
      ↓
Main Claude reads CLAUDE.md (mandatory every session)
      ↓
Main Claude reads agents.md trigger table
      ↓
Message matches a trigger?
      ├─ YES → launches the defined agent sequence in the defined mode
      └─ NO  → Main Claude answers directly (INFO prompt type)
```

agents.md does not fire agents automatically. Main Claude reads it and applies the routing logic. This is why the file must be written in unambiguous language — Claude cannot ask for clarification mid-session about what agents.md means. Every ambiguity produces inconsistent behavior.

### How It Differs From CLAUDE.md

| | CLAUDE.md | agents.md |
|-|-----------|-----------|
| Purpose | Identity, core rules, mandatory workflows | Routing logic and agent sequences |
| Read by | Main Claude (always) | Main Claude (via rules/ loading) |
| Contains | Role, critical rules, session protocol | Trigger tables, flow sequences, tier rules |
| Size | ~300–500 lines max | As long as needed — it is reference material |
| Update trigger | Fundamental project rules change | Any new agent, trigger, or workflow added |

The critical trigger patterns (especially the `bug::` handler) should appear in CLAUDE.md's mandatory checkpoint section AND in agents.md. CLAUDE.md gives them priority-one attention. agents.md gives them full specification.

---

## Why It Exists (The Problem It Solves)

**Without agents.md:** Agents exist as files in `.claude/agents/` but have no systematic trigger. Main Claude uses them when it feels appropriate and skips them when it decides it can handle the task directly. An agent designed to fire on every bug report fires on some bug reports. The systematic-debugger is bypassed on the bugs where Main Claude is "confident" it understands the issue — which is exactly the class of bugs that require runtime evidence.

**With agents.md:** Every message type has a defined routing decision. A `bug::` prefix always fires the systematic-debugger, no exceptions. A "develop X" request always checks for a plan first. The post-implementation quality loop always runs in the correct phase order. No case-by-case judgment.

### The Cost of a Missing Orchestra Entry

Creating an agent file completes 50% of the work. The other 50% is registering it in the orchestra.

Common scenario: a developer creates a `security-reviewer.md` agent. The agent is well-designed. But agents.md has no entry specifying when to launch it. Main Claude never launches it — not because it is unwilling, but because it has no instruction telling it when this agent is the right choice. The security reviewer sits in `.claude/agents/` doing nothing for the rest of the project.

### The "Two of Three" Rule

Three things must be in sync for an agent to fire reliably:

1. **Agent file exists** at `.claude/agents/[name].md`
2. **agents.md entry exists** with trigger condition and launch mode
3. **CLAUDE.md trigger exists** in the mandatory checkpoint section (for primary workflow agents)

Any two of three produces unreliable behavior:
- Agent file + agents.md entry, no CLAUDE.md trigger → agent fires in rules-mode but may be skipped when CLAUDE.md checkpoint is checked first
- agents.md entry + CLAUDE.md trigger, no agent file → Main Claude tries to launch something that doesn't exist
- Agent file + CLAUDE.md trigger, no agents.md entry → agent fires inconsistently (only when CLAUDE.md is the reference, not when the full routing table is consulted)

All three must be in sync. Orchestra management is the discipline of keeping them synchronized.

---

## How It Works

### Main Claude's Routing Sequence

For every prompt, Main Claude runs this internal reasoning sequence before taking any action. Every rule in agents.md maps to one of these six steps:

```
1. CLASSIFY  → What type is this prompt? (BUG / BUILD / CAPTURE / PLAN / INFO)
2. VERIFY    → Do I have enough context to route this safely?
3. ROUTE     → Which agent sequence does this trigger?
4. GATE CHECK → Does anything block me from proceeding?
5. ACT       → Launch the defined sequence
6. VALIDATE  → Did the output meet the expected standard?
```

CLASSIFY maps to the trigger table. ROUTE maps to the agent sequence. GATE CHECK maps to the Confirmation Gate and evidence requirements. VALIDATE maps to the quality tier decision.

### The 5 Prompt Types

Every message belongs to exactly one of these types. Main Claude classifies on first read — before reading the message content in detail.

| Type | Signal Words | What fires |
|------|-------------|-----------|
| `BUG` | `bug::`, `issue::`, `fix`, "wrong/broken/not working" | systematic-debugger → developer |
| `BUILD` | `develop`, `implement`, `build`, `add`, `create` | plan check → developer pipeline |
| `CAPTURE` | Describes behavior without action verb | fr-analyst (background) |
| `PLAN` | `plan`, `design approach`, `how would you structure` | planner → Confirmation Gate |
| `INFO` | `what is`, `how does`, `explain`, `show me` | Main Claude answers directly |

Classification happens before detailed reading. A `BUG` prompt and a `BUILD` prompt may both result in code changes but require completely different internal processes. `BUG` requires root cause investigation first. `BUILD` requires a plan check first. Misclassifying them produces the wrong output.

> **NOTE:** `INFO` is the only type where Main Claude answers directly without routing to any agent. Informational questions (not requests for action) are answered from loaded memory files. If a developer accidentally phrases a feature request as a question, it may classify as `INFO` and no agent fires. See [Chapter 17: Predefined Prompt Patterns] for correct phrasing for each prompt type.

---

## 9.1 — What agents.md Actually Is

agents.md is read by Main Claude as a set of routing instructions written in Markdown. The formats that produce consistent behavior:

- **Trigger tables**: `| User Request Pattern | Required Agent | Launch Mode | Condition |` — the clearest way to express routing decisions. Claude reads tables faster than paragraphs for reference material.
- **Numbered sequences**: for multi-step agent chains where order matters (systematic-debugger → developer → code-reviewer)
- **ASCII flow diagrams**: for branching decisions (FR exists? → yes → skip planner / no → launch planner)
- **Tier tables**: for quality loop decisions (Tier 1 / Tier 2 / Tier 3 with conditions)

**Location:** `.claude/rules/common/agents.md`

The file is loaded via the rules system every session because it lives in `.claude/rules/`. You do NOT need to reference it in CLAUDE.md for it to be read. You DO need to mirror the critical trigger patterns (especially `bug::` handling) in CLAUDE.md's mandatory checkpoint section, because those need highest-priority emphasis that rules/ loading alone doesn't guarantee.

Write agents.md in clear imperative language. Every sentence is an instruction Main Claude will follow literally. "You should consider launching..." produces inconsistent behavior. "Launch systematic-debugger. No exceptions." does not.

---

## 9.2 — Why Orchestra Matters

Without a functioning orchestra, the agent system degrades into an inconsistent, human-dependent mess:

| Scenario | Without orchestra | With orchestra |
|----------|-----------------|----------------|
| Bug reported | Main Claude might investigate directly | systematic-debugger always fires |
| Feature described without action verb | Main Claude might plan it immediately (scope overreach) | fr-analyst captures requirements first |
| Post-implementation | Quality loop runs "if Claude feels like it" | ui-reviewer → code-reviewer → doc-updater always run in order |
| New agent created | Never fires until someone manually asks for it | Registered trigger fires it consistently |
| Agent refuses with DATA GATE | Main Claude might re-investigate | Fixed response: forward message, wait for log |

The orchestra transforms the agent system from a set of tools you manually invoke into a system that runs itself. The return on investment comes from the second month of use — by then, the cumulative saved decision-making (which agent? which mode? which order?) exceeds the time spent writing agents.md.

---

## 9.3 — Trigger Classification System

Every orchestra needs these minimum trigger categories. They cover the daily development workflow with no gaps.

### Bug Trigger — Highest Priority

```markdown
bug:: [description]    → systematic-debugger (foreground, always first)
issue:: [description]  → systematic-debugger (foreground, always first)
fix [description]      → systematic-debugger (foreground, treat same as bug::)
```

The `bug::` trigger is the highest priority entry in agents.md. It must appear first in the file — before all other triggers. Even if a message sounds like it might be a feature request, any "fix/bug/issue" signal fires systematic-debugger first.

**Why no exceptions:** An agent that skips the systematic-debugger on a bug report investigates based on static code analysis — a hypothesis, not evidence. The fix it produces has roughly a 30% chance of addressing the actual root cause. The other 70% of the time, a new bug is introduced on top of the existing one.

### Development Trigger

```markdown
develop [module]      → plan check → developer
implement [feature]  → plan check → developer
build [system]       → planner → developer (plan always first for new systems)
add [component]      → developer directly (skip planner)
create [file/class]  → developer directly (skip planner)
```

**The plan check** runs before every `develop`, `implement`, and `build` trigger:

```
Does a plan already exist?
    ├─ YES (Implementation Tasks file found in docs/FR/) → developer directly
    └─ NO
          ├─ Feature is simple (≤3 files, no new module) → developer directly
          └─ Feature is complex (>3 files, new module, cross-module) → planner first
```

### Planning Trigger

```markdown
plan [feature]               → planner (foreground) + Confirmation Gate
design approach for [system] → planner (foreground) + Confirmation Gate
```

Confirmation Gate is mandatory after planner output. The human asked for a plan, not an implementation. Launching developer without explicit human approval violates the "Clarify → Suggest → Confirm → Build" operating model.

```
User: "plan UserModule"
      ↓
planner runs (foreground)
      ↓
planner outputs implementation plan
      ↓
⛔ Confirmation Gate — END MESSAGE. Wait.
      ↓
Human: "looks good, proceed"
      ↓
developer launches
```

### Requirement Capture Trigger

```markdown
[Human describes behavior without action verb]  → fr-analyst (background)
```

Example: "I want users to be able to filter profiles by age range" — no action verb. This is a `CAPTURE` prompt, not a `BUILD` prompt. fr-analyst documents the requirement before any implementation is discussed. Jumping to developer on a CAPTURE prompt is scope overreach.

### Post-Implementation Quality Loop

```
Developer marks feature REVIEW
      ↓
New screens created?
      ├─ YES → ui-reviewer (foreground, max 2 passes) — Phase 1
      └─ NO  → skip Phase 1
      ↓
Always → code-reviewer (foreground, targeted to changed files) — Phase 2
      ↓
Sensitive surface changed?
      ├─ YES → security-reviewer (foreground) — Phase 3
      └─ NO  → skip Phase 3
      ↓
Always → doc-updater (background) — Phase 4a
      ↓
Always → project-map (background, AFTER doc-updater) — Phase 4b
```

### Priority Order

When a message could match multiple triggers, apply this priority:

```
1st — BUG (bug::, issue::, "fix") — always wins
2nd — Build error reports ("flutter analyze failing") → build-error-resolver
3rd — BUILD (develop, implement, build) — standard development
4th — PLAN (plan, design approach) — planning-only requests
5th — CAPTURE (requirement description, no action verb) → fr-analyst
6th — INFO (questions) — Main Claude answers directly, no agent
```

> **CRITICAL:** Never let a `BUILD` trigger override a `BUG` trigger. "fix the login screen so users can stay logged in" is a BUG/FIX request. The word "fix" is the signal. systematic-debugger fires first regardless of what else the message says.  
> If violated: Main Claude starts planning an implementation for a broken feature without investigating why it's broken. The implementation is built on a misunderstood symptom.

---

## 9.4 — Foreground vs. Background

Every agent launch requires a mode decision. Getting this wrong is the second most common orchestra mistake after missing entries entirely.

**Foreground:** Main Claude waits for the agent to complete before taking the next step. Use when:
- Main Claude needs the agent's output to decide what to do next
- The output feeds another agent that cannot start without it
- A correction loop exists (reviewer → developer → reviewer)

**Background:** Agent runs independently. Main Claude continues or the session completes. Use when:
- The output is documentation — it doesn't block any decision
- The human can receive a response faster without waiting
- The agent's work is fully independent of everything else happening

### Mode Decision Table

| Agent | Mode | Why |
|-------|------|-----|
| systematic-debugger | Foreground | Root cause gates the developer launch |
| planner | Foreground | Plan gates the developer launch |
| developer | Foreground | Implementation output is the main deliverable |
| ui-design-enforcer | Foreground | Design brief gates the developer launch |
| ui-reviewer | Foreground | Correction brief feeds developer correction pass |
| code-reviewer | Foreground | Review findings feed developer correction pass |
| security-reviewer | Foreground | CRITICAL findings require immediate action before proceeding |
| fr-analyst | Background | FR package is documentation — doesn't block any current task |
| doc-updater | Background | Registry updates don't block anything |
| project-map | Background | Map regeneration doesn't block anything |

### The Risk of Wrong Mode

- **Foreground when background is fine:** Unnecessary blocking. Main Claude and the human wait for doc-updater to finish before getting a response — when the docs update could have happened in parallel.
- **Background when foreground is needed:** Main Claude proceeds to the next step without waiting for critical output. Example: code-reviewer runs in background, Main Claude marks the feature done, then the review returns with three CRITICAL findings that were never addressed.

The quality loop agents (ui-reviewer, code-reviewer, security-reviewer) must always be foreground because Main Claude needs their output to feed corrections to the developer agent. Background agents do not support this feedback loop.

---

## 9.5 — Stateful vs. Stateless Agent Sessions

This is one of the most consequential design decisions in the agent system. How you design data handoffs depends entirely on whether your runtime supports stateful sessions.

### What Stateful Means

A stateful session means the same agent conversation continues across multiple user messages. The agent remembers everything said above in the conversation.

Example: FR analyst asks 5 clarifying questions across 5 messages. In a stateful session, when the human answers question 5, the agent has full context from questions 1–4.

**How it works in Claude Code:** Use `SendMessage` to the same agent ID. The agent conversation is preserved across all messages in that session.

### What Stateless Means

A stateless session means every agent launch is a fresh instance. The agent only knows what is in its launch prompt.

Example: same FR analyst scenario — when the human answers question 5, the agent only knows about question 5 unless the answers to questions 1–4 are included in the launch prompt.

**Common stateless environments:** IDEs other than Claude Code (Copilot, Cursor). Also applies in Claude Code when the agent's context window has been fully compacted or a new session starts after a break.

### Why This Matters in Practice

The systematic-debugger DATA GATE is the clearest example. After DATA GATE fires:

| Runtime | What to send | What NOT to send |
|---------|-------------|-----------------|
| **Stateful** | Only the raw console log to the same agent ID | Do not resend the bug description — agent already has it |
| **Stateless** | Bug description + module + raw console log in one launch | Do not send log only — agent has no prior context |

Stateless strategy in a stateful runtime wastes context (resending what the agent already has). Stateful strategy in a stateless runtime breaks (agent receives log with no context).

### Designing Agents for Both Modes

Every agent in the setup must work in both modes. Two rules:

1. **Never rely on prior conversation memory inside an agent.** Every gate must be self-contained. If a gate needs information from Step 1 to run Step 2, that information must be explicitly passed in the prompt.

2. **Stateless follow-up format:** when continuing a stateless agent, the prompt must contain all three required blocks:

   ```
   Original context: [original task/bug description]
   Inferred scope:   [module / screen / feature]
   New input:        [raw console log / human answer / correction]
   ```

   Zero additions beyond these three blocks. No analysis. No "Key observations." No hypothesis.

State in agents.md which runtime the project uses so Main Claude knows which strategy to apply.

---

## 9.6 — Stateful Session: Continue vs. Start Fresh

Within a stateful runtime, not every follow-up message should go to the same agent session. Knowing when to continue vs. start fresh prevents context contamination between unrelated tasks.

### Continue (SendMessage to Same Agent ID)

Continue when:
- The agent is mid-process and needs the human's next input to proceed
- The agent asked a specific question and is waiting for the answer
- It is the **same task continuing** — not a different task of the same type

Examples:
- FR analyst has asked three clarifying questions and is waiting for answers to complete the FR package
- systematic-debugger has fired DATA GATE and is waiting for the console log paste
- planner has asked about a missing business rule before it can finalize the implementation plan

### Start Fresh (New Agent Launch)

Start fresh when:
- The previous task is complete and you are beginning a different task of the same type
- The agent's context window is full (checkpointing has preserved state, start from checkpoint)
- The task type changed completely (moving from bug investigation to new feature implementation)

The key test: **"Is this the same task continuing, or a new task of the same type?"**
- Same task → continue
- New task → fresh

### Prior Context Handoff Brief

When stateful continuation is unavailable (session ended, context full, runtime limitation), provide a handoff brief in the new agent launch prompt:

```
Prior context:
  Task: [original task description]
  Decisions made: [what was agreed or confirmed so far]
  Current state: [where the agent stopped]
  Open question: [what the agent needs to proceed]

New input: [human's latest message or data]
```

Main Claude includes this brief in the new launch prompt so the fresh instance has necessary context without the full conversation history.

---

## 9.7 — Agent Data Passing Contracts

For every agent-to-agent transition in the setup, define exactly: what data passes, what Main Claude does or does not add, and what the receiving agent expects. Without this contract, the "telephone game" failure occurs: each step adds interpretation, and by the time context reaches the developer agent, the original user intent is buried under layers of Main Claude's paraphrasing.

### The Transition Contract Table

| Transition | What passes | Main Claude adds | Receiving agent expects |
|------------|-------------|-----------------|------------------------|
| User → systematic-debugger | Raw bug description | Screen/module inference + project root. Nothing else. | Unprocessed bug description |
| systematic-debugger → developer | Confirmed Handoff Brief | Nothing — forward the brief as-is | Root cause with CONFIRMED evidence status |
| planner → developer | Implementation plan | FR file paths as additional context | Structured plan with phases |
| developer → ui-reviewer | REVIEW notification | Changed files list | Files to review (not the implementation brief) |
| ui-reviewer → developer | Correction brief | Nothing — forward as-is | Specific violations with file:line references |
| developer → doc-updater | DONE notification | New components and API endpoints created | List of new artifacts to register |
| doc-updater → project-map | Completion signal | Nothing | Signal to regenerate the map |

### The Telephone Game Failure

This is what happens when data passing contracts are missing for the systematic-debugger → developer transition:

```
systematic-debugger produces: confirmed finding with log line proof
Main Claude summarizes: "The issue seems to be in the controller where..."
Main Claude adds: "I think we should also check the repository while we're at it"
Developer receives: Claude's interpretation + Claude's additional suggestions
Developer acts on: interpretation instead of confirmed evidence
Result: wrong fix, potential new bugs introduced
```

The contract prevents this. "Main Claude adds: nothing" is as important as what passes.

### The Raw vs. Processed Prompt Rule

This is the most commonly misapplied rule in the agent system:

**Pass raw when:** The first agent in a sequence has a classification gate that must fire on unprocessed input. If Main Claude analyzes the input first, that gate gets bypassed.

**Pass processed when:** The agent receives the confirmed output of a previous agent. It does not need to re-analyze — it needs to act on the confirmed finding.

The systematic-debugger always receives raw input. Adding investigation steps to the prompt bypasses the DATA GATE. The developer always receives the processed Handoff Brief. These are the two most consequential data passing contracts in the setup.

---

## 9.8 — The Quality Tier System

Every code change triggers a post-implementation review. The review must be proportional to the risk of the change. Over-reviewing a one-line widget change wastes tokens and time. Under-reviewing a new authentication flow creates security gaps.

### The Three Tiers

**⚡ Tier 1 — Simple UI / Widget Change**

When: widget property changes, text or label changes, adding or removing a single widget, reordering elements, show/hide flags.

| Check | Required |
|-------|----------|
| `flutter analyze` (run by developer) | ✅ YES |
| code-reviewer agent | ❌ NO |
| ui-reviewer agent | ❌ NO |
| security-reviewer | ❌ NO |

Developer produces a one-line summary. No agent review needed. The analyzer catches everything relevant for this tier.

---

**🔍 Tier 2 — Logic / State / Behavior Change**

When: state management logic modified, API data flow changed, navigation result handling, async operations, pagination state, local storage reads/writes.

| Check | Required |
|-------|----------|
| `flutter analyze` | ✅ YES |
| code-reviewer (targeted, changed files only) | ✅ YES |
| ui-reviewer | ❌ NO (unless visible UI layout was also changed) |
| security-reviewer | Conditional — only if sensitive surface changed |
| doc-updater | Conditional — only if a new reusable pattern was introduced |

code-reviewer scope: changed methods and their direct callers only. Do not scan the entire file. Do not grep project-wide unless a dependency question arises.

---

**🏗️ Tier 3 — New Feature / Shared File Change**

When: new screens created, new API endpoints wired, shared model changes, cross-module changes, new injectable services or dependencies.

| Phase | Agent | Mode | Loop Limit |
|-------|-------|------|------------|
| 1 — UI Review | ui-reviewer | Foreground | Max 2 correction passes |
| 2 — Code Review | code-reviewer | Foreground | 1 correction pass |
| 3 — Security | security-reviewer | Foreground | Conditional (see below) |
| 4a — Docs | doc-updater | Background | No loop |
| 4b — Map | project-map | Background | After doc-updater |

Phase 1 runs only when new screen files were created. If the feature is API + domain layer only with no new screens, skip Phase 1.

### Sensitive Surface Triggers (security-reviewer Required)

security-reviewer runs in Tier 2 or Tier 3 only when ANY of these changed:
- Authentication, session tokens, login or logout flow
- API endpoint wiring, request construction, or response parsing
- Local storage of sensitive values (credentials, tokens, personal data)
- User input validation and sanitization paths
- External service integration with API keys
- File uploads, permissions checks, or role-based access control

### Writing Tier Rules in agents.md

Use explicit tables, not paragraphs. The table format scans faster and is harder to misinterpret:

```markdown
## Post-Implementation Tier

| Tier | When | Required checks |
|------|------|-----------------|
| Tier 1 | Widget/text/label/property change only | flutter analyze only |
| Tier 2 | State/logic/behavior change | flutter analyze + code-reviewer (targeted) |
| Tier 3 | New feature/screen/shared endpoint | Full quality loop (Phases 1–4) |
```

The tier is determined by Main Claude based on what was actually changed — not by what the developer says was changed. Main Claude reads the developer's change summary and classifies from the "When" column.

### Planner Trigger: Even When an FR Exists

The plan check before developer launch has a second condition that many developers omit. Even when an FR implementation plan exists, planner may still need to run. This applies when ANY of these are true:

| Complexity Trigger | Why Planner Runs |
|-------------------|-----------------|
| Touches a shared file with many callers | Impact analysis needed before developer starts |
| Requires cross-module event coordination | Event naming must be agreed before implementation |
| Creates more than 8 new files | Multiple modules → architectural integration risks |
| Has integration risk with in-progress work on the same branch | Conflicts must be resolved first |
| FR Implementation_Tasks.md is incomplete (missing phases, edge cases, or locale keys) | Incomplete plan → invisible assumptions |

If any trigger is checked, run planner even though FR docs exist. FR docs capture WHAT to build. The planner adds HOW to integrate it safely when architectural risk is present. These are different questions.

---

## 9.9 — Keeping the Orchestra Current

Orchestras decay. As a project grows, new agents are created, new trigger patterns emerge, and old entries become stale. Without active maintenance, the orchestra becomes a mix of working routes and broken ones — and the failures are silent (agent doesn't fire) rather than loud (error message).

### Mandatory Updates After Every Agent Change

After creating any new agent:
1. Add an entry to agents.md under the correct trigger category
2. If the agent introduces a new trigger prefix (e.g., `"audit::"`) → add that prefix to CLAUDE.md's mandatory checkpoint section
3. If the agent is part of the quality loop → add it to the quality loop phase table
4. Run the "two of three" check: agent file ✅ + agents.md entry ✅ + CLAUDE.md trigger ✅

After removing an agent:
1. Remove the agents.md entry
2. Remove the CLAUDE.md trigger patterns for that agent
3. Update any quality loop phase tables that referenced it
4. Check which other agents were sending context to the removed agent — update those data passing contracts

### Orchestra Review Schedule

Run an orchestra review at these milestones:
- After adding 2+ new agents (new additions may interact with existing routing)
- Before a major feature release (verify the quality loop is complete and correctly ordered)
- When an agent consistently produces unexpected output (may be a routing issue, not an agent design issue)
- When a new developer joins the project (verify the orchestra makes sense to a fresh reader)

### The Review Checklist

For each entry in agents.md, verify:
- [ ] Does the trigger still correctly classify the intended message types?
- [ ] Does the agent file still exist at the referenced path?
- [ ] Is the mode (foreground/background) still correct for the current workflow?
- [ ] Are the data passing contracts still valid (no intermediate steps added by Main Claude that bypass gates)?
- [ ] Has the quality tier assignment changed for any of this agent's use cases?

---

## Parallel vs. Sequential Execution

When multiple agents are involved in a workflow, the execution order matters. Running agents in parallel when they depend on each other produces incorrect results. Serializing independent agents that could run in parallel wastes time.

### Always Sequential (each waits for the previous)

| Sequence | Why sequential |
|----------|----------------|
| systematic-debugger → developer | Developer needs the confirmed Handoff Brief before applying any fix |
| planner → developer | Developer needs the implementation plan before writing code |
| ui-reviewer → developer → ui-reviewer | Correction feedback loop — reviewer needs to see corrected code, not original |
| doc-updater → project-map | project-map reads the registry files that doc-updater just wrote — parallel means stale data |

### Can Run in Parallel (independent outputs)

| Agents | Why parallel is safe |
|--------|---------------------|
| code-reviewer + security-reviewer | Both review the same code; neither needs the other's output to proceed |
| fr-analyst + main conversation activity | FR runs in background, independently of other active tasks |
| doc-updater + anything not reading `docs/memory/` files | Documentation updates don't block other work |

### How to Specify in agents.md

Write the parallel rule explicitly so Main Claude doesn't have to infer it:

```markdown
## Parallel Execution

Always launch in the same message (parallel):
- code-reviewer + security-reviewer — both reviewing same change, independent outputs

Always wait for previous to complete (sequential):
- systematic-debugger → developer (brief required before fix)
- doc-updater → project-map (map reads fresh registry data from doc-updater)
```

---

## When Agents Refuse to Proceed

Every well-designed agent has hard stops — conditions under which it will not output a result and instead requests specific missing input. These refusals are correct behavior, not agent failures. The orchestra must specify how to handle each refusal.

### Refusal Table

| Agent | Refuses when | Output instead | Correct response |
|-------|-------------|---------------|-----------------|
| systematic-debugger | Data mismatch bug, no console log | "⏸️ DATA MISMATCH DETECTED" | Copy to human verbatim. Wait. |
| systematic-debugger | Log is truncated/incomplete | cURL command to fetch complete response | Forward command to human verbatim |
| systematic-debugger | Feature request detected in bug:: | "⛔ NOT A BUG — redirecting" | Route to fr-analyst |
| ui-design-enforcer | Design question answered vaguely | "Design thinking incomplete. Re-answer Q[N]: [what's missing]" | Ask human to answer the specific missing question |
| developer | Brief references function that doesn't exist | "⚠️ Brief Verification Failed" | Return to systematic-debugger, verify the brief |
| developer | Context window near limit on large task | Checkpoint output, clean stop | Resume from checkpoint in new session |
| code-reviewer | Developer workflow steps were skipped | "Workflow incomplete. Missing: [X]" | Complete the missing developer steps, then re-launch |
| ui-reviewer | More than 2 correction passes still failing | Escalates to human | Human reviews correction brief directly |
| planner | FR docs contain contradictions or scope gaps | Explicit flag, waits for human | Resolve contradiction with human, re-launch planner |

> **CRITICAL:** The DATA GATE refusal from systematic-debugger is the most commonly mishandled case. When the agent outputs "⏸️ DATA MISMATCH DETECTED," Main Claude must copy that message to the human verbatim and wait. It must NOT investigate directly, re-launch the agent, or add analysis. The DATA GATE response IS the agent working correctly — it found the relevant endpoint and is waiting for runtime evidence before forming any hypothesis.  
> If violated: Main Claude forms a static-analysis hypothesis and presents it as a confirmed root cause. The developer applies a fix to wrong code. A new bug is introduced.

---

## Context Budget Management

The orchestra must adapt its routing based on where Claude is in its context window. Complex, multi-file tasks launched at 85% context capacity produce degraded output — Claude has less working memory for reasoning.

### The 80/20 Rule

```
First 80% of context window:
  → All task types available
  → Multi-file features, complex debugging, full quality loops — all fine

Last 20% of context window:
  → Avoid: large refactoring, multi-file feature implementation, complex investigation
  → Prefer: single-file edits, documentation updates, simple one-method fixes
  → If a complex task arrives: acknowledge it, recommend starting a new session
```

### Mid-Task Checkpointing

For tasks spanning many files (4+ files), the developer agent writes checkpoint lines to the pipeline status file as each file is completed:

```
[CHECKPOINT] FeatureName — ✅ domain/user_entity.dart | next: data/user_repository.dart
```

When context runs out mid-task, the next session reads the checkpoint and resumes from where work stopped. Without checkpoints, the next session must re-derive the state of work from scratch — expensive and error-prone.

Include in agents.md:

```markdown
## Context Budget Rule

If context window is at or above 80%:
- Do not start large refactoring tasks
- Do not start multi-file feature implementation
- Do not start complex bug investigation
- For complex tasks arriving at 80%+: acknowledge the task, recommend new session

Mid-task checkpoint format (developer writes to _pipeline_status.md):
[CHECKPOINT] [FeatureName] — ✅ [completed file] | next: [next file]
```

---

## Setup

### Prerequisites Check

- [ ] `.claude/agents/` directory exists with at least one validated agent file
- [ ] `.claude/rules/common/` directory exists
- [ ] At least one agent has been validated using the process in [Chapter 8: Agent Creation Guide], section 8.6

### Step-by-Step

**1. Create the file**

Create `.claude/rules/common/agents.md`. This file will grow as agents are added. Start with only the triggers you have agents for.

**2. Write the bug trigger section (goes first, before all other content)**

```markdown
## Bug / Issue Trigger — HIGHEST PRIORITY

Check this before ANY other trigger.

If message starts with `bug::`, `issue::`, or contains `fix [description]`:

1. Launch systematic-debugger (foreground) — MANDATORY. No exceptions.
   Pass: raw bug description + inferred screen/module + project root
   NOTHING ELSE — no investigation steps, no file suggestions, no hypotheses

2. Two possible responses — handle each differently:
   - "⏸️ DATA MISMATCH DETECTED" → copy verbatim to human, wait for log paste
     Stateful: send only raw log to same agent ID
     Stateless: re-launch with original bug + module + raw log (3 blocks only)
   - Handoff Brief with root cause → verify evidence status is CONFIRMED → launch developer

3. NEVER after DATA GATE response:
   - Investigate directly
   - Re-launch agent claiming "it didn't run properly"
   - Add analysis before forwarding log to agent
```

**3. Write the development trigger section**

```markdown
## Development Triggers

Step 0 — Before launching developer, check for existing implementation plan:
- Plan exists (docs/FR/*_Implementation_Tasks.md) → developer directly
- No plan + complex (>3 files or new module) → planner first
- No plan + simple (≤3 files, contained) → developer directly

| Request Pattern | Agent | Mode |
|----------------|-------|------|
| "develop [module]" with new screens | ui-design-enforcer → developer | foreground |
| "develop [module]" logic only | developer | foreground |
| "add [component]" | developer | foreground |
| "create [file]" | developer | foreground |
```

**4. Write the planning trigger section**

```markdown
## Planning Triggers

| Request Pattern | Agent | Gate |
|----------------|-------|------|
| "plan [feature]" | planner | Confirmation Gate — wait for human before developer |
| "design approach for [system]" | planner | Confirmation Gate |
```

**5. Write the quality tier section**

Use the three-tier table format from section 9.8.

**6. Write the parallel execution section**

Use the sequential vs. parallel tables from the Parallel vs. Sequential section.

**7. Write the agent refusal handling section**

Use the refusal table from the When Agents Refuse section.

**8. Add the agent roster**

```markdown
## Agent Roster

| Agent | Trigger | Mode |
|-------|---------|------|
| systematic-debugger | bug::, issue::, "fix" | foreground |
| fr-analyst | Requirement description | background |
| planner | plan, design approach, no-plan complex feature | foreground |
| developer | Any code writing request | foreground |
| ui-design-enforcer | develop/implement + new screens | foreground |
| ui-reviewer | Post-implementation (new screens, Tier 3) | foreground |
| code-reviewer | Post-implementation (Tier 2+) | foreground |
| security-reviewer | Sensitive surface changes | foreground |
| doc-updater | Post-implementation (always) | background |
| project-map | After doc-updater (always) | background |
| tdd-guide | "write tests for [feature]" | foreground |
| build-error-resolver | Human reports build error | foreground |
| refactor-cleaner | "refactor [module]", "clean [code]" | foreground |
| e2e-runner | "run e2e", "write integration tests" | foreground |
```

**9. Run the "two of three" check for each agent**

For every agent in the roster:
- [ ] Agent file exists at `.claude/agents/[name].md`
- [ ] agents.md entry exists with trigger and mode
- [ ] If this agent is a primary workflow agent, its trigger appears in CLAUDE.md's mandatory checkpoint section

---

## Validation

### Validation Test 1: Bug Trigger Routes Correctly

**Purpose:** Verify systematic-debugger fires on every bug report variant.

**Trigger:**
Type: `bug:: The item count shows 0 but there are 5 items visible in the list`

**Expected result:**
Main Claude launches systematic-debugger immediately. It does NOT investigate the bug itself. It does NOT read any source files. It does NOT suggest which file to check.

**If you see Main Claude saying "Let me look at the screen file...":**
→ agents.md bug trigger section is missing or not at the top of the file. Move it to the first section with explicit "HIGHEST PRIORITY" language.

---

### Validation Test 2: Development Request Routes Through Plan Check

**Purpose:** Verify the plan check runs before developer launch.

**Trigger:**
Type: `develop UserModule` (with no existing FR implementation plan in docs/FR/)

**Expected result:**
Main Claude checks for `docs/FR/UserModule/*_Implementation_Tasks.md`. Finding none, and assuming the module involves more than 3 files, it launches planner first. It does NOT launch developer directly.

**If Main Claude launches developer immediately:**
→ agents.md plan check rule is missing. Add the "Step 0 — Before launching developer, check for existing plan" section with explicit conditions.

---

### Validation Test 3: Quality Tier Classification

**Purpose:** Verify Tier 1 fires for simple changes and skips reviewer agents.

**Setup:**
Have developer make a single-property change (e.g., add `maxLines: 3` to a Text widget).

**Expected result:**
Developer applies the change, runs `flutter analyze`. Main Claude classifies as Tier 1. Neither code-reviewer nor ui-reviewer launches.

**If code-reviewer launches for a one-line widget property change:**
→ agents.md tier rules are missing the explicit Tier 1 exclusion. Add: "Tier 1 — widget/text/property change: flutter analyze only, no reviewer agents needed."

---

### Validation Test 4: Parallel Agent Launch

**Purpose:** Verify code-reviewer and security-reviewer launch in parallel on a Tier 3 feature.

**Setup:**
Complete a Tier 3 feature (new API endpoint + new screen). Observe the quality loop launch sequence.

**Expected result:**
code-reviewer and security-reviewer launch in the same message — one tool call per agent, not sequential launches.

**If they launch one after the other:**
→ agents.md parallel execution section is missing. Add the "Can Run in Parallel" table specifying code-reviewer + security-reviewer as safe to parallelize.

---

## Common Mistakes

### Mistake 1: Bug Trigger Not First in the File

**Symptom:** On `bug::` messages, Main Claude sometimes investigates directly or launches the wrong agent. Behavior is inconsistent across sessions.

**Cause:** agents.md has the bug trigger buried after development triggers or planning triggers. Main Claude reads the file and may match a later trigger first.

**Fix:** Move the bug trigger to the very first section of agents.md, with explicit "HIGHEST PRIORITY — check before all other triggers" language. Placement order in the file reflects reading priority.

---

### Mistake 2: Wrong Mode on Quality Loop Agents

**Symptom:** Main Claude sends a completion message to the human before code-reviewer results arrive. CRITICAL findings in the review are never addressed.

**Cause:** code-reviewer was configured as background mode. Main Claude does not wait for the results.

**Fix:** All agents in the correction phases of the quality loop (ui-reviewer, code-reviewer, security-reviewer) must be foreground. Only doc-updater and project-map are background.

---

### Mistake 3: Planner Trigger Missing the Complexity Checklist

**Symptom:** Developer launches directly on a complex cross-module feature even when the FR implementation tasks file is incomplete. Integration bugs appear mid-implementation that a planner pass would have caught.

**Cause:** agents.md plan check has only two conditions: "plan exists → skip planner" and "no plan → launch planner." The five complexity triggers are missing.

**Fix:** Add the complexity trigger table (see section 9.8). Any checked trigger runs planner even when FR docs exist.

---

### Mistake 4: doc-updater and project-map Run in Parallel

**Symptom:** project-map regenerates but references stale registry data. New components registered by doc-updater don't appear in the map.

**Cause:** doc-updater and project-map launched in parallel. project-map reads the registry files before doc-updater has finished writing to them.

**Fix:** Add to agents.md: "project-map runs AFTER doc-updater completes — never in parallel." Use the sequential constraint entry in the parallel execution table.

---

### Mistake 5: Orchestra Entry Missing After Agent Creation

**Symptom:** A new agent file was created and validated, but it never fires in real sessions. Main Claude does not use it.

**Cause:** The agent file exists but no agents.md entry was added. The "two of three" check was skipped.

**Fix:** Make agents.md update a mandatory step in your agent creation checklist. Agent creation is not complete until agents.md is updated and the "two of three" check passes.

---

### Mistake 6: DATA GATE Response Mishandled

**Symptom:** systematic-debugger outputs the DATA GATE message. Main Claude re-launches the agent or starts investigating directly. The bug is "confirmed" without runtime log evidence. The subsequent fix is wrong.

**Cause:** agents.md does not specify how to handle DATA GATE responses. Main Claude treats it as an agent failure and attempts to recover.

**Fix:** Add an explicit DATA GATE response handling block to agents.md:

```markdown
## DATA GATE Response Handling

When systematic-debugger outputs "⏸️ DATA MISMATCH DETECTED":
1. Copy the agent's message verbatim to the human — nothing more
2. Do NOT add analysis, investigation steps, or "key observations"
3. Wait for the human to paste the console log
4. Stateful runtime: send only the raw log to the same agent ID
5. Stateless runtime: re-launch with original bug description + module + raw log (3 blocks only)
```

---

## Reference

| Item | Value |
|------|-------|
| Primary file | `.claude/rules/common/agents.md` |
| Read by | Main Claude — every session via rules/ loading |
| Updated when | After every new agent creation, trigger addition, or quality loop change |
| Key sections | Bug trigger table + Development trigger + Quality tier table |
| "Two of three" check | Agent file ✅ + agents.md entry ✅ + CLAUDE.md trigger ✅ |
| Context budget rule | First 80%: all tasks fine. Last 20%: single-file work only |

---

*Next: [Chapter 10: Core Agents Deep Dive]*
