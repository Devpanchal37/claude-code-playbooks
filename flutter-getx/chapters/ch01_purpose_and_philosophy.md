# Chapter 1: Purpose & Philosophy

> **Applies to:** Flutter-GetX
> **Prerequisites:** None
> **Estimated read + setup time:** ~20 minutes (reading only — no hands-on setup in this chapter)

---

## TL;DR

By default, Claude Code is a fast, capable, but stateless tool — every session starts from zero, every developer prompts differently, and Claude makes decisions that contradict yesterday's decisions. This playbook turns Claude Code into a disciplined engineering process: a system with defined roles, cross-session memory, automatic gates, and an orchestra of specialized agents each with a single responsibility. The investment is 1-3 sessions of upfront configuration. The return is a workflow that gets *more reliable* as the project grows, not less.

---

## What This Is

This playbook describes how to turn Claude Code from a smart, fast, stateless assistant into a disciplined, stateful engineering process. The result is called an **agentic development setup**.

The distinction matters:

| | AI-Assisted Coding | Agentic Development |
|-|-------------------|---------------------|
| **What it is** | You use an AI tool to help with tasks | An AI system runs alongside your workflow with defined roles and process |
| **Who defines the process** | You, in each prompt | The CLAUDE.md, agents, and orchestra you configured once |
| **Memory** | None — every session starts from zero | Persistent — agents read past decisions and mistakes |
| **Consistency** | Depends on how you prompt that day | Enforced by gates and rules agents cannot skip |
| **Review** | You ask Claude to review | Automated quality loop fires after every implementation |
| **Bug investigation** | "I think the issue might be..." | Data gate fires — no hypothesis without runtime evidence |
| **Your role** | Developer who uses an AI tool | Orchestrator who defines the process; agents execute it |

The key difference is not capability. Claude Code is equally capable in both modes. The difference is **reliability**. AI-assisted coding produces different quality outputs depending on who is prompting and how. Agentic development produces consistent outputs because the process is defined, not improvised each session.

### How It Compares to Just Using Claude

| | Just Claude | This Setup |
|-|------------|------------|
| Session memory | None | Agents read `error_learnings.md` and `claude-mem` MCP |
| Who writes code | Main Claude, directly | `developer` agent — the only agent that writes code |
| Bug investigation | Claude guesses from file reading | `systematic-debugger` waits for runtime evidence before any hypothesis |
| Code review | You ask and hope | `code-reviewer` fires automatically, scoped to changed files only |
| Documentation | You update it manually, or it rots | `doc-updater` runs in background after every feature |
| Cross-session decisions | Contradicts previous sessions | `claude-mem` MCP stores and retrieves past decisions semantically |

---

## Why It Exists (The Problem It Solves)

### The Core Problem

> **CRITICAL:** LLMs are confident and fast. Confidence without verification produces wrong outputs at high velocity.
> If violated: You get plausible-sounding, well-structured code that is wrong in subtle ways — and no warning that it is wrong.

This is the root problem this setup exists to solve. Without structure, Claude Code will:

- Read your source files and form a hypothesis about a bug — then confidently write a fix — before ever seeing the actual API response that would have revealed the real cause
- Write a new widget that already exists in the codebase, because it did not know to check the component registry
- Contradict an architectural decision from two sessions ago, because it has no memory of that session
- Produce "technically correct but business wrong" code, because no one told it to hold the product-owner perspective simultaneously with the developer perspective

None of this is a defect in Claude. It is the default behavior of a capable LLM with no structure around it. The problem is not capability — it is the absence of a system that forces verification before every consequential step.

### Before This Setup

Without a structured setup, four failure classes appear in every project that runs long enough:

**1 — Standards drift**
Session 4: developer asks for ProfileScreen. Claude writes hardcoded color values instead of theme constants, no empty state, no error state. It ships. Session 12: code review finds 15 violations across three screens. Rewrite required.

**2 — Session amnesia**
Session 1: team decides `UserEntity.email` is nullable to support guest accounts. Session 8: a different developer asks for SettingsScreen. Claude makes `email` non-nullable — it looked safer. Build fails. The decision from session 1 has to be re-argued from scratch.

**3 — Duplicate work**
Session 3: developer builds `AvatarWidget` for ProfileModule. Session 9: a different developer asks for UserCard. Claude creates `UserImage` widget — same component, different name, different behavior. Both stay in the codebase.

**4 — Wrong-direction investigation**
Developer: "The item count shows 0 instead of 5." Claude reads source files, forms a hypothesis, suggests a fix. Fix applied. Bug persists. The actual cause was a wrong value in the API response — not visible in any source file.

