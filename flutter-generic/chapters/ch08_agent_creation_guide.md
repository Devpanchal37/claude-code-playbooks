# Chapter 8: Agent Creation Guide

> **Applies to:** Both
> **Prerequisites:** [Chapter 4: CLAUDE.md File], [Chapter 5: settings.json], [Chapter 7: Rules System]
> **Estimated read + setup time:** ~60 minutes

---

## TL;DR

Agents are specialized Claude instances defined as Markdown files in `.claude/agents/`. Each has its own isolated context window, its own identity, and a gate sequence that enforces quality checks before proceeding. A well-designed agent does one thing consistently, refuses wrong inputs, and produces output another agent can build on without re-verification. A badly designed agent produces confident-sounding wrong output with no error message, silently compounding mistakes downstream. This chapter is the most important skill in the entire setup — every sub-section is mandatory.

---

## What This Is

An agent is a Markdown file in `.claude/agents/[agent-name].md` that defines a specialized Claude instance. When Main Claude launches an agent, it loads that file as the agent's complete identity — its role, its gate sequence, its allowed tools, its output format, and what it explicitly refuses to do.

Agents are not macros. They don't run a fixed script. Each agent instance reasons within the constraints you define, which is why the constraints must be precise enough to produce consistent behavior, yet specific enough that edge cases are handled correctly rather than falling through to a default path.

### How Agents Compare to Skills

| Property | Agent | Skill |
|----------|-------|-------|
| Context window | Isolated — own clean context, not shared with Main Claude | Shared with Main Claude |
| Can have gates | Yes — blocks proceeding until conditions are met | No — flat instruction set |
| Launch mode | Foreground (Main Claude waits) or background (fire-and-forget) | Always inline in main conversation |
| Multi-step logic | Full — classification, investigation, decisions | Not supported |
| Best for | Complex, repeating workflows with quality gates | Quick one-off instruction sets |
| IDE support | Claude Code only | Any Claude Code IDE |

**The key distinction:** If the task needs classification logic, quality gates, multi-step workflows, or isolated context — use an agent. If it is a quick instruction set Main Claude follows inline — use a skill.

---

## Why Agents Exist (The Problem They Solve)

**Without agents:** Main Claude handles everything — requirements capture, code writing, code review, debugging, documentation. Every task runs in the same context window. After three or four features, the context is 60% full with previous conversation, and response quality degrades. One mistake in a requirements conversation contaminates the code-writing step because they share the same context.

**With agents:** Each concern has its own clean context window. The requirements agent focuses only on requirements — it has no memory of the last three screens you implemented. The debugging agent focuses only on root cause investigation — it has no memory of previous feature discussions that might bias its hypothesis. Each starts fresh, loads only the memory relevant to its job, and produces output the next agent can build on directly.

**The isolation is the point.** Narrow responsibility means narrow failure modes. When an agent produces wrong output, you know exactly where to look.

---

## 8.1 — When to Create an Agent

Not every recurring task warrants an agent. Agents require upfront design investment. A poorly designed agent is worse than no agent — it produces wrong output confidently, giving you false assurance while introducing errors downstream.

### The Three-Question Test

Before creating an agent, answer all three:

1. **Does this task have a defined, repeating sequence of steps?**
   A task that is different every time it runs cannot be codified into an agent gate sequence. An agent for "review code" works. An agent for "whatever feels right" does not.

2. **Does this task benefit from isolated context?**
   If the task needs to reason cleanly without contamination from previous conversations, isolation matters. Debugging, requirements analysis, and code review all benefit from isolation. Answering a quick question does not.

3. **Does this task happen repeatedly — often enough that the upfront design cost pays off?**
   If a task runs once per project, use Main Claude directly. If it runs once per feature (developer agent, code-reviewer) or on every bug report (systematic-debugger), the agent pays for itself within two uses.

**Rule:** If all three are YES — create the agent. If any is NO — use Main Claude directly or create a skill.

### What NOT to Create an Agent For

- Tasks that happen once (setting up a new project from scratch)
- Tasks that require human judgment as a core step (business decisions, design direction without structured questions)
- Tasks that are simple enough that the instruction fits in CLAUDE.md in three lines

---

## 8.2 — Agent File Format

Every agent file has the same structure: a frontmatter block followed by a body. Deviating from this structure causes the agent to behave unpredictably or not load at all.

### Frontmatter Block (Mandatory)

```yaml
---
name: agent-name
description: One-sentence description used by Main Claude to decide when to launch this agent. Must be precise enough to distinguish from all other agents.
tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
model: sonnet
---
```

**Field rules:**