### After This Setup

With the agentic setup, each failure class has a specific prevention mechanism:

**1 — Standards drift → prevented by compliance greps**
The developer agent runs automated checks after every file it writes. A hardcoded color constant means stopping and fixing before the next file. "I followed the rules" is not accepted as proof. Empty grep output is.

**2 — Session amnesia → prevented by error_learnings + claude-mem**
Every non-obvious decision is stored when it is made. Agents read this memory before starting any new work. The nullable-email decision from session 1 is retrieved in session 8. The debate does not repeat.

**3 — Duplicate work → prevented by registry checks**
Before creating any widget, the developer agent searches the component registry. `AvatarWidget` is found. The existing component is used, not duplicated.

**4 — Wrong-direction investigation → prevented by the evidence gate**
The systematic-debugger stops all file reading when a value mismatch is detected. It asks for the console log — the runtime evidence — before forming any hypothesis. Source files are not read first.

The difference is not Claude's intelligence. It is the system around Claude.

### The Speed Bump Philosophy

Every rule in this setup is a **speed bump** — a forced verification checkpoint before the next step. Speed bumps do not make Claude less capable. They make it more reliable.

| Speed Bump | What It Verifies | Without It, You Get |
|------------|-----------------|---------------------|
| **DATA GATE** | Runtime evidence before hypothesizing | Wrong fixes based on code-reading guesses |
| **Confirmation Gate** | Human intent before implementing | Code written for the wrong interpretation |
| **Instruction Loading** | Project conventions before writing code | Hardcoded values, wrong fonts, missing locale keys |
| **Compliance Greps** | Standards before marking done | Violations shipped to production |
| **Self-Validation** | Spec compliance before marking REVIEW | Scope creep — features the product owner never requested |
| **Brief Integrity Rule** | Function existence before documenting fixes | Invented function names that create new compile errors |
| **Dependency Check** | Impact before modifying existing code | Breaking 5 screens when changing 1 shared entity |
| **Error Learnings Check** | Past mistakes before starting new work | Repeating known mistakes every single session |
| **Pre-Review Workflow Check** | Developer completeness before code-reviewer runs | Reviewers catching obvious issues the developer should have caught |

**The key insight:** Slightly slower per task. Dramatically fewer wrong outputs, rework cycles, and introduced bugs. The trade-off compounds: in a project without speed bumps, every week adds more debt. In a project with them, the setup becomes more valuable as the codebase grows and institutional knowledge accumulates.

---

## How It Works

### The Mental Model Shift

This is the most important thing to internalize before setting up anything technical.

**You are no longer a developer who uses AI. You are an orchestrator who defines the process, and the agents execute it.**

This shift requires discipline before it pays off. The temptation is to keep prompting Claude directly — it is faster in the moment. But direct prompting is like hiring a skilled contractor and giving them different instructions every day. The work gets done, but nothing learned on Monday transfers to Friday.

The orchestrator role means:

- You define the trigger patterns ("when user says `bug::`, launch systematic-debugger")
- You define the agent instructions ("systematic-debugger never hypothesizes without runtime evidence")
- You define the gate conditions ("code-reviewer only runs after developer marks REVIEW")
- You validate the output — but you do not generate it

Once configured, most sessions look like:

```
You: one sentence, correct trigger pattern
     ↓
Main Claude: classifies message, routes to correct agent
     ↓
Agent: reads memory, applies its gates, produces verified output
     ↓
You: review the output, approve and commit
```

### The Role Hierarchy

```
┌──────────────────────────────────────────────────────────┐
│                  Human (Product Owner)                    │
│  Describes requirements → validates output → approves     │
└───────────────────────────┬──────────────────────────────┘
                            │ sends messages
┌───────────────────────────▼──────────────────────────────┐
│              Main Claude (Conductor)                       │
│  Reads CLAUDE.md → classifies message → routes to         │
│  correct agent → coordinates quality loop                 │
│  NEVER writes code directly                               │
└────┬──────────┬────────────┬──────────────┬──────────────┘
     │          │            │              │
┌────▼──┐  ┌───▼──────┐ ┌───▼────┐  ┌─────▼──────┐
│  FR   │  │Systematic│ │Planner │  │ Developer  │
│Analyst│  │Debugger  │ │        │  │(only agent │
│       │  │          │ │        │  │ writing    │
│       │  │          │ │        │  │ code)      │
└───────┘  └──────────┘ └────────┘  └────────────┘
     │          │            │              │
┌────▼──────────▼────────────▼──────────────▼────────────┐
│                     Memory System                        │
│   error_learnings · component_registry · api_registry    │
│   pipeline_status · claude-mem MCP · project_map         │
└──────────────────────────────────────────────────────────┘
```