| Field | Rule | Why |
|-------|------|-----|
| `name` | Lowercase with hyphens. Matches the filename. | Consistency — Main Claude references agents by name |
| `description` | One sentence. States the agent's job precisely. No vague language. | Main Claude reads ONLY this field to decide whether to launch the agent |
| `tools` | Include only tools this agent actually needs. No extras. | Unnecessary tools increase the agent's attack surface |
| `model` | `haiku`, `sonnet`, or `opus` — see model selection guide in Section 8.6 | Cost and quality must match task complexity |

> **CRITICAL:** The `description` field is the agent's routing signal. Main Claude reads the description to decide: "is this agent the right one for this task?" A vague description (e.g., "helps with code") means the agent fires for the wrong tasks — or never fires at all.
> If violated: Main Claude launches the wrong agent or skips the right one. The bug is silent — no error, just wrong routing.

### Body Sections (In This Order)

```
1. Identity/Role         — WHO this agent IS (not what it does — what it IS)
2. Pre-Step              — mandatory memory retrieval before any work begins
3. Classification Gate   — what inputs this agent accepts and what it redirects
4. Core Workflow         — numbered gates in execution order
5. Output Format         — exact template for what the agent produces
6. Explicit Exclusions   — what this agent does NOT do
```

Every agent needs all six sections. Missing the Pre-Step means the agent re-makes known mistakes. Missing the Classification Gate means the agent processes inputs it was not designed for. Missing the Exclusions means the agent "helpfully" does adjacent work that belongs to another agent.

### Section 1: Identity/Role

Write the agent's identity as what it IS, not what it does. The distinction matters because "what it IS" shapes every decision it makes, while "what it does" only describes its outputs.

```
# FeatureName Validator

You are a senior engineer specializing in validating feature requirements for completeness 
and consistency. You hold the product owner's perspective and the technical feasibility 
perspective simultaneously. You do NOT write code. You do NOT make implementation decisions.
You produce a validation report.
```

### Section 2: Pre-Step

Every agent reads memory before starting work. This prevents re-discovering known solutions.

```markdown
## Pre-Step — Memory Check (MANDATORY BEFORE ANYTHING ELSE)

1. Search claude-mem for: "[relevant topic] decision", "[package name] issue"
2. Read `docs/memory/error_learnings.md` — grep for the module/feature name
3. Read `docs/memory/component_registry.md` — grep for existing components before creating
4. Read `docs/memory/api_registry.md` — grep for existing endpoints before adding
```

### Section 3: Classification Gate

State explicitly what inputs this agent accepts, what it redirects, and what it refuses to handle.

```markdown
## Classification Gate

Before proceeding, classify the input:

| Input type | Classification | Action |
|------------|---------------|--------|
| [Expected input type A] | VALID | Proceed to Core Workflow |
| [Expected input type B] | VALID | Proceed to Core Workflow |
| [Out-of-scope input] | OUT OF SCOPE | Output: "⛔ NOT [MY JOB] — redirect to [correct agent]" |
| [Ambiguous input] | NEEDS CLARIFICATION | Output: "Which of these scenarios describes the issue?" |
```

### Sections 4–6

Section 4 (Core Workflow) contains the numbered gates — detailed in Section 8.5.
Section 5 (Output Format) is an exact template with labeled fields — detailed in Section 8.4.
Section 6 (Exclusions) is a DO NOT list — at least two explicit exclusions per agent.

---

## 8.3 — Designing the Agent Before Writing

Before writing a single line of the agent file, answer these questions. If you can't answer all of them clearly, the agent is not ready to be written.

### The Pre-Design Questions

1. **What is the ONE thing this agent is responsible for?**
   If the answer contains "and" — split it into two agents.

2. **What inputs will it receive, and who passes them?**
   Main Claude? The output of another agent? A direct user trigger? Each source has different quality and format.

3. **What decisions does the agent make, and what evidence does each decision require?**
   A decision that can be made from source code alone is different from a decision that requires runtime logs. Know the difference before writing the gates.

4. **What are the failure modes?**
   Incomplete input. Ambiguous input. Insufficient evidence. What does the agent do in each case? "Continue and guess" is never the correct answer.

5. **What must this agent explicitly refuse to do?**
   Every agent has adjacent tasks it could do but shouldn't. Refusing scope creep is a design requirement, not a preference.

6. **What is the exact output format?**
   Every field, every label, every ordering. If the output format is vague, Main Claude cannot reliably parse the agent's output to feed the next step.

### The Case Scenario Table Method

Before writing the agent's classification gate, build a complete case scenario table. This table becomes the gate.

List every possible input the agent could receive. Classify each one. Define the correct behavior.

**Example for a hypothetical data-validator agent:**

| Input type | Example | Classification | Agent behavior | Output |
|------------|---------|---------------|----------------|--------|
| Valid data with complete fields | `{ "id": 1, "name": "Test" }` | VALID | Run validation workflow | Validation report |
| Data missing required field | `{ "id": 1 }` | INCOMPLETE | Ask for missing field | "Missing required field: name" |
| Data with wrong type | `{ "id": "abc" }` | TYPE ERROR | Flag the violation | Type error report at field:line |
| Feature request instead of data | "Can you add a new field?" | OUT OF SCOPE | Redirect | "⛔ NOT A VALIDATION REQUEST — redirect to developer" |
| Data from wrong source/format | XML payload | UNSUPPORTED FORMAT | Refuse | "This agent accepts JSON only" |

**The rule:** Every cell in the "Agent behavior" column must be explicit. "Handle it" is not an agent behavior. "Ask for [specific missing information] and STOP" is.

---

## 8.4 — Writing Instructions That Agents Actually Follow

The most common agent design failure is not in the logic — it's in the formatting. An agent that sees a wall of instructional prose treats it as advisory guidance. To make rules non-negotiable, they need visual structure and emphasis.

### The Formatting Principle

**Agents follow structure. They skim prose.**

This is not a limitation — it is how LLMs process long instruction sets under context pressure. When an agent is at step 3 of a 6-step workflow, it is not re-reading all prior text. It is scanning for the structure that marks the next mandatory checkpoint.

### Structure Rules

**Rules that must always apply:** Bold heading + numbered list. Not a paragraph.

```markdown
## MANDATORY: Run These Checks Before Proceeding

1. Check if the endpoint exists in `docs/memory/api_registry.md`
2. Verify the component does not already exist in `docs/memory/component_registry.md`
3. Confirm the feature does not conflict with in-progress work in `_pipeline_status.md`
```

**Gates that cannot be skipped:** Prefix with `🚨` or `⛔ MANDATORY GATE — NO EXCEPTIONS`.

```markdown
## 🚨 MANDATORY GATE — EVIDENCE REQUIRED

Do NOT proceed to the fix step until Evidence Status is CONFIRMED.
CONFIRMED means: runtime log proof or direct code evidence line with grep output.
Assumption language (likely, maybe, appears, probably) = NOT CONFIRMED.
```

**Steps that must happen in order:** Number them. Explicitly state "No [action] until Step X."

```markdown
## Core Workflow

STEP 1 — [First action]
STEP 2 — [Second action] — No file reading until STEP 1 complete.
STEP 3 — [Third action] — No output until evidence status is CONFIRMED.
```

**Prohibitions:** Write as `DO NOT:` followed by a bulleted list. Never hide prohibitions in prose.

```markdown
DO NOT:
- Write a fix until evidence is CONFIRMED
- Form hypotheses before seeing runtime output
- Forward analysis to the receiving agent — only confirmed facts
```

### The "Why" Principle

Always explain why a rule exists. Agents follow rules more reliably when the reason is stated.

```markdown
# BAD — rule without reason
Never read source files before seeing the API response.

# GOOD — rule with reason
Never read source files before seeing the API response. Source file reading before runtime
evidence produces hypothesis-based root causes. A hypothesis confirmed from source code
has ~30% accuracy. Runtime evidence has ~90% accuracy. The time saved by guessing is
lost ten times over when the guess is wrong.
```

The "why" also allows the agent to apply the rule intelligently to edge cases you didn't anticipate.

---

## 8.5 — Gate Design

A gate is a checkpoint between workflow steps that can only be passed when specific evidence or conditions are met. Gates are the mechanism that makes agents reliable — not just fast.

### The Anti-Pattern: No Gate

Without a gate, this happens:

```
Step 1 — Agent does high-quality investigation → produces reliable finding A
Step 2 — Agent does lower-quality analysis → produces conclusion B that contradicts A
Final output — Agent uses conclusion B (it was last) → Step 1 was wasted
```

The Step 2 output overwrote the Step 1 output because there was no gate requiring Step 2 to be consistent with Step 1's evidence.

### What a Gate Enforces

A gate enforces that Step N can only proceed when Step N-1 produced output that meets a specific standard. The standard is measurable — not "agent thinks it's ready" but "grep output is empty" or "evidence status is CONFIRMED."

### Gate Structure

Use the Agent Gate Format from the format template:

```markdown
### Gate: [Gate Name]

| Property | Detail |
|----------|--------|
| **Trigger** | What causes this gate to activate |
| **Precondition** | What must be true before this gate can run |
| **Runs at** | Step number in the agent's sequence |
| **Exit — Pass** | Conditions met → continue to Step X |
| **Exit — Fail** | Conditions NOT met → stop / ask human / redirect |
| **Protects against** | Which lower-quality step is prevented from overwriting a higher-quality result |

**What the agent does at this gate:**
1. [Check 1] — if result is X → [action]
2. [Check 2] — if result is Y → [action]
```