**The roles are strict:**

- Main Claude is the conductor — it routes, coordinates, and presents. It does NOT write code.
- Agents are specialists — each has one job, defined gates, and explicit exclusions for everything outside that job.
- The human is the product owner and final validator — they describe what to build and approve what was built.

### Why Agents With Gates Are More Reliable Than Main Claude Acting Freely

When Main Claude handles everything directly, it can silently skip steps. There is no mechanism that prevents it from writing code before reading `error_learnings.md`, or suggesting a bug fix before seeing the API response.

Agents have a different property: their gate sequences are written into their identity. A gate is a checkpoint the agent cannot proceed past until specific conditions are met. When the systematic-debugger's DATA GATE fires, the agent stops — it does not continue to file reading regardless of what the prompt says. When the developer agent's instruction loading gate fires, no code is written until every required file has been read.

This is why the setup is more reliable: the gates are enforced at the agent level, not at the prompt level. Main Claude cannot instruct an agent to skip its own gates without the agent explicitly being designed to accept that instruction.

### What the Setup Consists Of

Seven components. Each is required. Removing any one breaks the system in a specific, diagnosable way:

| Component | What It Is | What Breaks Without It |
|-----------|-----------|------------------------|
| **CLAUDE.md** | Identity and rules file Main Claude reads every session | Main Claude makes wrong routing decisions; agents fire randomly |
| **settings.json** | Permissions, allowed tools, hook registration | Agents interrupted mid-flow requesting permission for routine operations |
| **.claude/rules/** | Layered coding standards all agents follow | Each agent invents its own style; standards drift across sessions |
| **.claude/agents/** | Specialized Claude instances with their own gates | Main Claude handles everything; context degrades; no gates |
| **agents.md (orchestra)** | Routing logic — which agent fires when | Agents exist as files but never fire; Main Claude improvises routing |
| **MCP plugins** | External tools (Claude Mem, code-review-graph) | No cross-session memory; no code intelligence for impact analysis |
| **docs/ folder** | Structured documentation maintained by agents | Agents have no persistent knowledge of the codebase state |

### Traditional Claude vs. Agentic Setup — Side by Side

```
TRADITIONAL (no setup)               │  AGENTIC (this setup)
                                     │
Developer types a request            │  Developer types: "develop UserModule"
         ↓                           │            ↓
Claude responds immediately          │  Main Claude reads CLAUDE.md
  · no memory of past sessions       │            ↓
  · no routing logic                 │  Classifies message type
  · no gate sequence                 │            ↓
  · no standards enforcement         │  Checks memory: past mistakes,
         ↓                           │  existing components, in-progress work
Output quality depends on:           │            ↓
  · how well the prompt was written  │  Routes to the correct agent
  · what Claude recalled this time   │            ↓
  · whether Claude skipped checks    │  Agent loads architecture rules,
         ↓                           │  component registry, error learnings
Next session: no memory              │            ↓
  · context re-explained again       │  Agent applies gate sequence:
  · mistakes repeated                │  conventions loaded → code written →
  · standards drift undetected       │  compliance checked → output validated
  · no documentation updated         │            ↓
                                     │  Quality loop fires automatically
                                     │            ↓
                                     │  Output delivered — memory updated
                                     │  Next session: agents already know
                                     │  what was decided and what went wrong
```

---

## Setup

This chapter has no hands-on technical steps — those begin in [Chapter 3: Quick Start Checklist]. What you need before starting is not a technical prerequisite. It is a decision.

### Prerequisites Check

- [ ] You understand that this setup requires 1-3 sessions of upfront configuration before it pays off
- [ ] You are building a project that will run long enough to benefit from cross-session memory (more than a few days of active development)
- [ ] You are willing to write CLAUDE.md, agent files, and the orchestra before writing any feature code

If all three are checked: proceed to [Chapter 2: How the Setup Works].

> **WARNING:** This setup is not appropriate for throwaway prototypes or one-day projects. The upfront investment is only justified when the project will accumulate sessions, developers, and codebase growth over weeks or months.
> Instead: for short-lived projects, use Claude Code with basic CLAUDE.md and manual prompting — skip the full agent setup.

### What You're Investing

Time investment: approximately 2-4 hours across 1-3 sessions before the first agent fires reliably.

Breakdown:

1. Write CLAUDE.md — 45-60 minutes (see [Chapter 4: CLAUDE.md File])
2. Configure settings.json and basic permissions — 20 minutes (see [Chapter 5: settings.json])
3. Create your first agent (developer) and register it in the orchestra — 60-90 minutes (see [Chapter 8: Agent Creation Guide])
4. Validate that the agent fires correctly — 30 minutes (see [Chapter 3: Quick Start Checklist])

**What you do NOT need on Day 1:**

- All agents — start with developer and systematic-debugger only
- All rules files — start with `common/coding-style.md` and `common/git-workflow.md`
- MCP plugins — add after the basic setup is working
- A complete docs/ folder — the minimum viable set is `error_learnings.md` and `_pipeline_status.md`

Start lean. Add components as you feel the absence of something specific.

### What You Gain (Compounding Returns)

| Project Phase | What the Setup Does for You |
|--------------|------------------------------|
| **Day 1-3** | Configuration overhead — no net gain yet |
| **Week 1-2** | Agents fire consistently; first `error_learnings` entries accumulate |
| **Month 1** | `error_learnings` has 10-20 entries — agents stop repeating past mistakes |
| **Month 2+** | New developers onboard by reading the setup; agents know the full codebase state |
| **Large codebase** | `project_map` shows blast radius before any shared file change; no surprise regressions |

The setup is not an investment with a fixed return. It is an investment that returns more the longer and larger the project runs.

---

## Validation

There are no hands-on technical tests for this chapter — it is a concepts chapter. The validation is understanding.

### Validation Test 1: The Role Check

**What to do:** Without looking at your notes, answer these three questions:
1. Who routes messages to agents?
2. Who is the only role that writes code?
3. What is your role in this system?

**Expected answers:**
1. Main Claude (the conductor)
2. The `developer` agent — no other role writes production code
3. Product owner and final validator — you describe what to build and approve what was built

**If you couldn't answer:** Re-read the "Role Hierarchy" section. This is the most important mental model in the setup. Everything else in the playbook depends on having this clear.

### Validation Test 2: The Gates Test

**What to do:** A developer asks: "Why not just tell Main Claude to always read `error_learnings.md` before every task? Why do we need separate agents for that?" What is the correct answer?

**Expected answer:** Main Claude follows instructions, but it can silently skip them when context seems to call for speed — and there is no enforcement mechanism to stop it. Agents have gate sequences embedded in their identity. A gate does not pass until its conditions are met, regardless of what the incoming prompt says. Reliability comes from enforcement at the agent level, not from instructions in the prompt.

**If you couldn't answer:** Re-read the "Why Agents With Gates Are More Reliable Than Main Claude Acting Freely" section.

### Validation Test 3: The Investment Reality Check

**What to do:** Complete this sentence honestly: "I should set up this system if ___."

**Expected answer:** Something like: "I am building a project that will run for weeks or months, involve multiple sessions or developers, and where I want quality and consistency to improve over time rather than degrade."

**If your answer was** "I want faster output on day 1" — that is not what this delivers. Re-read the "What You're Investing" section. Day 1 is always slower with this setup. The gain is in the weeks that follow.

---

## Common Mistakes

### Mistake 1: Treating this as a speed tool

**Symptom:** Developer sets up the system, finds it slower than direct prompting, and abandons it after Day 1.  
**Cause:** The value of this setup is not speed on any single task. It is consistency and reliability across many sessions. Day 1 is always slower.  
**Fix:** Measure the right metric. Not "how fast did I get this response?" but "how many times did an agent repeat a known mistake this month? How many bugs required more than one fix attempt? How many sessions did I spend re-explaining project context?" Those numbers drop as the setup matures.

### Mistake 2: Skipping the orchestra registration

**Symptom:** Developer creates an agent file but the agent never fires. Developer manually triggers the agent every time.  
**Cause:** An agent file without an entry in `agents.md` is invisible to Main Claude. It exists as a Markdown file but has no trigger condition registered.  
**Fix:** Every agent creation requires three coordinated changes: the agent file in `.claude/agents/`, the entry in `agents.md`, and the trigger pattern in CLAUDE.md. All three must be in sync. See [Chapter 9: Orchestra Management].

### Mistake 3: Letting Main Claude write code directly

**Symptom:** Developer types "write me a UserModule screen" and receives code directly from Main Claude, bypassing all agents and gates.  
**Cause:** Main Claude will write code by default unless CLAUDE.md explicitly states that all code writing is delegated to the developer agent.  
**Fix:** CLAUDE.md must contain an explicit rule: "ALL code writing is done by the developer agent. NEVER write code manually in the main conversation." See [Chapter 4: CLAUDE.md File].

### Mistake 4: Setting up agents before CLAUDE.md

**Symptom:** Developer creates agents but Main Claude makes random routing decisions — sometimes using agents, sometimes not.  
**Cause:** CLAUDE.md is the rulebook Main Claude reads every session. Without it, Main Claude has no orchestration rules to follow and improvises routing.  
**Fix:** Write CLAUDE.md before creating any agents. The orchestra needs a conductor's rulebook before the musicians play. See [Chapter 4: CLAUDE.md File].

### Mistake 5: Setting up everything on Day 1

**Symptom:** Developer tries to configure all agents, all rules files, MCP plugins, and the full docs structure in one session. Nothing works correctly. Debugging which piece is broken is impossible.  
**Cause:** When everything is installed at once, a misconfiguration anywhere breaks something somewhere, with no way to isolate the cause.  
**Fix:** Layer the setup. Start with CLAUDE.md + settings.json + developer agent + orchestra entry. Validate the developer agent fires correctly. Then add the next component. See [Chapter 3: Quick Start Checklist] for the recommended sequence.

---

## [Flutter-GetX Specifics]

For developers using this playbook, one foundational design decision has already been made: this setup is pre-calibrated for **GetX + feature-first Clean Architecture**.

### What That Means in Practice

This playbook's agents enforce a specific, opinionated stack. You are not choosing architecture session by session — the setup enforces it automatically.

**GetX patterns the agents enforce:**

| Pattern | Enforcement point |
|---------|-----------------|
| Permanent controllers for `IndexedStack` tabs (`Get.put(..., permanent: true)`) | Developer agent's instruction loading gate |
| Non-permanent controllers for push-and-pop routes | Developer agent's widget placement gate |
| `RxList` mutation via `.assignAll()` — never direct `=` assignment | Compliance greps run after every file |
| `Obx` scope: reads observables in its own closure only — child widgets are not reactive | Code-reviewer GetX pattern check |
| One use case = one action (`LoginUseCase`, not `AuthUseCase`) | Planner agent's domain layer planning step |

**Feature-first folder structure the agents enforce:**

```
lib/
  src/
    features/
      FeatureName/
        domain/
          entities/
          use_cases/
        data/
          repositories/
          data_sources/
        presentation/
          screens/
          controllers/
          bindings/
          widgets/
```

The developer agent reads `ARCHITECTURE.md` before writing any file and generates this structure automatically. You do not need to specify it in each request.

### What This Gives You

You do not make architectural decisions mid-project. The playbook made them. Your job is:
1. Describe what to build (feature requirements)
2. Validate the output (the product-owner role)

Everything in between — architecture, naming, layer placement, GetX pattern selection — is enforced by the agents.

### What This Requires

If you deviate from GetX patterns in one module — for example, introducing Riverpod for state management in a single feature — the developer agent and code-reviewer will flag violations, because the rules assume GetX throughout.

If your stack evolves (team decision to migrate to Riverpod, for example), you update the setup rather than fight it. See [Chapter 20: Updating the Architecture] for the full migration checklist.

> **NOTE:** If you have not yet committed to GetX + Clean Architecture, consider the Flutter Generic playbook instead. It leaves the architecture decision to you and does not enforce any particular state management pattern.

---

## Reference

| Item | Value |
|------|-------|
| **One-sentence summary** | "This setup turns Claude Code from a smart autocomplete into a disciplined engineering process." |
| **Core philosophy** | "LLMs are confident and fast. Confidence without verification produces wrong outputs at high velocity." |
| **Your role** | Product owner and final validator — describe what to build, approve what was built |
| **Main Claude's role** | Conductor — routes, coordinates, presents. Never writes code. |
| **Agent's role** | Specialist — one job, defined gates, explicit exclusions |
| **Stack enforced** | GetX + feature-first Clean Architecture |
| **Memory lives in** | `docs/memory/`, `docs/FR/_pipeline_status.md`, claude-mem MCP, auto-memory files |
| **Upfront investment** | 2-4 hours across 1-3 sessions before first agent fires reliably |
| **Returns compound at** | Month 1 (`error_learnings` populated), Month 2+ (new devs onboard from the setup alone) |
| **Technical setup begins** | [Chapter 2: How the Setup Works] → [Chapter 3: Quick Start Checklist] |

---

*Next: [Chapter 2: How the Setup Works]*