### Gate Exit Language

Use these exact phrases for gate exits. Ambiguous exit language produces ambiguous agent behavior.

| Exit type | Language to use |
|-----------|----------------|
| Hard stop waiting for input | "STOP. Output [message]. Wait for human." |
| Conditional proceed | "Proceed only if [condition]. If not met → [fallback]." |
| Evidence requirement | "Evidence Status must be CONFIRMED before proceeding." |
| Redirect out of scope | "⛔ [CATEGORY] — redirect to [correct agent]." |

### Every Gate Needs a Fallback Path

State explicitly what happens when the gate is NOT passed. "Figure it out" is not a fallback.

```markdown
**If the gate fails:**
- Output: "⏸️ NEEDS CONFIRMATION — [what is missing]"
- State the exact information needed
- STOP. Do not continue to the next step.
- Do not guess. Do not estimate.
```

### Gate Example: Evidence Gate

```markdown
### Gate: Evidence Confirmation

| Property | Detail |
|----------|--------|
| **Trigger** | Before writing any handoff brief or fix recommendation |
| **Precondition** | Root cause has been identified via investigation steps |
| **Runs at** | Step 4 (after investigation, before output) |
| **Exit — Pass** | grep output or runtime log directly confirms root cause → continue to Step 5 |
| **Exit — Fail** | Evidence is inference-only → stop, ask human for runtime confirmation |
| **Protects against** | Handoff brief containing unverified function names or invented root causes |

**What the agent does at this gate:**
1. Check: does the proposed root cause have a specific grep result or log line supporting it?
2. Check: are all function names, class names, and endpoint strings in the proposed fix confirmed to exist in the codebase?
3. If both YES → set Evidence Status: CONFIRMED → proceed
4. If either NO → output the NEEDS CONFIRMATION message → stop
```

---

## 8.6 — Critical Design Principles

These four principles apply when designing any agent. They emerged from real failures in production agent systems.

### The 3-Strikes Rule

After three failed attempts to fix the same problem, the agent must stop and discuss with the human before continuing.

An LLM that repeatedly fails at fixing a problem does not become more careful — it becomes more speculative. By the third failed fix, the agent is operating outside its competence. Either the problem is architectural (beyond the agent's scope), or the investigation methodology was flawed from the start.

Build this into every agent that applies fixes:

```markdown
## 3-Strikes Rule (MANDATORY)

Track: how many fix attempts have been made for this bug/task.

If fix_attempts >= 3:
  Output:
  "⛔ THREE-STRIKES STOP
  I have attempted [N] fixes without resolving this. Continuing without a different 
  approach will produce increasingly speculative fixes that are harder to reverse.
  
  Summary of what was tried:
  - Attempt 1: [brief description + result]
  - Attempt 2: [brief description + result]
  - Attempt 3: [brief description + result]
  
  Possible architectural issue: [hypothesis — clearly labeled as unconfirmed]
  
  Recommended next step: discuss approach with human before any further changes."
  
  STOP. Do not attempt fix #4.
```

### The Brief Integrity Rule

Every function name, class name, model name, endpoint string, and JSON key that an agent writes in a handoff brief or recommendation MUST be confirmed before writing.

A brief that contains an invented function name is worse than no brief. The agent receiving it will build code against something that does not exist. When the build fails, there are now two problems: the original unfixed bug AND new broken code.

**Verification checklist before writing any brief:**
- Every function name → grep in the codebase before naming it
- Every class name → grep in the codebase before naming it
- Every endpoint string → check `api_registry.md` before naming it
- Every JSON key → confirm it appears in actual runtime log output

```markdown
## Brief Integrity Rule (MANDATORY — before any handoff output)

Before writing the handoff brief, verify every claim:
1. grep each function name you plan to reference: `grep -rn "functionName" lib/ --include="*.dart"`
2. Confirm each JSON key appears in the actual log output provided (if data mismatch bug)
3. Confirm each endpoint string exists in api_registry.md or grep results

If any claim cannot be confirmed → DO NOT include it in the brief.
Write: "Unverified: [claim] — human must confirm before developer proceeds"
```

### Claim + Evidence Output Requirement

Every agent that produces output for another agent to consume must include observable evidence alongside every conclusion. Conclusions without evidence are not trustworthy to the receiving agent.

| What agents write | What they should write instead |
|-------------------|-------------------------------|
| "I believe the issue is in the controller" | "grep lib/ for controllerMethod returned 3 results at ProfileController:42 — this is the call site" |
| "The API response seems to have the correct value" | "Log line 47 shows `amount: 1500` — this matches the expected value" |
| "The fix should be to add null check" | "ProfileEntity.fromJson at line 12 reads `json['field']` with no null check — this is the specific line" |

The pattern: **claim + grep output / log line / terminal output = acceptable**. **Claim alone = not acceptable**.

Build this into the output format section of every agent:

```markdown
## Output Format

Every finding must be in this format:
FINDING: [conclusion]
EVIDENCE: [exact grep output, log line, or file:line reference]
CONFIDENCE: CONFIRMED / UNCONFIRMED

No finding may appear without its corresponding EVIDENCE line.
```

### Model Selection Per Agent

Choose the model when creating the agent frontmatter. This decision affects both quality and cost for every invocation.

| Model | Use when | Example agents | Cost multiplier |
|-------|----------|---------------|----------------|
| `haiku` | Deterministic, rule-following tasks — no judgment required. The output is mechanical, not reasoned. | doc-updater, project-map | 1x (baseline) |
| `sonnet` | Judgment-heavy work — code writing, investigation, review. Requires reasoning, pattern recognition, code generation. | developer, code-reviewer, systematic-debugger, fr-analyst, security-reviewer | ~3x |
| `opus` | Architectural decisions — quality of reasoning multiplies all subsequent work. Used sparingly. | planner | ~15x |

**The principle:** Model complexity must match task complexity. Using Opus for updating a registry wastes 15x cost with zero quality gain. Using Haiku for architectural planning produces wrong decisions that cost more to fix than the model savings.

Deterministic tasks (the output could be produced by a rule engine): `haiku`
Judgment-heavy tasks (the output requires real reasoning): `sonnet`
Architecture tasks (the output determines the quality of everything built after it): `opus`

### Protected Files

When designing an agent, explicitly state which files it owns and which it must never touch.

Each file in the docs system has an authoritative owner agent. When a second agent "helpfully" updates a file it doesn't own, it overwrites the authoritative output with its own interpretation — which may be incorrect.

**Example ownership table:**

| File | Owner agent | Never touched by |
|------|-------------|-----------------|
| `docs/memory/error_learnings.md` | developer, systematic-debugger | doc-updater |
| `docs/memory/component_registry.md` | doc-updater | developer, code-reviewer |
| `docs/maps/project_map.md` | project-map | doc-updater, developer |
| `docs/backend_issues/backend_issues.md` | systematic-debugger | developer, code-reviewer |

Add a Protected Files section to every agent that writes to the docs system:

```markdown
## Protected Files — NEVER MODIFY

The following files are owned by other agents. Do not write to them under any circumstances.
doc-updater owns: component_registry.md, api_registry.md
project-map owns: docs/maps/project_map.md
developer and systematic-debugger own: error_learnings.md
```

---

## 8.7 — Validating a New Agent

After writing the agent file, validate it before registering it in the orchestra. An unvalidated agent in the orchestra will fire for real tasks and produce wrong output from day one.

### The Validation Process

1. Give Main Claude the validation prompt below (fill in `[agent-name]`)
2. Main Claude reads the agent file and generates a test criteria checklist
3. Run 3–5 test scenarios using the checklist
4. Record pass/fail per criterion per scenario
5. If any scenario fails → fix the agent → re-run that scenario before marking done

### Validation Prompt Template

Copy this prompt, fill in `[agent-name]`, and send it to Main Claude:

```
I have created a new agent. Please validate it before I register it in the orchestra.

Agent file: .claude/agents/[agent-name].md

Step 1: Read the agent file completely.

Step 2: Generate a test criteria checklist. For each gate in the agent, create a test criterion:
  - What input triggers this gate?
  - What is the expected behavior when the gate fires?
  - What is the expected behavior when the gate does NOT fire?
  - What does the agent output in each case?

Step 3: List 5 test scenarios from simple to complex that exercise every gate.

Step 4: For each scenario, state what the agent should do at each gate.

Step 5: Answer: Why was this agent created? What problem does it solve that Main Claude 
cannot solve alone?

After generating the criteria and scenario list, run Scenario 1 using the exact trigger input.
Report: [scenario] → [what the agent did at each gate] → [pass/fail per criterion]
```

### What to Check in the Validation Output

Run through this checklist after each test scenario:

- [ ] Agent fires the correct gate for each trigger type
- [ ] Agent does NOT bypass gates when Main Claude's prompt pre-loads investigation steps
- [ ] Agent stops and waits for input when evidence is insufficient — it does NOT fabricate
- [ ] Agent's output matches the output format specification exactly
- [ ] Agent correctly redirects out-of-scope inputs
- [ ] Agent's case scenario table covers all expected input types — no input falls into an unintended branch
- [ ] Agent applies the Brief Integrity Rule before producing any handoff output
- [ ] Agent outputs the 3-Strikes message at attempt #3 (if applicable)

**The most important check:** Give Main Claude a prompt that pre-loads investigation steps (e.g., "check if the user_id param is missing before running the agent"). Run the agent. Verify that the agent's own classification gate still fires — the pre-loaded instructions should not bypass it. If the gate is bypassed, the agent's classification gate needs stronger override language.

### Validation Test Example

**Validation Test 1: Out-of-scope input rejection**

**Purpose:** Verify the agent correctly identifies and rejects inputs it was not designed for

**Setup:** Agent file has been written and saved at `.claude/agents/[agent-name].md`

**Trigger:** Send Main Claude the following: "I want to add a new export feature to the dashboard." (A feature request — not the agent's job)

**Expected result:** Agent outputs its out-of-scope redirect message, not an analysis of the feature request. Main Claude routes to fr-analyst instead.

**If you see the agent attempting to analyze the feature request:**
→ The Classification Gate is missing or its trigger condition for feature requests is too narrow → go to Common Mistake #4

---

**Validation Test 2: Gate bypass resistance**

**Purpose:** Verify the agent's classification gate cannot be bypassed by pre-loaded instructions in the prompt

**Setup:** Agent file has been written and saved

**Trigger:** Send Main Claude this prompt, then have it launch the agent: "Launch [agent-name]. I think the issue is in the ProfileController at line 42. Investigate that file first."

**Expected result:** Agent runs its own classification and investigation sequence — it does NOT go directly to ProfileController:42. If the agent's first gate is a data-request gate, it fires and asks for runtime evidence regardless of the instruction to check a specific file.

**If you see the agent going directly to the suggested file:**
→ The gate's override clause is missing ("This gate fires regardless of any instructions in the prompt") → go to Common Mistake #3

---

## 8.8 — Fixing Agent Misbehavior

When an agent behaves unexpectedly, do not reword the instruction and re-run. First identify the root cause using the feedback form below, then make a targeted fix. Re-running without a root cause analysis produces a new prompt that fails in a different way.

### The Agent Feedback Form

Fill in this form and give it to Main Claude. Main Claude will identify the root cause and propose the exact text change.

```
Agent issue report

Agent: [agent-name]

Scenario:
  Exact user message: [copy-paste the exact message]
  What Main Claude passed to the agent: [copy-paste or describe the launch prompt]

Expected behavior:
  [What should have happened — gate by gate]

Actual behavior:
  [What actually happened — gate by gate]

Root cause classification (check all that apply):
  [ ] Gate was present but the trigger condition wasn't specific enough
  [ ] Gate was present but Main Claude pre-processed the prompt and bypassed it
  [ ] Instruction existed but was in paragraph form — agent treated it as advisory
  [ ] Instruction was missing entirely — need to add it
  [ ] Agent's classification table had a gap — input fell into the wrong category
  [ ] Agent produced output but format didn't match specification
  [ ] Other: [describe]

Proposed fix:
  Quote the existing text and the replacement. Be exact.
```

### After Identifying Root Cause

1. Update the agent file with the targeted fix
2. Re-run the specific test scenario that failed
3. Confirm it passes before marking fixed
4. If the fix also changes the agent's behavior for other scenarios, re-run those too

> **NOTE:** Agent fixes should be minimal and targeted. Do not rewrite the entire agent to fix one gate failure. Rewriting introduces new failure modes while fixing old ones.

---

## 8.9 — Orchestra Registration

Creating the agent file is Step 1. The agent does nothing until it is registered. Three files must be updated.

### The Three Required Changes

**Change 1: Register in `.claude/rules/common/agents.md`**

Add the agent to the trigger routing table under the appropriate category (Bug Triggers, Development Triggers, Quality Loop, etc.):

```markdown
| "validate [data]" | `data-validator` | **foreground** | When validation is explicitly requested |
```

Include: trigger pattern, agent name, launch mode, and the condition that gates the trigger.

**Change 2: If it has a new trigger pattern → update CLAUDE.md**

If the agent responds to a new trigger word or prefix (e.g., `"validate::"`) that Main Claude doesn't already know about, add it to CLAUDE.md's development workflow trigger section:

```markdown
| `validate:: [description]` | `data-validator` | foreground | Always — never skip |
```

**Change 3: If it is a mandatory post-implementation step → update the Quality Loop in agents.md**

If the agent runs as part of the post-implementation review (after a developer marks code REVIEW), add it to the Quality Loop sequence in the correct phase:

```markdown
Phase 2.5: data-validator (foreground) — ONLY if new data models were added
```

### The "Two of Three = Broken" Rule

| Files updated | Result |
|--------------|--------|
| Agent file only | Agent never fires — Main Claude doesn't know it exists |
| agents.md only (no agent file) | Main Claude tries to launch a non-existent agent |
| Agent file + agents.md (no CLAUDE.md update for new trigger) | Agent fires inconsistently — only when agents.md is re-read |
| All three | Agent fires correctly and consistently |

Always update all three. Check them as a group after every new agent creation.

---

## 8.10 — Raw Prompt vs. Processed Prompt

This is one of the most commonly misunderstood decisions in agent design. Getting it wrong silently degrades the quality of every agent invocation.

### The Core Decision Rule

| Agent's first step | Pass | Why |
|-------------------|------|-----|
| A **classification gate** that fires on unprocessed input | **Raw** | The gate reads the input directly. Pre-processing changes what the gate sees. |
| **Execution** (agent already knows what to do) | **Processed** | Agent needs enriched context — the output of a previous step — not the original trigger. |

**Raw:** Pass the user's message with minimal addition. Do not add investigation steps, file suggestions, or hypotheses.

**Processed:** Pass a structured summary — the confirmed output of a previous agent, with specific fields the receiving agent needs.

### The Bypass Problem

Main Claude is naturally helpful. When it sees a bug report, it wants to add context: "I think the issue might be in ProfileController, check line 42." When it adds this to the launch prompt for a debugging agent, two things happen:

1. The debugging agent reads the suggestion as an instruction
2. The debugging agent's own classification gate — which was designed to fire on unprocessed bug descriptions — never gets a chance to fire because the agent is already following Main Claude's investigation path

The result: the debugging agent produces a static-analysis guess dressed as a confirmed root cause. It sounds confident. It is unverified. The developer builds against it. Two problems now exist instead of one.

### The Correct Format for Raw Prompts

```
Bug description: [exact user message — no paraphrasing]
Screen/module: [inferred from description]
Project root: [path]
```

Nothing else. No "I think", no "check if", no "the issue is probably". The agent's own logic determines what to investigate.

### The Correct Format for Processed Prompts

After an investigation agent (like a debugger) produces a confirmed brief, the brief is the processed prompt for the next agent (developer):

```
Root cause (CONFIRMED): [exact statement from the brief]
Evidence: [grep output or log line from the brief]
Fix location: [file:line]
Fix description: [what to change]
Scope: minimal fix only — do not refactor surrounding code
```

The developer agent receives this brief and does not re-investigate. It verifies the brief against the codebase (Brief Integrity Rule) and applies the fix.

### Worked Example

```
User: "The message count badge shows 0 even when there are unread messages"

Main Claude (WRONG — adds hypothesis):
  Launch prompt: "Bug: message count shows 0. Investigate the ConversationController 
  at badgeCount getter — it may not be updating the observable correctly."

  → Agent follows Main Claude's suggestion
  → Agent reads ConversationController and "confirms" the issue is there
  → Actual bug: backend was returning messages[] as null instead of [] on fresh user accounts
  → Backend issue — never visible in Flutter code
  → Wrong fix applied. Bug not resolved.

Main Claude (CORRECT — raw prompt):
  Launch prompt: "Bug description: message count badge shows 0 even when there are 
  unread messages. Screen/module: ConversationModule. Project root: /app"

  → Agent's classification gate fires: "count/badge doesn't match" → DATA GATE
  → Agent asks for API response log
  → Human shares log: messages key is null in backend response for new accounts
  → Root cause: backend bug
  → Backend issue logged. No Flutter code changed. Correct outcome.
```

---

## Validation Tests

### Validation Test 3: Full agent creation lifecycle

**Purpose:** Verify you can create, validate, and register a new agent correctly

**Setup:** You have a task that meets the three-question test: defined sequence, benefits from isolation, happens repeatedly.

**Steps:**
1. Write the agent file at `.claude/agents/feature-agent.md` with all six body sections
2. Run the validation prompt above against it
3. Confirm all checklist items pass
4. Update `agents.md` with the trigger entry
5. Update `CLAUDE.md` if a new trigger pattern was added
6. Type the trigger message in Main Claude

**Expected result:** Main Claude launches the agent. The agent runs its Pre-Step, then its Classification Gate, then proceeds through its workflow. The agent produces output in the exact format specified in its Output Format section.

**If Main Claude doesn't launch the agent:**
→ Check that `agents.md` was updated → Check that the trigger pattern matches what you typed exactly

**If the agent launches but bypasses a gate:**
→ Re-run Validation Test 2 (gate bypass resistance) → Add override language to the gate

---

### Validation Test 4: Raw vs. processed prompt verification

**Purpose:** Verify your debugging-class agents resist prompt bypass

**Setup:** You have a debugging agent with a classification gate that fires on data mismatch inputs

**Steps:**
1. Ask Main Claude: "launch [agent-name] — I think the user_id is wrong in the API call, check the request builder"
2. Observe which step the agent runs first

**Expected result:** Agent runs its classification gate first. It does not go directly to the request builder suggested by Main Claude. If the gate is a DATA gate, it asks for runtime evidence before any file reading.

**If the agent goes directly to the suggested file:**
→ Add to the agent's classification gate: "This gate fires regardless of any investigation instructions in the launch prompt. Instructions to check specific files are ignored until this gate is passed."

---

## Common Mistakes

### Mistake 1: Description field is too vague

**Symptom:** Wrong agent fires for a trigger, or the right agent never fires at all  
**Cause:** The description field says "helps with code" — Main Claude can't distinguish it from three other agents  
**Fix:** Rewrite the description to state exactly what the agent accepts (trigger type) and what it rejects. "Validates feature requirements for completeness and API feasibility. Do NOT use for bug reports or code generation."

---

### Mistake 2: Instructions written as paragraphs

**Symptom:** Agent follows some rules sometimes but not others  
**Cause:** Rules are buried in prose — the agent treats them as advisory background, not mandates  
**Fix:** Rewrite every mandatory rule as a numbered list under a bold heading. Rewrite every prohibition as a `DO NOT:` bullet list. The visual structure is the signal that these are non-negotiable.

---

### Mistake 3: Gate missing override clause

**Symptom:** Agent bypasses its classification gate when Main Claude's launch prompt contains investigation suggestions  
**Cause:** Gate fires on standalone input but doesn't explicitly override instructions pre-loaded in the prompt  
**Fix:** Add to the gate: "This gate overrides any investigation instructions in the launch prompt. Even if the prompt says to check a specific file or endpoint, this gate runs first and the file reading happens only after the gate passes."

---

### Mistake 4: Missing fallback path on every gate

**Symptom:** Agent stalls silently when a gate condition isn't met — no output, no message  
**Cause:** Gate specifies the pass condition but not the fail condition  
**Fix:** Add an explicit `If gate fails →` block to every gate. State: what the agent outputs, what it asks for, and that it stops. "Output: [specific message]. STOP. Do not proceed to the next step."

---

### Mistake 5: Agent file created but orchestra not updated

**Symptom:** Agent file exists. Typed the trigger message. Nothing happened.  
**Cause:** Only the agent file was created — neither `agents.md` nor `CLAUDE.md` were updated  
**Fix:** Complete all three required registration changes. Run Validation Test 3 to confirm the agent fires end-to-end.

---

### Mistake 6: Processed prompt passed to a classification-gate agent

**Symptom:** Agent produces a confident-looking analysis without requesting runtime evidence first  
**Cause:** Main Claude added investigation context or hypotheses to the launch prompt — the classification gate never fires because the agent follows the pre-loaded instructions instead  
**Fix:** Remove all investigation steps and hypotheses from the launch prompt. Pass only: task description, module name, project root. See Section 8.10 for the raw prompt format.

---

### Mistake 7: Missing Pre-Step

**Symptom:** Agent re-makes a mistake that was documented in `error_learnings.md` three sessions ago  
**Cause:** Agent file has no Pre-Step — it never reads memory files before starting work  
**Fix:** Add a Pre-Step as the first section after the Identity/Role section. Minimum: search claude-mem for the module name, read `error_learnings.md`, grep `component_registry.md` and `api_registry.md`.

---

### Mistake 8: No explicit exclusions

**Symptom:** Agent "helpfully" does adjacent work — writes to a file it doesn't own, adds features not requested, modifies code when it was only supposed to review  
**Cause:** Agent has no exclusions section — adjacent tasks are not prohibited  
**Fix:** Add an explicit "This agent does NOT:" section with at least two items. The developer agent does not investigate bugs. The code-reviewer does not write fixes. The doc-updater does not write to `error_learnings.md`. Be specific.

---

## Reference

| Item | Value |
|------|-------|
| Agent file location | `.claude/agents/[agent-name].md` |
| Orchestra file | `.claude/rules/common/agents.md` |
| Trigger registration | `CLAUDE.md` — development workflow trigger table |
| Validation prompt | Section 8.7 above — copy-paste template |
| Feedback form | Section 8.8 above — copy-paste template |
| Model: deterministic tasks | `haiku` (doc-updater, project-map) |
| Model: judgment tasks | `sonnet` (developer, code-reviewer, debugger) |
| Model: architecture decisions | `opus` (planner) |

---

*Next: [Chapter 9: Orchestra Management (agents.md)]*
