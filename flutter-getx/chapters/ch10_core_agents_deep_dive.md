# Chapter 10: Core Agents Deep Dive

> **Applies to:** Flutter-GetX
> **Prerequisites:** [Chapter 8: Agent Creation Guide], [Chapter 9: Orchestra Management]
> **Estimated read + setup time:** ~60 minutes (full chapter) / ~10 minutes per agent section

---

## TL;DR

Six agents cover 90% of daily development work: FR Analyst, Systematic Debugger, Planner, Developer, UI-Design Enforcer, and Loop Operator. This chapter covers each one in full — what it is, how its gates work, what it produces, and what breaks when it's misconfigured or bypassed. The Agent Reference section at the end is a cross-cutting capability matrix: the fastest way to answer "which agent does X?"

---

## How to Read This Chapter

Each agent section contains:
- An **Agent Definition Block** — the properties table that defines how the agent is invoked and what it produces
- **Gate descriptions** — every checkpoint the agent runs through, with pass and fail paths
- A **Case Scenarios Table** — every significant input type the agent handles, mapped to its classification and output
- A **"Does NOT do" list** — explicit scope limits that prevent misuse

The **Agent Reference** section at the end contains the full capability matrix for all agents in the setup — not just the six covered here. Use it as a quick-lookup reference after reading the individual sections.

---

## 10.1 — FR Analyst Agent

### Agent: fr-analyst

| Property | Value |
|----------|-------|
| **File** | `.claude/agents/fr-analyst.md` |
| **One-line role** | The requirements specialist that converts a raw feature description into a production-ready FR documentation package |
| **Invoked by** | Main Claude (automatically when requirement is described in natural language) |
| **Mode** | Background |
| **Session type** | Stateful continuation (same agent session through the intake Q&A) |
| **Input receives** | Raw user description of a feature, flow, or requirement — no pre-processing by Main Claude |
| **Output produces** | 3 FR files + updated pipeline status + claude-mem storage of non-obvious decisions |
| **Memory query** | Yes — mandatory Pre-Step before any intake begins |
| **Does NOT do** | Write implementation code, review code, run flutter analyze, make final architecture decisions without human confirmation |

**Trigger conditions (from agents.md):**
- Human describes a feature, user journey, or flow in natural language WITHOUT using action words like "develop", "implement", or "build"
- Example trigger: "I want a filter system where users can filter by age and distance" → fr-analyst fires
- Counter-example: "implement a filter system" → developer pipeline fires, NOT fr-analyst

**Why raw prompt, not processed prompt:**
The FR analyst's first step is a classification check and memory retrieval — it needs the raw user description to decide what questions to ask and what past decisions apply. If Main Claude pre-processes the input ("the user wants X, the key requirements are Y, please generate the FR"), the agent skips its intake phase and produces a shallow spec based on Main Claude's interpretation rather than a thorough Socratic exploration. Raw input is what triggers the agent to ask the right questions.

---

### Why It Exists

**Without the FR analyst:** A developer types "implement a profile filter feature," Main Claude starts writing code, and 45 minutes later the implementation is done — but it's missing edge cases (what happens when the user sets age min higher than max?), missing UI states (no empty state when filters return zero results), missing business rules (can a user save filter presets?), and the API contract was never verified with the backend team. The feature is working code that may need to be rewritten.

**With the FR analyst:** Before any code is written, the agent asks one question at a time — through a structured 9-step intake — until every ambiguity is resolved. The output is three structured documents: a flow spec, an API spec, and an implementation plan. The developer agent gets these as input and implements a complete, unambiguous feature. Rework rate drops significantly.

---

### The Triple-Role Identity

The FR analyst holds three roles **simultaneously** throughout every intake. Not sequentially — simultaneously.

| Role | What it checks |
|------|---------------|
| **Senior Developer** | Technical feasibility, Clean Architecture compliance, what already exists that can be reused, what will require architectural discussion |
| **Product Designer** | UI states (loading, error, empty, success), micro-interactions, transitions, whether the UX will feel polished or generic |
| **Business Owner** | Does this requirement match the product's core mechanics? Is this scope creep? Are there missing business rules? What edge cases exist for premium features or account states? |

Every clarifying question comes from all three lenses — not just technical. A question like "what happens when a user with zero results sees the filtered list?" is asked simultaneously by the designer (empty state needed) and the business owner (should we suggest lowering their filter criteria?) and the developer (the API must return a flag for this case).

> **CRITICAL:** If the FR analyst drops into single-role thinking — asking only technical questions, or only UX questions — the spec it produces will have gaps. The triple-role identity must be active on every question.  
> If violated: the Implementation_Tasks.md will be missing a dimension (UI states, business rules, or technical constraints), and the developer agent will have to guess on that dimension.

---

### Step 0 — Memory Retrieval Gate

Before asking the human a single question, the FR analyst runs this mandatory check:

| Property | Detail |
|----------|--------|
| **Trigger** | Every FR session — no exceptions |
| **Precondition** | None — runs first, before any input is processed |
| **Runs at** | Step 0, immediately on invocation |
| **Exit — Pass** | Memory loaded, relevant past decisions applied → continue to intake |
| **Exit — Fail** | N/A — memory retrieval always completes (may return empty results) |
| **Protects against** | Repeating questions already answered in past FR sessions; asking about business rules already settled; proposing approaches already rejected |

**What the agent does at this gate:**
1. Query claude-mem for `"[feature area] requirements"` — find any past decisions for this module or similar modules
2. Query claude-mem for `"product owner preferences"` — find UX constraints stated in past sessions (e.g., "no modal dialogs," "always inline errors")
3. Query claude-mem for `"[similar feature] business rules"` — find edge cases already decided in related FRs
4. Read `docs/FR/_pipeline_status.md` — is a similar module already built, in progress, or pending? Is this a duplicate?
5. Grep `docs/memory/component_registry.md` for components this feature could reuse
6. Grep `docs/memory/api_registry.md` for endpoints that already exist for this area

**Example trigger input:**  
A new FR session begins for any feature

**Example output when gate passes:**  
Memory loaded. Relevant findings: component X exists and can be reused. Endpoint `/api/v1/users/filters` was discussed in the ProfileModule FR but never implemented. Product owner stated "no pagination controls visible to user" in past session. Applying these findings before first question.

**Example output when gate passes with empty results:**  
Memory retrieved. No past decisions found for this feature area. Proceeding to intake with clean slate.

---

### The Intake Process — 9-Step Socratic Method

After Step 0, the FR analyst begins a structured intake. The key rule is **one question at a time**. Never ask all 9 clarifying questions in a single message — this overwhelms the human and produces short, incomplete answers that result in a shallow spec.

```
Step 1: Listen completely
      ↓
      Capture the full user journey and business context as described.
      Do not interrupt. Do not suggest. Just receive.
      ↓
Step 2: Explore existing context
      ↓
      Review memory findings from Step 0. What already exists?
      What related decisions have already been made?
      ↓
Step 3: Ask clarifying questions (ONE AT A TIME)
      ↓
      Each question is answered before the next is asked.
      Questions explore: UI states, business rules, API needs,
      component reuse, security, performance, edge cases.
      ↓
Step 4: Devil's advocate probes
      ↓
      "What happens when [failure condition]?"
      "What if the user [edge case behavior]?"
      These are the questions that prevent rework.
      ↓
Step 5: Ambiguity check
      ↓
      Identify any requirement that can be interpreted two ways.
      Force an explicit choice. Never leave ambiguities in the spec.
      ↓
Step 6: Scope assessment
      ↓
      Is this one feature or multiple independent subsystems?
      If multiple: should they be separate FR packages?
      ↓
Step 7: Propose 2-3 design approaches
      ↓
      Show trade-offs for each direction.
      Let the human choose — do not decide unilaterally.
      ↓
Step 8: Present design sections for approval
      ↓
      Get approval SECTION BY SECTION, not all at once.
      A section approved is locked. Move to the next section.
      ↓
Step 9: Self-review the spec
      ↓
      Before generating files: check for contradictions,
      vague language, placeholders, unbounded scope,
      uncovered edge cases.
      ↓
Generate FR files only after Step 9 passes.
```

> **WARNING:** Asking all questions at once (dumping a list of 9 questions) produces short answers and an incomplete spec. One question at a time forces the human to think deeply about each dimension. The extra turns are worth the thoroughness.  
> Instead: ask the most critical question first, wait for the answer, then ask the next most critical question.

---

### Epic Grouping (for multi-module features)

When a feature involves 3 or more modules or 2 or more distinct API surface areas, the FR analyst proposes grouping the related FRs under a named epic before generating any files.

Epic grouping sets the correct implementation order upfront — which modules must be built first before others can depend on them. This prevents building Module B before Module A is stable, then having to rewrite Module B when Module A changes.

In `docs/FR/_pipeline_status.md`, epics appear as parent rows with individual FR modules as child rows. Status at the epic level is the aggregate of all children:

```
## Epic: UserDiscovery

| Module | Status | Notes |
|--------|--------|-------|
| FilterModule | ⏳ PENDING | depends on UserModule done |
| DiscoverModule | ⏳ PENDING | depends on FilterModule |
| UserModule | 🔄 IN_PROGRESS | — |
```

---

### Canonical Reference Module

When writing Implementation Tasks, the FR analyst references an existing correctly-structured module as the structural template. This prevents each new module from having a different folder structure.

After the first complete feature is implemented following the project architecture, designate it as the canonical reference module in `ARCHITECTURE.md`. In every subsequent `Implementation_Tasks.md`, include one line:

```
Follow the folder and file structure of `lib/features/[canonical_module]/`.
```

When the architecture evolves, update the canonical reference to the most recently correctly-structured module. This keeps the codebase structurally consistent without repeating architecture rules in every FR.

---

### The Three Output Files

The FR analyst produces exactly three files per feature module, placed in `docs/FR/{module}/`:

**File 1: `{Module}_Flow_Requirements.md`**

Maps every user journey with full UI states (loading, error, empty, success), edge cases, and business rules. This is the spec the developer reads to understand what screens to build and what behavior each state requires.

Minimum contents:
- Primary user journey (step by step, from trigger to completion)
- All UI states for every async operation
- Business rule constraints (validation logic, access control, premium feature gates)
- Error scenarios with user-visible messages
- Edge cases (empty data, concurrent actions, account state conditions)

**File 2: `{Module}_API_Requirements.md`**

The endpoint specification for the backend developer. This file exists before any Flutter implementation starts.

Minimum contents:
- Complete endpoint list (method, path, purpose)
- Request and response structures (field names, types, nullable fields)
- Authentication requirements (which endpoints require a valid session)
- Pagination specification (default page size, max page size, cursor vs. offset)
- Error code list with HTTP status codes and user-visible message for each
- Rate limiting specifications for high-frequency endpoints

**File 3: `{Module}_Implementation_Tasks.md`**

The phase-by-phase development plan that the developer agent reads as its implementation guide.

Minimum contents:
- Phase 1: Domain layer (entities, use cases, repository interfaces)
- Phase 2: Data layer (API calls, DTOs, repository implementations)
- Phase 3: Presentation layer (screens, controllers, widgets)
- Phase 4: Navigation and dependency injection
- Phase 5: Testing (use cases 100%, controllers 80%+)
- Figma design requirements (which screens need design before implementation)
- Component reuse list (which existing components to use instead of building new)

---

### Backend Verification Loop

The `{Module}_API_Requirements.md` goes to the backend developer **before any Flutter implementation starts**. This is a mandatory step, not optional.

```
FR analyst generates API_Requirements.md
      ↓
Backend developer reviews for feasibility
      ├─ Feasible as-is → backend confirms → Flutter implementation starts
      │
      └─ Changes needed (different data shape, different endpoint, missing field)
              ↓
         FR analyst updates API_Requirements.md
              ↓
         Backend confirms updated spec
              ↓
         Flutter implementation starts
```

**Why this loop exists:** Building Flutter code against an API spec that the backend then changes is expensive. The frontend code is structured around data shapes — a field name change or response shape change requires touching every screen and model that uses that endpoint. Verifying the API spec before Flutter work starts costs one backend conversation. Fixing it afterward costs days.

> **CRITICAL:** Never let the developer agent begin implementation while API_Requirements.md is in PENDING state (backend not yet confirmed).  
> If violated: frontend is built against a spec that may change, requiring partial or full rewrite of the data and presentation layers.

---

### Store to Claude-Mem (After Pipeline Updated)

After marking the pipeline status, the FR analyst stores non-obvious decisions to claude-mem. These are decisions that won't be visible by reading the FR files alone.

Items to store:
- Product owner UX preferences stated during intake (e.g., "no modal dialogs for errors — always inline snackbar")
- Animation or theme constraints confirmed during design discussion
- Business rule exceptions that seem unusual but were explicitly confirmed
- Technical constraints decided during intake (e.g., "use polling not WebSocket for this feature")

Format:
```
Module: [feature name]
Type: [product-preference | business-rule | technical-decision | ux-constraint]
Detail: [specific statement, precise enough to find via keyword search]
Source: FR intake [date]
```

**Why this matters:** FR documents capture WHAT was decided. Claude-mem captures WHY and under what context. Six months later, when a developer changes a feature, the agent can retrieve "no modal dialogs" from claude-mem and apply it — without re-asking the same question that was already settled.

---

### Case Scenarios

| Input type | Example | Classification | Agent behavior | Output |
|------------|---------|---------------|----------------|--------|
| Simple feature (one screen, one endpoint) | "I want users to be able to save their filter preferences" | Standard FR | Full 9-step intake, 3 files | FR package, PENDING status |
| Complex feature (multi-module, cross-system) | "I want a complete notification system with push, in-app, and settings" | Epic required | Propose epic grouping first, then FR per module in dependency order | Epic structure + individual FR packages |
| Feature request that is actually a bug | "The profile filters aren't working — users expect it but nothing shows" | NOT a feature | Redirect: "This sounds like a bug report. Use the `bug::` prefix to trigger the debugger." | Redirect message only — no FR files |
| Feature requiring backend confirmation first | "Add a video profile feature" | PENDING — backend unknown | Generate FR with [PENDING BACKEND CONFIRMATION] flag on API_Requirements.md | 3 files, pipeline marked PENDING |
| Feature contradicting a previous decision | New filter layout that contradicts a UX constraint stored in claude-mem from 3 sessions ago | Conflict detected | Surface the conflict explicitly, ask human to resolve before proceeding | Conflict summary, waits for resolution |
| Requirement already built (pipeline check) | Describing a feature that exists in pipeline as DONE | Duplicate detected | "This module (FeatureModule) is already marked DONE in the pipeline. Is this an extension or a modification?" | Clarification request — no FR until confirmed |
| Ambiguous scope (could be one or three features) | "I want to revamp the profile experience" | Scope unclear | Ask scoping questions — is this profile viewing, editing, photo management, or all three? | Scoped feature list, then FR per scope item |

---

### What It Does NOT Do

- **Does not write implementation code.** The FR analyst produces documentation. Code comes from the developer agent after the FR is confirmed and the backend verification loop is complete.
- **Does not run flutter analyze.** Analysis is for post-implementation, not pre-implementation.
- **Does not make final architecture decisions without human confirmation.** The FR analyst proposes approaches and presents trade-offs. The human chooses. The Confirmation Gate at the end of every FR session is non-negotiable for new modules.
- **Does not skip the intake process for "simple" features.** Every feature deserves structured thinking. Simple features that skip intake most frequently produce the missing edge cases that create rework.
- **Does not combine questions.** One question per turn. Always.

---

### [Flutter-GetX Specifics] — What the FR Analyst Adds for GetX + Clean Architecture Projects

These additions apply only when the project uses GetX + feature-first Clean Architecture. They are encoded in the GetX version of the fr-analyst agent file.

**Locale and model key enumeration in Implementation Tasks**

Every `Implementation_Tasks.md` for a project with localization must enumerate all new locale keys and model key constants before implementation begins:

```
## New Locale Keys Required

| Key | English value | Screen(s) that use it |
|-----|---------------|-----------------------|
| locale.filterAgeRange | "Age Range" | FilterScreen |
| locale.filterNoResults | "No profiles match your filters" | FilterScreen (empty state) |

## New Model Key Constants Required

| Class | Constant | Storage scope |
|-------|----------|---------------|
| FilterKeys | kAgeMin, kAgeMax | Hive — userBox |
| FilterKeys | kDistanceKm | Hive — userBox |
```

**Why at FR stage:** If keys are not planned before implementation starts, developers use hardcoded strings, create key collisions in Hive, or miss translatable strings. All three are expensive to fix post-implementation. Planning them at FR stage takes five minutes. Fixing them after implementation takes hours and risks missing some.

---

**5-phase implementation order (Clean Architecture)**

`Implementation_Tasks.md` must phase work in this exact order:

1. **Models** — entity classes, DTOs, model key constants
2. **API layer** — repository methods, data source calls, endpoint wiring
3. **Screens** — screen files, controller, bindings, widget tree
4. **Locale keys** — register all new keys in the localization files
5. **Navigation** — register routes in `app_pages` / `app_routes`, update any callers

Each phase depends on the previous one being complete. Domain entities must exist before data layer can reference them. Controllers must exist before screens can use them. This order is non-negotiable for Clean Architecture: skipping it produces import cycles and undefined references.

---

**Cross-screen event name planning (GetX)**

For features that update state across screens (e.g., accepting a request removes the card from the discover stack AND updates a badge count), event names must be agreed in `Flow_Requirements.md` before implementation starts.

Include a Cross-Screen Events table in every `Flow_Requirements.md` for features with cross-screen state:

```
## Cross-Screen Events

| Event name | Fired by | Consumed by |
|------------|----------|-------------|
| onRequestAccepted | RequestDetailController | DiscoverController (remove card), TabBarController (decrement badge) |
| onMatchCreated | RequestDetailController | ChatController (enable chat), MatchListController (add entry) |
```

**Why at FR stage:** If two developers independently name the same logical event differently (`requestAccepted` vs `onRequestSuccess`), the sender and receiver never connect — and this class of bug is invisible until integration testing. The event name is a contract between two controllers. Define it before either controller is written.

---

### Common Mistakes — FR Analyst

**Mistake 1: Main Claude processes the input before passing to fr-analyst**

**Symptom:** FR analyst produces a spec immediately without asking clarifying questions. The spec is suspiciously complete but misses critical edge cases.

**Cause:** Main Claude pre-analyzed the requirement and passed a processed description ("The user wants X with Y and Z already assumed") instead of the raw user message. The agent skipped its intake process because Main Claude already "answered" its questions.

**Fix:** Always pass the raw user message to fr-analyst. Never enrich it with Main Claude's analysis. If the trigger is "I want a new discovery screen with age and distance filters," that exact sentence is what the agent receives — not "The user wants a filter feature. Key requirements: age range slider, distance selector, filter persistence."

---

**Mistake 2: Starting Flutter implementation before backend confirms API_Requirements.md**

**Symptom:** Developer agent implements several screens, models, and repository calls. Backend comes back with "the response structure is different — we can't send `filter_id` in that format." Frontend rewrite required.

**Cause:** The team skipped the backend verification loop and started Flutter work immediately after the FR was generated.

**Fix:** Mark the pipeline entry as PENDING until backend explicitly confirms the API spec. The developer agent must not start while the status is PENDING. Add this check to your agents.md trigger table: "If pipeline status is PENDING (backend confirmation outstanding) → do not launch developer agent."

---

**Mistake 3: FR analyst asks all clarifying questions at once**

**Symptom:** Human answers with short, vague responses ("yeah, the usual stuff") because the list of questions is overwhelming. FR spec is shallow and misses business rules.

**Cause:** Agent file was written without the "one question at a time" rule, or the rule was present but phrased as advisory ("try to ask one question at a time") rather than mandatory.

**Fix:** In the agent file, write: "MANDATORY: Ask exactly one clarifying question per message. Do not proceed to the next question until the current question is answered." The imperative form enforces compliance; the soft form doesn't.

---

**Mistake 4: Not updating claude-mem after FR completion**

**Symptom:** Three sessions later, the developer agent or a new FR session asks the product owner a question that was already settled ("should errors be inline or modal?") — the product owner is frustrated, the answer is re-decided, and it conflicts with how the previous feature was built.

**Cause:** The fr-analyst completed the FR but skipped the store-to-claude-mem step (Step 7 of the workflow).

**Fix:** Make Step 7 non-optional in the agent file. The step is: "After pipeline_status.md is updated, store non-obvious product owner preferences, business rule exceptions, and technical constraints to claude-mem." Verify this step ran by checking that claude-mem has an entry for the feature.

---

---

## 10.2 — Systematic Debugger Agent

### Agent: systematic-debugger

| Property | Value |
|----------|-------|
| **File** | `.claude/agents/systematic-debugger.md` |
| **One-line role** | The root-cause investigation specialist that confirms what is broken before any code is changed |
| **Invoked by** | Main Claude — automatically on `bug::` / `issue::` prefix, or any informal "fix [X]" message |
| **Mode** | Foreground |
| **Session type** | Stateful continuation (human may paste logs into the same session) |
| **Input receives** | Raw bug description only — Main Claude must never pre-process or add investigation steps |
| **Output produces** | Handoff Brief (CASE A — Flutter fix) OR backend issue logged to `docs/backend_issues/backend_issues.md` (CASE B) |
| **Memory query** | Yes — reads `docs/memory/error_learnings.md` during STEP 1 of the Full Investigation path |
| **Does NOT do** | Write fix code, apply changes, skip gates to go faster, produce briefs with assumption language |

**Trigger conditions (from agents.md):**
- `bug:: [description]` — mandatory trigger, always foreground, always first
- `issue:: [description]` — same as above
- `fix [description]` (informal) — treated identically to `bug::`
- Any message describing wrong behavior, unexpected output, or a crash

**Why raw prompt, not processed prompt:**
The systematic-debugger's first action is the DATA GATE — it scans the raw bug description for data mismatch keywords before doing anything else. If Main Claude adds investigation steps ("I think the issue might be in the controller, check line 42"), the agent follows those instructions instead of its own gate sequence. The DATA GATE is bypassed. The agent produces a hypothesis-based brief with no runtime evidence, marked as high confidence. This is the most costly failure mode in the entire setup — it produces wrong fixes that create new bugs.

> **CRITICAL:** Main Claude must pass only this to the systematic-debugger — nothing more:
> ```
> Bug description: [exact user message]
> Screen/module: [inferred from description]
> Project root: [path]
> ```
> If violated: the DATA GATE does not fire on pre-processed prompts. The agent skips to static analysis and produces a fabricated root cause with no runtime evidence.

---

### Why It Exists

**Without the systematic debugger:** A developer reads a bug report ("the message count shows 0"), goes directly to the controller file, sees a suspicious variable, changes it, marks it fixed. The real cause — the API was returning the count in a different JSON field than the one the model was reading — is never found. The change does nothing. Two more guesses follow. After the third wrong fix, the developer is further from the root cause than when they started.

**With the systematic debugger:** The agent identifies the data mismatch keywords in the bug report, runs one grep to find the endpoint name, asks the human to paste the console log. The log shows the API is returning `unread_count: 5` but the model reads `message_count`. Root cause confirmed in two minutes. Zero guesses. Zero wrong fixes.

---

### The Zero-Assumption Policy

The systematic-debugger has one global rule that governs every gate in its sequence:

> **No handoff brief until Evidence Status: CONFIRMED.**

`CONFIRMED` means runtime evidence (API log, console output) AND direct code evidence (grep match, file read) both point to the same root cause. No assumption language (`likely`, `maybe`, `appears`, `probably`) is permitted in any brief. If evidence is incomplete, the agent stops and outputs:

```
⏸️ NEEDS CONFIRMATION — no code changes yet

Current evidence is insufficient to produce a safe fix.
Please share the missing runtime/API/code evidence listed below:
1) ...
2) ...

I will not provide a fix handoff until evidence status is CONFIRMED.
```

---

### Gate 1 — DATA MISMATCH EARLY EXIT

| Property | Detail |
|----------|--------|
| **Trigger** | Any of these keywords appear in the bug description: "wrong amount", "wrong value", "doesn't match", "not match", "mismatch", "shows X but should show Y", "wrong number", "wrong count", "wrong price", "wrong total" |
| **Precondition** | None — this fires BEFORE classification, BEFORE file reading, BEFORE any reasoning |
| **Runs at** | First action on every input — before the agent reads the bug description in detail |
| **Exit — Triggered** | Run one grep to find the endpoint name, then ask human to paste console log → STOP |
| **Exit — Not triggered** | Continue to Gate 2 (Classification Gate) |
| **Protects against** | The agent reading source files and forming hypotheses based on code structure alone — which produces a "confident" but unverified root cause for bugs that are almost always API response issues |

**What the agent does when triggered:**

1. Run one targeted grep to find the endpoint string for the affected module
2. Output the DATA MISMATCH message (see below) and STOP — no further investigation until the human pastes the log

```
⏸️ DATA MISMATCH DETECTED — please share console/API log output

Steps:
1. Hot reload (press 'r') OR fully restart the app
2. Navigate to [screen name]
3. In the console, find the debug output for the [endpoint] API call
4. Paste the full response block here

Endpoint to look for: [endpoint found by grep]

I will NOT investigate further until I see the actual API response.
```

**Why this gate exists:** Data mismatch bugs have two possible root causes — the API is returning the wrong value (backend bug), or the Flutter app is reading the API response incorrectly (frontend bug). Both possibilities require seeing the actual API response to distinguish. Reading source files first produces a hypothesis based on code logic — but code logic tells you what the app *intends* to do, not what the server actually sent. The log is the only evidence that settles this question.

**What Main Claude must do when this gate fires:**
Copy the agent's message to the human word-for-word. Nothing else. Do not add analysis. Do not suggest "the issue might be in X." When the human pastes the console log, pass it to the same agent session (stateful) or re-launch with the original bug + screen + raw log (stateless). Zero additions.

---

### Gate 1b — Log Completeness Gate

| Property | Detail |
|----------|--------|
| **Trigger** | Human pastes a console log block after DATA GATE fires |
| **Precondition** | DATA GATE has already fired and human has pasted a log |
| **Runs at** | Immediately after the human's console paste — before reading any field values |
| **Exit — Pass** | Log is complete and relevant fields are visible → continue to classification |
| **Exit — Fail (truncated)** | Build and output a filled cURL command using the URL and token from the pasted log — never a template with placeholders |
| **Exit — Fail (key missing)** | Ask the human directly for the specific missing field |
| **Protects against** | Classifying the bug based on a truncated log — which produces a wrong CASE A/B decision |

**Completeness check:**

```
✅ Complete log:   ...,"status":1,"deleted_at":null}
❌ Truncated log:  ...,"is_verified":    (cut off mid-value)
```

If truncated — the agent fills a real cURL command from the log's URL line, HTTP method, and Authorization header value (all visible in a typical console log). It never outputs a template with `[placeholder]` text. The filled cURL lets the human get the complete response without needing to reproduce the bug.

---

### Gate 2 — Classification Gate

| Property | Detail |
|----------|--------|
| **Trigger** | Every bug that did NOT trigger the DATA GATE (or after log is confirmed for data mismatch bugs) |
| **Precondition** | DATA GATE did not fire (or data mismatch log has been analyzed) |
| **Runs at** | Before opening any file |
| **Exit — Route 1** | NOT A BUG → redirect message, stop |
| **Exit — Route 2** | FAST TRACK → read one screen file, produce Fast Track Brief |
| **Exit — Route 3** | FULL INVESTIGATION → 4-step mandatory gate sequence |
| **Protects against** | Investigating feature requests (wastes time) or over-investigating simple widget changes (wastes tokens) |

**Three routes:**

**Route 1 — NOT A BUG (Feature Request or Design Task)**

Triggered when the description asks to add a new screen, add search/filter to an existing screen, match a Figma design (purely visual), add a new API integration, or restructure a layout as a design task.

Output:
```
⛔ NOT A BUG — Feature Request

This is a feature/design request, not a bug. Redirecting to developer agent.

Request: [description]
Reason: [why this is a feature, not a bug]
Suggested agent: developer (with planner if complex)
```

> **NOTE:** "Match design" exception — if the mismatch involves a number, count, or data field value (not just visual layout), it is a data bug. Apply the DATA GATE — do not redirect.

---

**Route 2 — FAST TRACK (Simple UI / Widget Fix)**

Triggered when the description involves: adding a max character limit, removing a widget or label, changing a color/size/font, adding a validation message, hiding/showing a field based on an existing condition, or fixing a wrong hardcoded string.

Fast Track reads exactly ONE screen file, runs the dependency check (grep + project_map.md blast radius check), and produces a Fast Track Brief. It does NOT search component folders, locale files, or run the full Phase 1-3 gate sequence.

Fast Track Brief format:
```
Bug: [description]
Screen file: lib/src/features/[module]/[screen].dart
Widget: [exact widget name]
Fix: [one property to add/change/remove]
Callers: [grep output — filenames only]
Blast Radius Tier: [Tier 4 — file-local / Tier 3 — feature-level / Tier 2 — HIGH]
Risk: [LOW / MEDIUM / HIGH]
```

> **WARNING:** If opening the screen file reveals the fix involves state, API calls, navigation, or business logic — stop, re-classify as FULL INVESTIGATION, start the full gate sequence.  
> Instead: do not apply any fix until re-classification is complete.

---

**Route 3 — FULL INVESTIGATION (Logic / State / Runtime Bug)**

Triggered when the description involves: wrong data shown on screen, a crash or exception, a list not refreshing after an action, state not updating, real-time events not received, storage data lost, pagination issues, navigation arguments lost, or any ambiguous case.

---

### Gates 3-6 — Full Investigation Sequence

This is the mandatory 4-step gate sequence for Route 3. No file reading is permitted before Step 4.

```
STEP 1 → PRE-STEP   — read error_learnings.md (no other tools)
      ↓
STEP 2 → PHASE 1    — symptom documentation (reasoning only, no tools)
      ↓
STEP 3 → PHASE 2    — hypothesis formation (reasoning only, no tools)
      ↓
STEP 4 → PHASE 3    — evidence collection (Read, Grep, Bash permitted here only)
      ↓
DEPENDENCY CHECK    — grep callers + project_map.md blast radius
      ↓
BRIEF INTEGRITY     — verify every symbol in the proposed fix exists
      ↓
CASE A/B DECISION   — Flutter fix or backend issue
      ↓
HANDOFF BRIEF / BACKEND LOG
```

**STEP 1 — Pre-Step (error_learnings.md)**

Read `docs/memory/error_learnings.md` completely before any other action. Scan for any entry matching the current bug's module, screen, or symptom pattern.

- Match found → present it to the human, ask if it matches. Wait for confirmation before proceeding.
- No match → proceed to STEP 2.

This is the cheapest check in the workflow. Skipping it and producing a wrong root cause when the answer was already in error_learnings.md is the first strike of the 3-Strikes Rule.

**STEP 2 — Phase 1: Symptom Documentation (no tools)**

Document without opening any file:
- WHAT is happening vs. what should happen
- WHERE it happens (screen, layer, storage mechanism, event system)
- WHEN it happens (always / first load / after refresh / after tab switch / after navigation return)
- LOG EVIDENCE — if the DATA GATE fired, summarize what the logs showed

**STEP 3 — Phase 2: Hypothesis Formation (no tools)**

Pick the top 1-2 hypotheses from the relevant category. Jump to the category that matches Phase 1 symptoms — do not scan all categories.

Priority order for hypothesis selection:
1. API / Server issues (JSON key mismatch, wrong endpoint, auth failure, wrong params)
2. State management issues (observable read outside reactive context, controller lifecycle, list mutation pattern)
3. Real-time / event issues (room not joined, event name mismatch, connection drop)
4. Storage issues (wrong box name, key mismatch, storage not initialized)
5. Navigation issues (wrong arguments, missing result handling)
6. Form / Lifecycle / Async / Pagination issues

> **NOTE:** See the `[Flutter-GetX Specifics]` section below for the exact hypothesis patterns when using GetX + Clean Architecture. These patterns map directly to the GetX controller lifecycle, RxList mutation rules, Socket.IO event handling, and Hive storage patterns used in this setup.

**STEP 4 — Phase 3: Evidence Collection (tools permitted)**

Run grep commands targeted at the hypothesis. After each grep — apply negative confirmation:
- Evidence matches hypothesis → proceed to Dependency Check
- Evidence contradicts hypothesis → discard, return to Phase 2 with next candidate
- No evidence found → hypothesis wrong, return to Phase 2
- Both hypotheses exhausted → add boundary `debugPrint` logs at each layer transition and ask human to paste output

> **WARNING:** Never write a Handoff Brief without a positive grep match or confirmed log evidence.  
> Instead: emit `⏸️ NEEDS CONFIRMATION` and list exactly what evidence is missing.

---

### Dependency Check (Mandatory Before Every Brief)

Before writing any Handoff Brief, the agent runs two checks:

**Check 1 — Grep all direct callers:**
```bash
grep -rln "<function_name>|<class_name>|<field_name>" lib/ --include="*.dart"
```
The returned filenames go into the **Callers** field of the brief. If the only result is the screen file being changed → write "grep verified: only in this file."

**Check 2 — Cross-check blast radius:**
Read `docs/maps/project_map.md` → Blast Radius Matrix. Find the file being changed, note its tier.

| grep result | Blast radius tier | Risk |
|-------------|-------------------|------|
| Only the screen file | Tier 4 — file-local | LOW |
| Other screen files | Tier 3 — feature-level | MEDIUM |
| Shared service, shared model, routing file | Tier 1 or 2 | HIGH |

**Fix Safety Gate:** For each caller file found — verify the proposed fix does not break that caller. If a risk is found, expand the fix to include the additional change, then re-check before writing the brief.

---

### Brief Integrity Rule

Every function name, model name, class name, endpoint string, and JSON key written in the Handoff Brief must be confirmed before writing. A brief with an invented function name is worse than no brief — the developer builds against something that does not exist, creating a second problem.

**Verification required:**
- Before writing "call `getItemList()`" → grep for `getItemList` in `lib/`
- Before writing "use `ItemModel`" → grep for `class ItemModel` in `lib/`
- Before writing "add JSON key `advance_fee`" → confirm the key appears in the pasted API log

If the function or model does not exist → do not invent it. Ask the human:
```
⚠️ I can see the bug but I cannot find the correct function to use instead.

Current call: [what it calls now]
This returns: [what data it returns — wrong data]

What should this screen be calling? Please tell me:
- The correct API endpoint name, OR
- The correct function already in the repository layer
```

---

### CASE A vs. CASE B Decision

After evidence is confirmed, classify the root cause:

| Console log shows | Classification |
|-------------------|---------------|
| API response has the correct value, but screen shows wrong value | CASE A — Flutter bug (parsing, wrong field, state) |
| API response has wrong value / missing required field, request params are correct | CASE B — Backend bug |
| Request params are wrong (wrong ID, wrong scope) and code proves it | CASE A — Flutter request construction bug |
| Evidence is mixed or incomplete | Emit `⏸️ NEEDS CONFIRMATION` — stop |

**CASE A** → produce Handoff Brief with `Evidence Status: CONFIRMED` → wait for human confirmation → pass to developer agent (Correction Pass Mode).

**CASE B** → append to `docs/backend_issues/backend_issues.md` (ONE file, always append, never create per-issue files) → tell human to share the file with the backend team → no developer agent is launched.

---

### The 3-Strikes Rule

After 3 failed fixes on the same bug — stop. Do not attempt a 4th fix.

Output:
```
⏸️ 3 STRIKES REACHED

Three fixes have been attempted without resolving the root cause.
Continuing without changing the approach will produce increasingly speculative guesses.

Before the next attempt, we need to discuss:
1. What did each fix change and what evidence showed it was wrong?
2. Is the root cause in a layer we haven't examined yet?
3. Is this a systemic architecture issue rather than a localized bug?

Please confirm the approach before proceeding.
```

**Why this rule exists:** An LLM that repeatedly fails does not become more careful — it becomes more speculative. The 3rd guess is always less grounded than the 1st. The 3-Strikes Rule forces a pause that prevents the agent from guessing its way into creating three new bugs in the process of trying to fix one.

---

### Human Confirmation Gate

Every Handoff Brief — Fast Track and Full Investigation — ends with the agent waiting for human confirmation before anything is passed to the developer agent.

| Human response | Action |
|---------------|--------|
| "Yes, proceed." | Pass brief to developer agent (Correction Pass Mode) |
| "That's not it." | Re-open from Phase 1 with new information |
| "Not sure — check X first" | Gather targeted evidence, re-present brief |

CASE B (backend bug) does not go through this gate — the agent writes the backend issue file and tells the human it is done. No developer agent is launched.

---

### [Flutter-GetX Specifics] — GetX Hypothesis Patterns

When using GetX + Clean Architecture, the Phase 2 hypothesis categories have exact patterns to check. These are the most common root causes in this specific stack.

**Priority 2 — GetX / Controller / Obx patterns:**

| Pattern | Why it causes the bug | What to grep |
|---------|----------------------|-------------|
| `.obs` value read outside `Obx(() => ...)` | Widget never rebuilds when value changes | `grep -n "controller\.\|\.value"` on screen file, filter lines without "Obx(" |
| Controller not registered in binding | `Get.find<X>()` throws at runtime | `grep -rn "Get.lazyPut\|Get.put\|Get.find"` in `app/bindings/` |
| Non-permanent controller in IndexedStack tab | Controller auto-disposed on tab switch, state lost | `grep -n "Get.put"` — verify `permanent: true` for tab controllers |
| `RxList` assigned with `=` instead of `.assignAll()` | `Obx` does not rebuild — assignment replaces the reactive reference | `grep -n "\.assignAll\|= \[\|= List"` in the controller |
| Multiple `Get.put()` calls for same type without `tag` | Overwrites existing controller instance unexpectedly | `grep -rn "Get.put<"` across bindings and `onInit` methods |
| `GetBuilder` used instead of `Obx` | State only updates when `update()` is called manually | `grep -n "GetBuilder\|update()"` in screen file |

**Priority 2 — Socket.IO / Real-Time patterns:**

| Pattern | Why it causes the bug | What to grep |
|---------|----------------------|-------------|
| Room not joined before event emitted | Event arrives with no registered listener | `grep -rn "socket\.on\|socket\.emit\|join"` — check join happens before emit |
| Event name mismatch (camelCase vs snake_case) | Server emits `match_accepted`, Flutter listens for `matchAccepted` — never receives | `grep -rn "socket\.on\("` — compare exact string to backend docs |
| Socket listener registered multiple times | Handler fires twice per event (registered in `onInit` AND after reconnect) | `grep -n "socket\.on\("` in controller `onInit` and reconnect handler |
| Wrong `match_id` type (int vs string) | Room join silently fails — server expects string, Flutter sends int | Read the specific `emit()` call, check type of the room ID argument |

**Priority 2 — Hive / Local Storage patterns:**

| Pattern | Why it causes the bug | What to grep |
|---------|----------------------|-------------|
| Wrong box name | Reads from empty box, returns null for every key | `grep -rn "HiveUtils\.\|Hive\.box\|hiveKey"` — compare box name across files |
| Key string mismatch | `HiveUtils.get('user_token')` vs stored key `'userToken'` — always returns null | `grep -rn "hiveKey\|HiveConst"` — confirm key constants match usage |
| Box not opened before read | `HiveError: Box not found` thrown at runtime | Check `Hive.openBox()` is called in `main.dart` before `runApp()` |

**Grep template for GetX evidence collection (Phase 3):**
```bash
# Controller lifecycle — find onInit, onClose, ever() listeners
grep -n "onInit\|onClose\|onReady\|ever(" lib/src/features/[feature]/presentation/ -r

# RxList mutation pattern
grep -n "\.assignAll\|\.add(\|\.remove(\|\.clear(" lib/src/features/[feature]/ -r

# Obx coverage check — find reads outside Obx
grep -n "controller\.\|\.value" lib/src/features/[feature]/presentation/[screen].dart | grep -v "Obx("

# Socket event name match
grep -rn "socket\.on\|socket\.emit" lib/ --include="*.dart"

# Hive box and key usage
grep -rn "HiveUtils\.\|Hive\.box\|hiveKey" lib/ --include="*.dart"
```

---

### Case Scenarios

| Input type | Example | Classification | Agent behavior | Output |
|------------|---------|---------------|----------------|--------|
| Data value mismatch | "The unread message count shows 0 but there are unread messages" | DATA GATE fires | Grep endpoint, ask for console log, stop | DATA MISMATCH message |
| After log pasted — Flutter parsing bug | Log shows `unread_count: 5`, model reads `message_count` | CASE A — Flutter bug | Full Investigation confirms key mismatch | Handoff Brief, CONFIRMED |
| After log pasted — backend returns wrong value | Log shows `unread_count: 0` despite messages existing | CASE B — Backend bug | Write backend_issues.md entry | Backend issue logged, no developer |
| Simple widget fix | "The description field allows unlimited characters" | FAST TRACK | Read one screen file, dependency check, brief | Fast Track Brief |
| Feature request disguised as bug | "The discover screen should have a filter option" | NOT A BUG | Redirect message | Redirect, stop |
| State not updating after action | "After accepting a request, the card is still visible in the list" | FULL INVESTIGATION | 4-step gate sequence; GetX: RxList `.assignAll()` hypothesis | Handoff Brief, CONFIRMED |
| Crash on screen return | "The app crashes when navigating back from the profile screen" | FULL INVESTIGATION | Phase 1: when=after navigation return; Phase 2: lifecycle/controller dispose hypothesis | Handoff Brief, CONFIRMED |
| Backend confirmed root cause | "The API is definitely returning wrong data" | CASE B | Write backend_issues.md entry, skip developer | Backend issue logged |
| Ambiguous — could be widget or state | "The button label is wrong" | Tiebreaker applies | Hardcoded string → FAST TRACK; API field value → FULL INVESTIGATION | Brief after classification |
| 3rd fix failed | Bug persists after 3 attempts | 3-Strikes Rule | Stop, output structured pause message, wait for human | 3-Strikes pause message |

---

### What It Does NOT Do

- **Does not write the fix.** The systematic-debugger produces a Handoff Brief. The developer agent applies the fix.
- **Does not skip the DATA GATE for speed.** The gate fires on keywords regardless of how confident the agent feels about the root cause.
- **Does not produce briefs with assumption language.** Every claim in every brief is backed by observable evidence.
- **Does not investigate feature requests.** Redirect immediately.
- **Does not attempt a 4th fix after 3 failures.** The 3-Strikes Rule is absolute.
- **Does not leave Callers or Evidence Status blank** in any brief. These fields are proof that the dependency check and evidence gate ran.

---

---

## 10.3 — Planner Agent

### Agent: planner

| Property | Value |
|----------|-------|
| **File** | `.claude/agents/planner.md` |
| **One-line role** | The architectural planning specialist that produces a dependency-aware implementation plan the developer agent can execute without ambiguity |
| **Invoked by** | Main Claude — when complexity criteria are met, or when human explicitly requests a plan |
| **Mode** | Foreground |
| **Session type** | Fresh each time — receives feature description or FR file paths as input |
| **Input receives** | Feature description OR FR file paths (processed — Main Claude identifies what to plan) |
| **Output produces** | Structured implementation plan (Markdown document) — ends with Confirmation Gate |
| **Memory query** | Yes — mandatory Pre-Step before any analysis begins |
| **Does NOT do** | Write code, modify source files, launch the developer agent, bypass the Confirmation Gate |

**Trigger conditions (from agents.md):**
- No FR / Implementation Plan exists AND feature creates more than 3 files or a new module folder
- FR exists BUT feature touches a shared file with many callers
- FR exists BUT feature requires cross-module events (cross-screen state broadcasts)
- FR exists BUT feature creates more than 8 new files total
- FR exists BUT feature has non-obvious integration risk with in-progress work
- FR exists BUT `Implementation_Tasks.md` is missing or incomplete
- Human explicitly requests `"plan [feature]"` or `"design approach for [system]"`

**When NOT triggered:**
- FR docs exist AND none of the above complexity criteria apply → developer agent directly
- Single-file or 2-3 file additions → developer agent directly
- Bug fixes → never (planner has no role in root cause investigation)

**Why processed prompt, not raw prompt:**
The planner receives context from Main Claude — specifically, which FR files to read and what complexity factor triggered it. Unlike the systematic-debugger (which needs raw input to fire its DATA GATE), the planner's first step is memory retrieval and requirements analysis. Main Claude providing FR file paths as context saves the planner from searching for them.

---

### Why It Exists

**Without the planner:** A developer receives a feature request for a new module, opens an existing similar screen, copies its structure, and starts writing. Midway through, it becomes clear the new feature shares a model with two other modules. Changing the model breaks both. The developer didn't know to check because no one analyzed the blast radius before writing. The feature takes 3 days instead of 1 — and leaves two regressions behind.

**With the planner:** Before any code is written, the planner reads the FR docs, checks the registries, identifies what can be reused, maps every shared file that will be touched, and produces an ordered implementation plan with explicit reuse flags and risk notes. The developer follows the plan. No surprises mid-implementation.

---

### Why Opus Model

The planner is the only agent in this setup that uses the Opus model.

Architectural decisions have long-term consequences. A wrong implementation order (building presentation before domain exists) creates undefined references. A wrong decision to create a new shared model instead of extending an existing one creates diverging data shapes that will conflict in 6 months. A missed blast-radius analysis on a shared file causes silent regressions in unrelated modules.

Opus is used for the planner because the quality of the planning reasoning directly multiplies the quality of all subsequent implementation work. A correct plan enables a correct developer output. An incorrect plan produces incorrect code regardless of how well the developer follows it. The cost of Opus for planning is justified — and nowhere else in the pipeline is this true.

---

### The "FR Exists" Misconception

A common setup mistake: treating "FR exists" as sufficient reason to skip the planner.

The planner is not just for "when there is no plan." It is for when there is **architectural complexity** — regardless of whether FR docs exist.

The 5-trigger checklist that overrides "FR exists → skip planner":

| Trigger | Why planner still runs |
|---------|----------------------|
| Touches a shared file with many callers | FR captures WHAT to build; planner adds HOW to modify safely without breaking callers |
| Requires cross-module event broadcasting | Event names are contracts between controllers — they must be defined before either controller is written |
| Creates more than 8 new files | File dependency ordering matters; FR tasks files often don't specify inter-file dependencies |
| Has integration risk with in-progress work | Two concurrent modules touching the same shared file need explicit coordination |
| `Implementation_Tasks.md` is incomplete | An incomplete plan is no plan — the developer will have to guess on the missing dimensions |

If any one of these is true → planner runs, even if FR docs are present. The planner reads the FR docs as input and adds the architectural integration analysis on top.

---

### Step 0 — Memory Retrieval Gate

| Property | Detail |
|----------|--------|
| **Trigger** | Every planner session — no exceptions |
| **Precondition** | None — runs before any analysis |
| **Runs at** | First action on invocation |
| **Exit — Pass** | Memory loaded, relevant past decisions identified → continue to Requirements Analysis |
| **Exit — Fail** | N/A — memory retrieval always completes (may return no results) |
| **Protects against** | Proposing architecture that contradicts an established decision; creating something that already exists; hitting a known pitfall the team already documented |

**What the agent retrieves:**
1. `docs/memory/error_learnings.md` — grep for module name and adjacent module names. Find past pitfalls. Never propose architecture that contradicts an established pattern.
2. `docs/FR/_pipeline_status.md` — what is already built, what is IN_PROGRESS. The plan must account for in-progress work (do not touch it, do not conflict with it).
3. `docs/memory/component_registry.md` — list reusable components this plan can reference instead of creating new.
4. `docs/memory/api_registry.md` — list existing API functions that can be reused. Never propose duplicating a function that already exists.
5. `lib/src/features/` — does a partial implementation already exist for this module? If yes, the plan picks up from where it stopped — not from scratch.

> **CRITICAL:** A plan that proposes creating something that already exists wastes the developer's time and creates duplicate code. Memory retrieval costs one file read. Ignoring it can cost days of rework.  
> If violated: developer implements a duplicate API function that diverges from the existing one over time, creating two sources of truth for the same endpoint.

---

### Planning Flow

```
Input: feature description OR FR file paths
      ↓
Step 0: Memory Retrieval (error_learnings + pipeline + registries + existing screens)
      ↓
Step 1: Requirements Analysis
      ↓
      Read all 3 FR files (Flow Requirements, API Requirements, Implementation Tasks)
      Identify: screens, endpoints, models, locale keys, navigation wiring
      ↓
Step 2: Reuse Check
      ↓
      API functions: check api_registry + source
      Shared models: check existing model files
      Shared components: check component_registry
      Mark each item: "reuse existing — do NOT re-create" OR "new — must be added"
      ↓
Step 3: Scope Definition
      ↓
      Plan only what FR explicitly requires
      Flag anything developer must NOT add (scope creep prevention)
      Flag ambiguous business rules as explicit decision points
      ↓
Step 4: Implementation Order
      ↓
      Domain layer first (pure Dart, testable, no dependencies)
      Data layer second (depends on domain)
      Presentation layer last (depends on domain + data)
      Navigation and DI registration last
      ↓
Step 5: Risk & Red Flag Check
      ↓
      Business logic in build() → flag, move to use case / repository
      Shared file modification → read blast-radius matrix before finalizing
      Missing locale key list → flag as incomplete, must define before developer starts
      Any architectural anti-pattern → address explicitly in plan
      ↓
Output: Implementation Plan (structured Markdown)
      ↓
Confirmation Gate — END MESSAGE. Wait for human approval.
```

---

### Implementation Order (Why This Sequence)

The planner always produces phases in this sequence:

```
Phase 1: Domain layer
      → entities (immutable, @immutable, copyWith)
      → repository interfaces (abstract — no implementation)
      → use cases (one use case = one action)
      ↓
Phase 2: Data layer
      → DTOs / models (fromJson / toJson, toDomain())
      → data sources (API calls, HTTP client)
      → repository implementations (implements the domain interface)
      ↓
Phase 3: Presentation layer
      → controllers / view models (state management, calls use cases)
      → screens (reads reactive state, no logic in build())
      → widgets (stateless where possible)
      ↓
Phase 4: Registration and wiring
      → routes registered
      → dependency injection / bindings set up
      → navigation wiring (where is this screen launched from?)
      → cross-screen events (which controllers listen for which broadcasts)
```

**Why this order matters:** The domain layer must exist before the data layer can implement it. The data layer must exist before the presentation layer can call it. Building out of order creates undefined references mid-implementation — the developer hits compiler errors and must context-switch to fix the foundation instead of progressing.

---

### Risk and Red Flag Check

Before finalizing any plan, the planner checks for these issues. If found, each one is addressed explicitly in the plan — never silently ignored.

| Red flag | Why it's a problem | Correct approach |
|----------|-------------------|-----------------|
| Business logic proposed in `build()` or `Widget` | Untestable, couples UI to logic, breaks on rebuild | Move to use case or controller |
| New shared model proposed that duplicates an existing one | Two models for the same data → diverging field names over time | Reference and extend the existing model |
| Shared file modification without blast-radius analysis | Changing a shared service or entity touches every module that imports it | Read `docs/maps/project_map.md` blast-radius matrix for that file before finalizing |
| FR is ambiguous on a business rule | Developer will guess, guess will be wrong | Flag as "Decision needed: [describe ambiguity]" — human must resolve before developer starts |
| Locale key list missing from FR | Developer will use hardcoded strings | Flag: "Locale keys must be defined before developer starts" |
| Out-of-scope additions visible in FR (feature creep) | Untested, unreviewed features added implicitly | List under "Out of Scope — developer must NOT add" |

---

### The Confirmation Gate

After outputting the plan — the planner ends its response and waits.

The planner does NOT launch the developer agent. The planner does NOT assume approval. The human must explicitly confirm ("looks good, proceed") before implementation begins.

**Why this gate is non-negotiable:** The plan may surface decisions only the human can make — missing business rules, ambiguous scope, API contracts that need backend confirmation, or integration decisions that depend on timeline. A developer that starts before the plan is confirmed will build the wrong thing with high confidence.

**After human confirms:** Main Claude launches the developer agent, passing the confirmed plan as context. The planner stores any significant architectural decisions to claude-mem before handing off.

---

### [Flutter-GetX Specifics] — GetX + Clean Architecture Planning Patterns

**One use case = one action (enforced)**

The planner enforces this rule on every plan it produces. `LoginUseCase`, not `AuthUseCase`. `GetUserProfileUseCase`, not `UserUseCase`. A use case that does more than one thing cannot be tested in isolation and cannot be named precisely.

In the plan's Phase 1 section, every use case is listed with its exact name and its single `execute()` signature:
```
- GetDiscoverProfilesUseCase — execute(filters: FilterEntity) → List<UserEntity>
- AcceptRequestUseCase — execute(requestId: int) → void
```

If a developer asks "can I combine these into one use case?" — the answer is always no.

**GetX-specific red flags for the planner:**

| Red flag | Why it's wrong | Correct approach |
|----------|---------------|-----------------|
| Controller proposed for IndexedStack tab without `permanent: true` | Controller auto-disposed on tab switch, state is lost | Plan must explicitly mark: `Get.put(TabController(), permanent: true)` |
| `GetBuilder` proposed instead of `Obx` | State only updates when `update()` is called manually — missed updates | Use `Obx(() => ...)` wrapping observable reads |
| Shared controller proposed across two unrelated screens | Creates tight coupling, hard to test, makes the controller's scope ambiguous | One controller per screen; use events for cross-screen communication |
| Routes defined as raw strings | Route name change in one place doesn't propagate to callers | All route navigation uses `Routes.featureName` constants — never string literals |
| Direct API call proposed in controller | Bypasses the domain layer — untestable, violates Clean Architecture | API calls go: controller → use case → repository → data source |

**GetX plan format additions:**

The plan's Phase 3 and Phase 4 sections must include these GetX-specific entries:

```markdown
### Phase 3 — Presentation Layer
- lib/src/features/[name]/presentation/controllers/[name]_controller.dart
  → GetxController with .obs state
  → Calls use cases only — no direct API calls
  → Handles loading / error / success states as Rx<bool> / Rx<String>
- lib/src/features/[name]/presentation/screens/[name]_screen.dart
  → Uses Obx(() => ...) for all reactive reads
  → No logic in build() — all logic in controller
  → ColorHelper.xxx for all colors — no Color(0xFF...)
  → locale.xxx for all strings — no hardcoded text
- lib/src/features/[name]/presentation/bindings/[name]_binding.dart
  → Get.lazyPut(() => FeatureNameController())

### Phase 4 — Registration and Wiring
- Routes: add constant to lib/src/core/routes/app_routes.dart
- AppPages: add GetPage with binding to lib/src/core/routes/app_pages.dart
- Launched from: [exact file + line where Get.toNamed(Routes.xxx) will be added]
- Cross-screen events: [list event names, which controller fires, which controller consumes]
  → IndexedStack controllers: permanent: true
  → Push-and-pop route controllers: NOT permanent
```

---

### Case Scenarios

| Input type | Example | What planner does | Output |
|------------|---------|-------------------|--------|
| New module, no FR | "Plan a notifications module" | Full 5-step flow, creates plan from description alone | Complete plan, Confirmation Gate |
| New module, FR exists, simple | One screen, one endpoint, no shared files | Memory check → reads FR → straightforward plan | Plan references FR, phases 1-4, Confirmation Gate |
| FR exists but shared file modification required | New feature adds 2 functions to a shared API service used by 12 modules | Reads blast-radius matrix, adds ordering and safety notes to plan | Plan with explicit shared-file risk section |
| FR exists but Implementation_Tasks.md is incomplete | Missing locale keys, missing navigation wiring | Flags incomplete sections, fills gaps using Flow_Requirements.md | Complete plan that supplements the incomplete FR |
| Partial implementation exists | Module folder exists with 3 of 8 planned files | Memory check finds existing files → plan starts from file 4 | Incremental plan, skips already-done phases |
| Contradicting requirements in FR | Flow_Requirements says paginated list, API_Requirements says single object response | Flags contradiction explicitly | Plan with "Decision needed" block — waits for human |
| Planning-only request | "Design approach for the real-time messaging system" | Full planning output, no implementation trigger | Architectural decision document, Confirmation Gate |
| Bug fix request | "Plan how to fix the wrong message count" | Redirect: "Bug fixes use the `bug::` prefix + systematic-debugger. Planner does not investigate bugs." | Redirect message, stop |

---

### What It Does NOT Do

- **Does not write any Dart code.** Planning output is documentation only — no source file modifications.
- **Does not launch the developer agent.** The Confirmation Gate is between the plan and implementation. Launching developer is Main Claude's job after human confirms.
- **Does not skip memory retrieval.** Step 0 is mandatory on every invocation — no exceptions for "simple" features.
- **Does not propose architecture that contradicts a past decision in claude-mem or error_learnings.md.** Memory findings are applied before the first plan line is written.
- **Does not proceed past the Confirmation Gate.** Plan output ends the response. Waiting for human is the correct next state.
- **Does not invent API endpoints.** All proposed endpoints must be grounded in FR docs or existing patterns in api_registry.md. If an endpoint is unknown → flag it as requiring backend confirmation.
- **Does not plan bug fixes.** Any bug description redirected here is re-routed to the systematic-debugger.

---

### Common Mistakes — Planner

**Mistake 1: Skipping planner because FR docs exist**

**Symptom:** Developer agent starts implementation on a complex feature, hits a shared file, realizes the blast radius is much larger than expected. Work stops mid-implementation to do the analysis that should have been done before writing anything.

**Cause:** agents.md trigger table had a simple rule: "FR exists → skip planner." This is correct for simple modules but incorrect for the 5 complexity triggers.

**Fix:** Add the 5-trigger checklist to the planner decision gate in agents.md. "FR exists" is necessary but not sufficient to skip planning. All 5 triggers must be false before the developer agent launches without a plan.

---

**Mistake 2: Planner launches developer automatically after plan output**

**Symptom:** Human sees a plan appear, followed immediately by developer agent output — never had a chance to review the plan, approve it, or raise concerns.

**Cause:** Agent file was missing the Confirmation Gate, or it was present but phrased as "if human approves" (which the agent interpreted as "I'll assume approval").

**Fix:** Write the gate as: "END THE MESSAGE. WAIT. Do not launch the developer agent. Do not assume approval. The next action occurs only after the human explicitly confirms." Imperative form, not conditional.

---

**Mistake 3: Plan proposes creating something that already exists**

**Symptom:** Developer creates a second `getUserProfile()` function alongside the existing one. Two functions with different parameter shapes for the same endpoint. Callers start using one or the other inconsistently.

**Cause:** Planner skipped Step 0 (memory retrieval) or ran it but didn't grep api_registry.md for the specific function.

**Fix:** Make Step 0 results visible in the plan's "Reuse Identified" section. If this section says "none" for API functions, that is a red flag — almost every new feature reuses at least one existing endpoint. A blank reuse section warrants re-checking.

---

---

## 10.4 — Developer Agent

### Agent: developer

| Property | Value |
|----------|-------|
| **File** | `.claude/agents/developer.md` |
| **One-line role** | The sole implementation arm — it writes all code, validates all output, and documents every change |
| **Invoked by** | Main Claude (always — no manual invocation) |
| **Mode** | Foreground |
| **Session type** | Fresh each time (stateless) |
| **Input receives** | FR docs / implementation plan — OR — Handoff Brief from systematic-debugger / Correction Brief from reviewer agents |
| **Output produces** | Implemented feature files + documentation updates + pipeline status update; OR targeted fix + flutter analyze result |
| **Memory query** | Yes — claude-mem + error_learnings.md + component_registry + api_registry (every run) |
| **Does NOT do** | Investigate bugs; write FR documents; launch review agents; make architecture decisions without a plan; write a single line of code before instruction files are loaded |

**Trigger conditions (from agents.md):**
- `"develop [ModuleName]"` — full implementation, FR docs exist
- `"implement [feature]"` — full implementation, may need planner first if complex
- Any development request after planner produces an implementation plan
- Main Claude launches in Correction Pass Mode after systematic-debugger produces a confirmed Handoff Brief

**Why processed prompt, not raw prompt:**
The developer always receives enriched context — either FR file paths (for full implementation) or a confirmed Handoff Brief (for bug fixes). It has no classification gate that raw input would trigger. By the time Main Claude routes to the developer, the "what to build" question is already answered.

---

### Two Operating Modes

The developer determines its mode from the input it receives. This decision happens before any other step.

```
Input is an FR doc / implementation plan / feature description
  → MODE 1: FULL IMPLEMENTATION
    Pre-Step → Instruction Loading → Module Intake → Per-Feature Loop → Self-Validation

Input is a Handoff Brief (from systematic-debugger) or Correction Brief (from reviewer agents)
  → MODE 2: CORRECTION PASS
    Brief Verification Gate → Apply minimal fix → flutter analyze → Report
```

Never mix modes. An agent that starts implementing a new feature and also applies an unrelated bug fix in the same pass has violated scope. Mode 2 fixes the exact issue in the brief — nothing more.

---

### Mode 1: Full Implementation

#### Pre-Step — Memory and Reuse Check

This runs before any instruction file is read. It prevents re-solving known problems and prevents creating duplicates of things that already exist.

**A — Error Learnings**
Read `docs/memory/error_learnings.md`. Grep for the module name, package names you will use, and pattern types involved (e.g., `"navigation"`, `"auth"`, `"pagination"`).

If a matching entry exists → apply the documented fix or pattern directly. No investigation.

**B — Component Registry**
Grep `docs/memory/component_registry.md` for any widget related to this feature. Profile cards, loading skeletons, error states, themed buttons, badges — all of these have likely been built already.

If a matching component exists → reuse or extend it. Never create a duplicate.

**C — API Registry**
Grep `docs/memory/api_registry.md` for endpoints already available for this feature.

If the endpoint exists → use the existing implementation. Never create a parallel one.

**D — Claude-Mem Retrieval**
Search claude-mem for:
- `"[feature/module name] implementation"` — past patterns for this area
- `"[packages you will use] known issues"` — non-obvious package behaviors
- `"[similar feature] gotcha"` — edge cases from previous sessions

If a relevant result is found → apply it directly.

**E — Project Map Impact Check (only when task touches shared code)**
Read `docs/maps/project_map.md` only if the task modifies a shared entity, a route constant, a shared service, or a binding used by multiple modules. Find the entry in the Deep Change Impact Matrix and know every file affected before writing anything.

Skip this step for new features that don't touch shared files.

> **CRITICAL:** The Pre-Step is not optional. An agent that skips it and re-discovers a known mistake — a mistake documented in error_learnings.md from three sessions ago — wastes the time that was spent fixing it the first time.

---

### Gate: Instruction Loading Gate

| Property | Detail |
|----------|--------|
| **Trigger** | Always — fires before any Dart code is written |
| **Precondition** | Pre-Step is complete |
| **Runs at** | Step 0, before any screen or widget file |
| **Exit — Pass** | All three instruction files read; UI constants extracted to scratchpad; 4 pre-flight checks pass → implementation can begin |
| **Exit — Fail** | Any pre-flight check fails → stop, re-read the relevant instruction file, re-check |
| **Protects against** | Writing a screen before knowing the color system, font, locale pattern, or async state requirements — which produces compliance violations that require a full file rewrite |

**What the agent does at this gate:**

1. Read `docs/instructions/UI_INSTRUCTION.md` completely. Extract into scratchpad: every named color constant, every text style helper, the locale accessor pattern, the border radius convention, the sizing unit system.
2. Read `docs/instructions/API_INSTRUCTION.md` completely. Note the error handling pattern and response model conventions.
3. Read `docs/instructions/ARCHITECTURE.md` completely. Note layer boundaries, folder structure, and ISP rules.
4. Before writing any screen file, answer YES to all four pre-flight checks:
   - Do I know the exact color helper class and all its constants?
   - Do I know the exact font family string?
   - Do I know the locale accessor pattern?
   - Do I have all four UI states planned for this screen?

If any answer is NO → re-read the relevant file. Then continue.

**Example output when gate fails:**
The agent stops and states which pre-flight check failed. It re-reads the file and re-runs the check before proceeding. It does not proceed with a partial answer.

> **CRITICAL:** No Dart code before this gate passes. An agent that starts writing widgets while promising to "follow the rules from memory" will violate the color, font, or locale conventions — because conventions are project-specific and change over time. The only proof the rules were loaded is a clean compliance grep after each file.

---

### Per-Feature Implementation Loop

For each feature (FR file), execute in this exact order. Steps are numbered — order is not optional.

```
1.  READ   the FR file completely — business context, all UI states, edge cases
2.  CHECK  component_registry.md → reuse existing widgets
3.  CHECK  api_registry.md → reuse existing endpoints
4.  PLAN   list every file to create or modify before writing any of them
5.  BUILD  domain layer:
              → entity (immutable, with copyWith)
              → repository interface (abstract contract only)
              Write use case tests FIRST (RED) using mocktail
6.  BUILD  data layer:
              → model (DTO with fromJson/toJson and toDomain())
              → data source (API calls)
              → repository implementation
7.  BUILD  presentation layer:
              → binding
              → controller (GetxController with .obs state)
              Write controller tests alongside controller
              → screen (StatelessWidget + Obx)
              → feature-specific widgets
              Apply Widget Placement Gate before each widget
8.  UPDATE routes (app_routes.dart and app_pages.dart)
9.  RUN    UI Compliance Grep immediately after each .dart file is written
10. VALIDATE using the two-stage self-validation checklist
11. UPDATE docs/memory/component_registry.md for all new shared widgets
12. UPDATE docs/memory/api_registry.md for all new endpoints
13. UPDATE docs/FR/_pipeline_status.md → mark FR as REVIEW
14. STORE  non-obvious findings to claude-mem
15. REPORT "Feature [name] complete. Files created: [...]. Tests written: [...]."
```

---

### Gate: Widget Placement Gate

| Property | Detail |
|----------|--------|
| **Trigger** | Fires silently before every widget is written |
| **Precondition** | Instruction Loading Gate has passed |
| **Runs at** | During Step 7 (presentation layer), inline before each widget placement |
| **Exit — Pass** | All answers confirmed → write the widget |
| **Exit — Fail** | Any answer is "unsure" → stop, re-read `docs/instructions/UI_INSTRUCTION.md`, then continue |
| **Protects against** | Writing widgets with hardcoded colors, strings, fonts, or missing async state branches — which cause UI compliance violations detected in the compliance grep |

**What the agent asks silently for each widget:**

1. Does it use a color? → Must be `ColorHelper.xxx` — never `Color(0xFF...)` or `Colors.xxx`
2. Does it display text? → String must come from `locale.xxx` — never a string literal
3. Does it style text? → Must use the project's TextStyleHelper — never raw `TextStyle(...)`
4. Does it need a font? → Must be the project font — never a font from outside the design system
5. Is it on an async screen? → Must be inside one of the four UI state branches (loading / error / empty / success)

**Example trigger input:**
Agent is about to write: `Text('No matches found', style: TextStyle(color: Colors.grey))`

**Example output when gate fails:**
Agent stops. Identifies three violations: string literal, raw TextStyle, Colors.grey. Corrects to: `Text(locale.noMatchesFound, style: TextStyleHelper.secondary)`

---

### Gate: UI Compliance Grep

| Property | Detail |
|----------|--------|
| **Trigger** | Fires after every `.dart` file in the presentation layer is written |
| **Precondition** | File has been written (not before) |
| **Runs at** | Step 9, immediately after each file |
| **Exit — Pass** | All greps return empty output → proceed to next file |
| **Exit — Fail** | Any grep returns a match → stop, fix every match, re-run greps, then proceed |
| **Protects against** | Compliance violations surviving past the writing step and reaching code review, where they require a second round-trip through the quality loop |

**What the agent runs after each file:**

```bash
FILE=[path to file just written]

# 1. Hardcoded colors
grep -n "Color(0xFF\|Colors\." $FILE

# 2. Raw text styles
grep -n "TextStyle(\|fontSize:\|fontWeight: FontWeight\." $FILE

# 3. String literals in Text widgets
grep -n "Text('" $FILE
grep -n 'Text("' $FILE

# 4. Hardcoded asset paths
grep -n "assets/\|\.png'\|\.svg'\|\.jpg'" $FILE

# 5. Wrong font family
grep -n "fontFamily.*Poppins\|fontFamily.*Inter\|fontFamily.*Roboto" $FILE
```

**Example output when gate fails:**
```
UI Compliance Grep — ProfileScreen
Line 47: Text('Edit Profile', style: TextStyle(fontSize: 16))
  → Fix: Text(locale.editProfile, style: TextStyleHelper.heading)
Line 63: Container(color: Colors.white)
  → Fix: Container(color: ColorHelper.background)
Fixing now before proceeding to ProfileController.
```

"I followed the rules" is not evidence. An empty grep result is evidence.

---

### Mid-Task Checkpointing

For any task that involves four or more files, the developer writes a checkpoint line to `docs/FR/_pipeline_status.md` after completing each file:

```
[CHECKPOINT] FeatureName — ✅ feature_controller.dart | next: feature_screen.dart
[CHECKPOINT] FeatureName — ✅ feature_screen.dart | next: feature_binding.dart
```

When a feature reaches REVIEW status, all its CHECKPOINT lines are cleared.

**Why this exists:** If context runs out mid-task, the next session reads `_pipeline_status.md` and resumes exactly where work stopped. No repeated research. No re-reading completed files. Without checkpoints, a five-file task interrupted at file three means the next session starts from scratch, re-reading the FR, re-planning, and potentially re-writing files already completed.

---

### Two-Stage Self-Validation

The developer does not mark any feature as REVIEW until both stages pass. These are not optional.

**Stage 1 — Spec Compliance Gate (always runs first)**

```
[ ] Every line of code traces back to the FR requirements?
[ ] No unrequested features added?
[ ] No assumptions made about business logic beyond the FR?
[ ] Implementation scope matches the FR exactly — nothing more, nothing less?
```

If any box is unchecked → revert those additions immediately. Do not proceed to Stage 2.

**Why Stage 1 runs before Stage 2:** Code quality review on out-of-scope code is wasted effort. If Stage 1 fails, some of the code being reviewed doesn't belong in the codebase at all.

**Stage 2 — Code Quality Gate (only after Stage 1 passes)**

Run both instruction file checklists (UI_INSTRUCTION.md and API_INSTRUCTION.md). Then confirm:

```
[ ] component_registry.md updated with all new shared widgets
[ ] api_registry.md updated with all new endpoints
[ ] _pipeline_status.md updated to REVIEW
[ ] Every async screen has all four UI states (loading, error, empty, success)
[ ] Error state has a retry action
[ ] Empty state has a descriptive message
[ ] Loading state uses shimmer only on initial load / retry / reload
```

All boxes checked → mark REVIEW and report to Main Claude.

---

### Mode 2: Correction Pass

The developer enters Correction Pass Mode when launched with either:
- A **Handoff Brief** from systematic-debugger (confirmed bug fix)
- A **Correction Brief** from ui-reviewer, code-reviewer, or security-reviewer

In both cases: apply only what the brief specifies. No scope expansion. No opportunistic refactoring.

#### Gate: Brief Verification Gate

This gate runs before any code change in Correction Pass Mode.

| Property | Detail |
|----------|--------|
| **Trigger** | Always — fires before any code is written in Correction Pass Mode |
| **Precondition** | A Handoff Brief or Correction Brief has been received |
| **Runs at** | First step of Mode 2, before reading any source file |
| **Exit — Pass** | Every function, model, class, and endpoint named in the brief is verified to exist in the codebase → proceed with fix |
| **Exit — Fail** | Any named item does not exist → stop immediately, output `⚠️ Brief Verification Failed`, ask human |
| **Protects against** | Applying a fix that references invented function names, fabricated model classes, or non-existent endpoints — which creates two problems instead of one |

**What the agent does at this gate:**

For every function, model, class, and endpoint the brief mentions:
```bash
# Confirm function exists
grep -rn "functionName" lib/

# Confirm model/class exists
grep -rn "ClassName" lib/

# Confirm endpoint string appears in API layer
grep -rn "endpoint-string" lib/
```

If anything is not found:
```
⚠️ Brief Verification Failed

The brief references [item] but it does not exist in the codebase.
Brief says: "[exact claim]"
Reality: Not found in [searched location]

Options:
1. Tell me the correct existing item to use instead
2. Confirm this needs to be created (describe the API contract)
3. Re-run systematic-debugger with corrected information
```

The agent does NOT create the missing item. It does NOT guess what it should look like. It stops and asks.

**Why this gate exists:** A Handoff Brief can contain fabricated names if the systematic-debugger's investigation was bypassed or poorly evidenced. This gate catches the fabrication before any code is modified. A brief that invents a function name is WORSE than no brief — the developer builds against something that doesn't exist, creating two problems.

---

### Correction Rules (Both Sub-modes)

- Apply only the fix described in the brief — one change at a time
- Never bundle unrelated fixes in the same pass
- Run `flutter analyze` after every fix — the changed file must be clean
- For Tier 1 (widget/text fix): output the Tier 1 Summary format, no code-reviewer
- For Tier 2+ (logic/state/data): report to Main Claude, which launches the appropriate reviewer

**Tier 1 Summary format (developer outputs — no separate agent needed):**
```
✅ Fix applied
File:   lib/src/features/[module]/presentation/[screen].dart (line [N])
Change: [what changed — one line]
flutter analyze: clean
```

---

### Documentation Updates (Mandatory — Not Optional)

After each feature reaches REVIEW:

1. `docs/memory/component_registry.md` — register every new shared widget with: file path, purpose, configurable params, which features use it
2. `docs/memory/api_registry.md` — register every new endpoint with: function name, HTTP method, endpoint path, request shape, response model
3. `docs/FR/_pipeline_status.md` — mark FR as REVIEW, clear CHECKPOINT lines
4. `docs/memory/error_learnings.md` — add entry for any non-obvious issue encountered and solved
5. claude-mem — store: non-obvious package behaviors, architecture decisions, patterns future sessions should know

These updates are not post-implementation housekeeping. They are what prevents the next feature from duplicating the work just done.

---

### What the Developer Agent Does NOT Do

- Write a single line of code before the Instruction Loading Gate passes
- Skip the Widget Placement Gate ("I'll check compliance at the end")
- Skip the UI Compliance Grep ("I'm sure the file is clean")
- Launch review agents — Main Claude owns the Quality Loop
- Investigate bugs — that is systematic-debugger's role
- Write FR documents — that is fr-analyst's role
- Make architecture decisions without a plan — that is planner's role
- Create items referenced in a brief that don't exist in the codebase
- Touch `android/` or `ios/` folders under any circumstances
- Bundle unrelated fixes in a Correction Pass

---

### Case Scenarios

| Input type | Example | Mode | Agent behavior | Output |
|------------|---------|------|----------------|--------|
| Feature with existing FR and plan | `"develop ProfileModule"` | Full Implementation | Pre-Step → Load instructions → Module Intake → Implementation Loop | Implemented files, updated registries, REVIEW status |
| Feature without a plan, >3 files | `"implement notification system"` | Main Claude blocks — planner runs first | Main Claude checks for FR plan, none found, launches planner, then developer | Developer receives plan; begins implementation |
| Bug fix — Tier 1 (widget change) | Handoff Brief: "maxLength missing on input field" | Correction Pass | Brief Verification Gate → apply one-line fix → flutter analyze | Tier 1 Summary: file:line, change, clean analyze |
| Bug fix — Tier 2 (state logic) | Handoff Brief: "controller not clearing list on refresh" | Correction Pass | Brief Verification Gate → targeted fix → flutter analyze → report | Report to Main Claude; targeted code-reviewer launched |
| Correction brief from ui-reviewer | "Error state missing retry button on ProfileScreen" | Correction Pass | Fix only the listed item → re-run compliance grep → report | "Corrections applied. Ready for re-review." |
| Brief names non-existent function | Handoff Brief references `getLatestProfiles()` | Correction Pass — STOP | Brief Verification Gate fires → function not found in codebase | `⚠️ Brief Verification Failed` with options |
| Scope creep during implementation | Agent about to add an unrequested animation | Full Implementation | Stage 1 self-validation catches it → reverts the addition | Spec-compliant output only |
| Large task mid-session (4+ files, context near limit) | 6-file feature, context at 75% | Full Implementation | Writes checkpoint after each file → stops cleanly if context runs out | Checkpoint in pipeline_status; next session resumes from checkpoint |

---

### Common Mistakes

**Mistake 1: Developer launched without an implementation plan for a complex feature**

**Symptom:** Developer produces a folder structure that differs from the project's existing pattern. Module A uses a different file layout than Module B. Code review finds architectural violations.

**Cause:** Main Claude skipped the planner check and launched the developer directly for a feature that touches more than three files or crosses module boundaries.

**Fix:** In agents.md, the trigger check is explicit: if feature is complex AND no `*_Implementation_Tasks.md` exists in `docs/FR/` → launch planner first. Developer receives the plan as input. Only then can it execute consistently.

---

**Mistake 2: Instruction Loading Gate skipped because the developer "already knows the rules"**

**Symptom:** UI compliance greps find Color(0xFF...) violations after the file is written. Code review round-trip needed. The developer agent produced output that required a correction pass to fix compliance violations it should have prevented.

**Cause:** The developer agent started writing widgets without extracting the color constants from `ColorHelper` into its scratchpad. Rules were applied from a generic understanding, not from the actual constants in the project.

**Fix:** The Instruction Loading Gate is not a "read this if you're unsure" step. It is a blocker. No widget is written before the pre-flight check passes. The four pre-flight checks are binary: either the exact constant name is in the scratchpad or it isn't.

---

**Mistake 3: Correction Pass adds unrequested changes**

**Symptom:** A bug fix that was supposed to change one line touches three files and refactors two methods. Code reviewer finds changes outside the brief's scope. The original bug is fixed but two new regressions are introduced.

**Cause:** The developer noticed related issues while applying the fix and "improved" them while in the file. Good intent, bad outcome.

**Fix:** Correction Pass Mode has a single rule: apply only what the brief specifies. Every file touched beyond the brief's scope is a scope violation. Noticed improvements go in a new feature request, not the current correction pass.

---

**Mistake 4: Mid-task checkpoints skipped on a large feature**

**Symptom:** Context runs out mid-feature at file 4 of 6. The next session re-reads the FR, re-plans, and re-writes files 1–3 that were already correct. Two hours of work duplicated.

**Cause:** Developer skipped the checkpointing step because the task "seemed manageable."

**Fix:** The 4-file threshold is the trigger — it is not negotiable. After each completed file in any task with four or more files, append the CHECKPOINT line to `_pipeline_status.md`. The cost is five seconds. The recovery cost without checkpoints is measured in re-work.

---

**Mistake 5: Both self-validation stages run in the wrong order**

**Symptom:** Code reviewer flags that the implementation added an unrequested feature. The developer then re-implements. Two code review passes wasted on code that shouldn't exist.

**Cause:** Stage 2 (code quality) ran without Stage 1 (spec compliance) passing first. The code was clean but out of scope.

**Fix:** Stage 1 is not a formality. Run it first, every time. Only after "every line traces back to the FR" passes does it make sense to run the code quality checklist.

---

## [Flutter-GetX Specifics] — Developer Agent

The developer agent as described above is generic. When using GetX + feature-first Clean Architecture, these additional conventions apply. They are enforced by the Widget Placement Gate, the UI Compliance Grep, and the self-validation checklist.

---

### GetX-Specific Pre-Step Additions

Before Step 0, check claude-mem for:
- `"GetX [pattern]"` — known GetX pitfalls (permanent controllers, RxList mutation)
- `"socket_io_client issues"` — if the feature involves real-time events
- `"Hive [box name]"` — if the feature reads or writes local storage

These queries are in addition to the generic pre-step queries. GetX has enough non-obvious behaviors that past sessions reliably surface useful context.

---

### GetX Implementation Order (Step 5–7 in the Loop)

The domain → data → presentation order is mandatory and identical to the generic version. GetX adds specific file types at each layer:

```
Domain layer:
  lib/src/features/[feature]/domain/entities/[Feature]Entity.dart  (immutable, @immutable, copyWith)
  lib/src/features/[feature]/domain/repositories/I[Feature]Repository.dart  (abstract)
  lib/src/features/[feature]/domain/use_cases/[Action][Feature]UseCase.dart  (one use case = one action)

Data layer:
  lib/src/features/[feature]/data/models/[Feature]Model.dart  (DTO: fromJson/toJson + toDomain())
  lib/src/features/[feature]/data/data_sources/[Feature]RemoteDataSource.dart
  lib/src/features/[feature]/data/repositories/[Feature]RepositoryImpl.dart

Presentation layer:
  lib/src/features/[feature]/presentation/bindings/[Feature]Binding.dart
  lib/src/features/[feature]/presentation/controllers/[Feature]Controller.dart  (GetxController)
  lib/src/features/[feature]/presentation/screens/[Feature]Screen.dart  (StatelessWidget + Obx)
  lib/src/features/[feature]/presentation/widgets/  (feature-specific widgets)
```

---

### Widget Placement Gate — GetX Additions

The generic gate checks color, text, font, and async states. For GetX projects, add:

6. Does it read a `.obs` variable? → Must be inside `Obx(() => ...)` — never read outside Obx
7. Does it navigate? → Must use `Get.toNamed(Routes.xxx)` — never `Navigator.pushNamed`
8. Is it a screen that loads data on init? → Controller must have `isLoading`, `hasError`, `errorMessage` observables

---

### GetX Controller Conventions

**Permanent vs. non-permanent controllers — critical distinction:**

| Controller type | Registration | Why |
|----------------|--------------|-----|
| IndexedStack tab controllers (HomeController, DiscoverController, etc.) | `Get.put(..., permanent: true)` | Never popped — GetX must not auto-dispose |
| Push-and-pop route controllers (ProfileDetailController, ChatRoomController) | `Get.put(...)` (non-permanent) | Disposed when route is popped — correct behavior |

> **CRITICAL:** An IndexedStack tab controller registered without `permanent: true` will be auto-disposed when the user navigates to another tab. State is lost. Re-entering the tab creates a new controller with blank state. This is the most common GetX lifecycle bug.

**RxList mutation — full replacement:**
```dart
// WRONG — replaces the reference, Obx does not react
items = newList;

// CORRECT — mutates in place, Obx reacts
items.assignAll(newList);
```

**One use case = one action:**
```dart
// WRONG — one use case handles multiple operations
class AuthUseCase { login(); register(); logout(); }

// CORRECT — one file, one action
class LoginUseCase { Future<UserEntity> execute(LoginParams params); }
class RegisterUseCase { Future<UserEntity> execute(RegisterParams params); }
class LogoutUseCase { Future<void> execute(); }
```

---

### UI Compliance Grep — GetX Additions

In addition to the five generic greps, run after every GetX screen/controller file:

```bash
# 6. Obs variable read outside Obx
grep -n "controller\.[a-z].*\.value\b" $FILE  # catches .obs reads outside Obx

# 7. Hardcoded route strings
grep -n "Get\.toNamed(['\"]" $FILE  # should use Routes.xxx constants

# 8. setState usage (forbidden in GetX)
grep -n "setState(" $FILE
```

---

### Self-Validation — GetX Stage 2 Additions

After the generic Stage 2 checklist, confirm:

```
[ ] Every .obs variable read is inside Obx(() => ...)
[ ] All routes use Routes.xxx constants — no string literals in Get.toNamed()
[ ] IndexedStack tab controllers use Get.put(..., permanent: true)
[ ] Push-and-pop controllers do NOT use permanent: true
[ ] RxList full replacement uses .assignAll(), not direct assignment
[ ] Controller uses one use case per action (no multi-action use cases)
[ ] Binding registers the controller — screen does not instantiate it directly
[ ] No setState() calls in any StatelessWidget
```

---

### Correction Pass — GetX-Specific Brief Verification

For GetX projects, the Brief Verification Gate adds:

```bash
# Confirm controller binding exists
grep -rn "ControllerName" lib/src/features/[feature]/presentation/bindings/

# Confirm route constant exists
grep -n "Routes.[FEATURE]" lib/src/core/routes/app_routes.dart

# Confirm use case is registered
grep -n "UseCase" lib/src/features/[feature]/presentation/bindings/[Feature]Binding.dart
```

A brief that says "fix the DiscoverController" when no DiscoverBinding exists should trigger the Brief Verification Gate — the fix cannot be applied correctly without knowing where the controller is registered.

---

## 10.5 — UI-Design Enforcer Agent

### Agent: ui-design-enforcer

| Property | Value |
|----------|-------|
| **File** | `.claude/agents/ui-design-enforcer.md` |
| **One-line role** | A mandatory pre-implementation design thinking session — forces intent commitment before the first widget is written |
| **Invoked by** | Main Claude — automatically, before developer agent, whenever new screens are involved |
| **Mode** | Foreground |
| **Session type** | Fresh each time (stateless) |
| **Input receives** | Development request describing the screen(s) to build |
| **Output produces** | A Design Brief (when answers are clear) OR a blocked clarification request (when they are not) |
| **Memory query** | Yes — reads `docs/instructions/UI_INSTRUCTION.md` and `docs/memory/component_registry.md` before asking any question |
| **Does NOT do** | Write Dart code; run after a screen is already built; accept vague answers; produce pixel-perfect specs; run for bug fixes or logic-only changes |

**Trigger conditions (from agents.md):**
- `"develop [ModuleName]"` where the module includes new screen(s)
- `"implement [feature]"` where the feature includes a new screen

**Does NOT trigger for:**
- Bug fixes (including visual bugs — systematic-debugger owns those)
- Logic-only changes with no new screens
- Existing screen modifications
- API integration work with no new UI

**Why raw-ish prompt, not heavily processed:**
The agent's first step is reading project context for itself. Main Claude passes the screen name and feature description — enough to orient the agent. The agent reads UI_INSTRUCTION.md and component_registry.md directly rather than receiving a summary.

---

### The Core Problem This Agent Solves

A developer asked to "implement a notifications screen" will write a notifications screen. It will compile. It will function. It will look like a default Flutter app.

Not because the developer is bad — but because the developer's job is to implement intent, not invent it. Without a design brief, every layout decision (card shape, information hierarchy, loading skeleton, empty state illustration, animation timing) gets made implicitly, at coding time, in isolation. Those decisions cannot be reviewed against a standard because there was no standard.

```
BEFORE ui-design-enforcer:
  User: "implement notifications screen"
        ↓
  Developer agent writes screen
        ↓
  ui-reviewer: "this looks generic — the shimmer doesn't match the card layout,
               the empty state has no CTA, animations missing"
        ↓
  Developer rewrites widget tree
        ↓
  Two quality loop passes wasted
```

```
AFTER ui-design-enforcer:
  User: "implement notifications screen"
        ↓
  ui-design-enforcer: reads context, answers 4 questions, outputs Design Brief
        ↓
  Developer agent implements from Design Brief
        ↓
  ui-reviewer: confirms implementation matches intent
        ↓
  One quality loop pass
```

The shift is moving design decisions from implicit (at code-writing time) to explicit (at brief-writing time). Explicit decisions can be reviewed, corrected, and improved without touching a line of code.

---

### Step 1 — Read Project Context First

Before answering any question or forming any opinion, the agent reads:

1. `docs/instructions/UI_INSTRUCTION.md` — the project's color palette, typography system, component conventions, animation standards
2. `docs/memory/component_registry.md` — existing shared components that might apply to this screen

Optionally, if the feature has an adjacent existing screen of similar type, the agent greps that file to understand what layout patterns the project already uses.

**Why read before asking:**
An agent that proposes a layout without knowing that the project already has a matching card component will invent a new one. The component_registry exists precisely to prevent this. The agent reads it so the Design Brief can say "use the existing `ItemCard` component" rather than "build a new card with these properties."

---

### The 4 Design Thinking Questions

These are answered internally by the agent based on the feature description and project context — not asked out loud to the user one by one. The agent produces answers from the information it has. If information is missing, that is when it blocks (see Gate below).

**Question 1 — Purpose and User State**

What problem does this screen solve for the user? What is the user's emotional or task state when they arrive here?

This is not a technical question. It determines the visual weight, density, and energy level of the screen.

- A user arriving at a checkout confirmation screen is focused and slightly anxious — clarity and trust signals matter more than visual flair.
- A user arriving at a match celebration screen is excited — the screen should feel celebratory.
- A user filling a long settings form is in task mode — minimal distractions, clear field grouping.

The answer becomes one sentence in the Design Brief: "User is [state] here. Screen must feel [adjective]."

**Question 2 — Tone Commitment**

Pick one and commit. No "balanced" or "it depends":

| Tone | Feel | Typical use |
|------|------|-------------|
| Premium / refined | Deliberate, quality-signaling | Profile showcase, subscription, premium features |
| Energetic / playful | Celebratory, forward-moving | Achievement moments, gamified interactions |
| Intimate / warm | Personal, readable, unhurried | Conversations, deepdive views, personal history |
| Minimal / focused | Nothing distracts from the action | Multi-step forms, onboarding, decision confirmations |
| Data-dense / efficient | Administrative, scan-optimized | List management, monitoring, multi-item comparison |

The tone determines typography weight, animation style (spring vs ease-out), color temperature, and spacing density.

**Question 3 — The One Differentiator**

What is the one thing a user will remember about this screen?

If the agent cannot name one memorable element, the design is not distinct enough. Push until the differentiator is named:

- "The shimmer skeleton perfectly mirrors the card layout — instant recognition of what's loading"
- "The error state has an illustration, not just a retry button"
- "The empty state has a direct CTA that takes the user to the action that would fill it"

A generic answer ("it shows a list of notifications") means generic implementation. The differentiator forces specificity.

**Question 4 — Constraints Check**

Before any brief is written, confirm project constraints are planned for:

```
[ ] Color system: will use the project's named color constants, not raw hex
[ ] Typography: will use the project's text style helpers, not raw TextStyle
[ ] Strings: will use the project's locale keys, not string literals
[ ] Font: will use the project-specified font only
[ ] Animations required: screen entry, button press, key interactions
[ ] 4 UI states planned: Loading (shimmer) / Error (+ retry) / Empty (+ CTA) / Success
```

All six must be planned before the brief is issued. These are not code-level details — they are design constraints that determine what the developer is allowed to write.

---

### Gate: Design Brief Gate

| Property | Detail |
|----------|--------|
| **Trigger** | After all 4 questions are answered internally |
| **Precondition** | Project context has been read (Step 1 complete) |
| **Runs at** | After the 4-question session, before any output |
| **Exit — Pass** | All 4 questions answered non-vaguely → output Design Brief |
| **Exit — Fail** | Any question answered vaguely or left unanswered → output clarification request, block implementation |
| **Protects against** | A vague Design Brief reaching the developer — which is WORSE than no brief, because it gives the developer false confidence that design decisions were made |

**What "vague" means:**
- Q1 vague: "user wants to see notifications" (no emotional state, no screen feel)
- Q2 vague: "balanced mix of minimal and playful" (not a commitment)
- Q3 vague: "it's a standard list screen" (not a differentiator)
- Q4 vague: skipped entirely (constraints unchecked)

**When the gate fails:**
```
⏸️ Design Brief Blocked — [ScreenName]

Before implementation starts, re-answer:
Q2: The tone choice "it depends on the user" is not a commitment.
    Pick exactly one from the tone table: Premium / Energetic / Intimate / Minimal / Data-dense.
    State why that tone fits this screen's user state.
```

The agent does not guess. It does not pick a tone on the user's behalf. It blocks and asks.

**Example Design Brief output when gate passes:**

```
DESIGN BRIEF — NotificationsScreen

Purpose: User is checking what happened while away — expectant, scanning quickly.
         Screen must feel clear and easy to process.

Tone: Minimal/focused — notifications are information delivery, not a destination.
      No decorative elements that slow scanning.

Differentiator: Unread notifications have a left accent border in the primary color —
               the visual separation requires zero reading to distinguish read from unread.

Constraints: confirmed
  (color constants, text style helpers, locale keys, project font, 4 UI states)

Animation plan:
- Entry: fade-in 180ms with 8dp slide-up
- List items: staggered fade-in 40ms apart (first 5 items only)
- Mark-as-read: accent border fades out with 150ms ease-out
- Loading: shimmer matching notification row layout (avatar circle + two text lines)

4 UI States:
- Loading: shimmer skeleton — row of circle + two lines per item, 4 rows
- Error: icon + "Could not load notifications" + "Try again" button
- Empty: icon + "You're all caught up" + no CTA (nothing to do when empty)
- Success: list of notification rows, unread with accent border

Reuse candidates:
- Check component_registry for existing list item shimmer

Hand off to developer agent. Implementation may begin.
```

---

### What Happens After the Design Brief

The Design Brief is the handoff document from ui-design-enforcer to developer agent. Main Claude passes it as part of the developer agent's launch prompt.

The developer agent implements from the brief. Every layout decision in the brief is a constraint — not a suggestion. The developer does not make layout decisions beyond what the brief specifies.

The ui-reviewer agent (which runs after implementation) checks the screen against the brief. If the implementation diverges from the brief without justification, ui-reviewer flags it.

```
ui-design-enforcer → Design Brief → developer agent → implementation → ui-reviewer
                                                                            ↑
                                             checks implementation against the Brief
```

---

### Case Scenarios

| Input | Screen type | Gate result | Output |
|-------|-------------|-------------|--------|
| "implement a profile edit screen" | Form screen | Pass | Design Brief with field grouping, section headers, sticky submit, 4 states |
| "implement a match list screen" | List screen | Pass | Design Brief with card layout, status indicators, empty state CTA |
| "develop the notifications module" — FR exists | List screen | Pass | Design Brief referencing component_registry for reuse candidates |
| Screen description is "show user a list" | Any | Fail | Blocked: Q3 unanswered — no differentiator identified |
| "fix the profile screen layout" | Existing screen | Does not trigger | ui-design-enforcer only runs for new screens |
| `"bug:: profile image not loading"` | Existing screen | Does not trigger | Bug fix — systematic-debugger handles this |
| Design request with a provided mockup | Any | Pass | Brief uses mockup as ground truth; flags any missing states not in mockup |
| Screen with no async data (static content only) | Any | Pass | Brief notes "4 UI states: loading and error not applicable — content is static" |

---

### Common Mistakes

**Mistake 1: ui-design-enforcer runs after the screen is already built**

**Symptom:** ui-reviewer flags the screen. Developer rewrites the widget tree. Two passes through the quality loop. The ui-design-enforcer's output arrives as a retrospective critique rather than a pre-implementation brief.

**Cause:** In agents.md, the trigger was registered under "post-implementation" or was missing entirely. Developer agent was launched directly.

**Fix:** In agents.md, the trigger table for development requests must have `ui-design-enforcer` as Step 1, before `developer`. The development request flow is: `ui-design-enforcer → developer → ui-reviewer`. Not the reverse.

---

**Mistake 2: Vague answers accepted and brief issued anyway**

**Symptom:** Developer receives a brief that says "show a standard list of items with a nice design." Developer makes layout decisions. ui-reviewer flags them. Developer rewrites. False confidence was given by the brief — the brief existed but communicated nothing.

**Cause:** The Design Brief Gate threshold was too low. The agent issued a brief when Q3 (differentiator) was generic.

**Fix:** Tighten the gate's definition of "specific enough." The test is: "Could the developer write this screen without making a single unspecified layout decision?" If any decision would have to be invented, the brief is not specific enough.

---

**Mistake 3: Agent triggers for bug fixes**

**Symptom:** A bug report (`bug:: the profile image shows a broken icon`) triggers ui-design-enforcer. It outputs a Design Brief for a screen that already exists. Developer is confused about which screen to re-implement.

**Cause:** The trigger condition in agents.md matched on "profile" or "screen" without checking whether the request is a bug fix.

**Fix:** The trigger condition must check for the `bug::` / `issue::` prefix first. Bug triggers always go to systematic-debugger. ui-design-enforcer only fires on development requests (`develop`, `implement`, `build`) that include new screens.

---

**Mistake 4: Agent skips Step 1 (context reading) and invents reuse candidates**

**Symptom:** Design Brief says "build a new notification card component." component_registry.md already has `ItemNotificationCard` with identical requirements. Developer builds a duplicate.

**Cause:** Agent answered the 4 questions without reading component_registry.md. It proposed creating something that already exists.

**Fix:** Reading `docs/memory/component_registry.md` is not optional — it is Step 1, before any question is answered. The Brief's "Reuse candidates" section must reference the registry, not general intuition.

---

## [Flutter-GetX Specifics] — UI-Design Enforcer Agent

The ui-design-enforcer agent as described above is generic. When using GetX + feature-first Clean Architecture, these additions apply.

---

### Question 4 — GetX Constraint Extensions

The generic constraints check covers color, typography, locale, font, animations, and 4 UI states. For GetX projects, the constraint confirmation also covers:

```
[ ] Controller state plan: isLoading, hasError, errorMessage, isEmpty observables identified
[ ] Obx wrap plan: which parts of the screen are inside Obx() — list, error, loading indicator
[ ] Route name identified: Routes.FEATURE_NAME exists or must be added
[ ] Binding identified: FeatureBinding.dart is in scope for this screen
```

These are not implementation details — they are design decisions that determine the screen's state management shape. A Design Brief that specifies "loading state uses shimmer" but does not note "isLoading: RxBool in FeatureController" leaves the developer to decide the observable name. Different sessions produce different names. Cross-screen references break.

---

### GetX-Aware Design Brief Fields

The Design Brief output for a GetX project includes two additional sections:

```
Controller state:
- isLoading: RxBool — drives shimmer vs content toggle
- hasError: RxBool + errorMessage: RxString — drives error state
- items: RxList<FeatureEntity> — drives list content
- (add any screen-specific state: selectedTab, isFiltered, etc.)

Reactive scope (Obx wrap plan):
- Entire list area: inside Obx()
- Loading overlay: inside Obx() — separate from list
- Error message: inside Obx()
- Success content: inside Obx()
- Static header / navigation bar: outside Obx() (not reactive)
```

This tells the developer exactly where `Obx()` boundaries go before they open the file. Obx boundary decisions made at coding time often end up too broad (wrapping the entire screen) or too narrow (missing reactive fields). The brief specifies them explicitly.

---

### Cross-Screen Events in the Brief (GetX-specific)

If the feature being designed fires or listens to events from other screens, the Design Brief must name the event:

```
Cross-screen events:
- This screen fires: onMatchAccepted (consumed by DiscoverController, BadgeController)
- This screen listens for: onProfileUpdated (fired by ProfileEditController)
```

These names are agreements. If ui-design-enforcer defines them in the brief and the developer implements them, the sender and receiver match. If the developer names them independently, they mismatch — a class of bug invisible until integration testing.

> **NOTE:** Cross-screen event naming is only required when the feature spec explicitly mentions state changes that affect other screens. Single-screen features do not need this section.

---

## 10.6 — Loop Operator Agent

### Agent: loop-operator

| Property | Value |
|----------|-------|
| **File** | `.claude/agents/loop-operator.md` |
| **One-line role** | The safety net for autonomous pipelines — distinguishes intentional pauses from true stalls, and applies the minimum intervention to unblock |
| **Invoked by** | Main Claude when a loop or pipeline appears stuck; also invoked directly by the user |
| **Mode** | Foreground |
| **Session type** | Fresh each time (stateless) |
| **Input receives** | Symptom description, agent ID, or "the loop seems stuck" — any signal that a pipeline is not advancing |
| **Output produces** | Diagnosis (WAIT or STALL), minimum intervention applied, current pipeline status; OR escalation to human when intervention would require judgment |
| **Memory query** | No — this agent reads the current loop state from pipeline_status.md and recent agent output, not from historical memory |
| **Does NOT do** | Write production code; make architectural decisions; override Confirmation Gates or DATA GATEs; restart a pipeline from scratch; increase correction pass limits beyond their documented maximums |

**Trigger conditions (from agents.md):**
- "the agent seems stuck"
- "nothing is happening"
- "the loop has been running for [X] minutes"
- Main Claude detects an agent has produced identical output twice, or a phase transition has not happened within expected time
- Correction loop has exceeded its maximum passes (ui-reviewer > 2, code-reviewer > 1)

**Does NOT trigger for:**
- An agent taking a long time on a legitimate complex task
- A Confirmation Gate waiting for human approval (correct behavior, not a stall)
- An agent that escalated to human (also correct behavior)

**Why foreground:**
The loop-operator's output — WAIT vs. STALL diagnosis — determines what Main Claude does next. Background mode would deliver the diagnosis after Main Claude has already acted on an assumption.

---

### The Central Judgment: STALL vs. WAIT

This is the most important decision the loop-operator makes. Getting it wrong in either direction is expensive:

- Diagnosing a WAIT as a STALL and intervening → double work, lost agent context, broken pipeline state
- Diagnosing a STALL as a WAIT and not intervening → loop runs forever, tokens wasted, session stalls

```
WAIT — agent is correctly paused, waiting for something external:
  "Waiting for human confirmation before proceeding"   → Confirmation Gate
  "Please share the console log output"                → DATA GATE (systematic-debugger)
  "Answer these to unblock the Design Brief"           → ui-design-enforcer block
  "Decision needed: [description]"                     → planner escalation
  "Escalating — pass 2 corrections still failing"      → ui-reviewer escalation

STALL — agent is stuck, cannot progress without external intervention:
  Same tool call repeated 3+ times with identical parameters
  Agent produced identical output twice in a row
  Agent said "complete" but next pipeline phase never started
  Agent is reading files in a loop without producing analysis
  Correction loop exceeded its maximum pass count
  Agent is re-asking questions it already answered (context lost)
  Every fix creates a new error of the same type (fix-loop)
```

**If WAIT:** Tell the human what the agent is waiting for and what action to take. Do not intervene.

**If STALL:** Classify the stall type and apply the minimum intervention.

---

### Gate: Stall Classification Gate

| Property | Detail |
|----------|--------|
| **Trigger** | After STALL is confirmed (WAIT ruled out) |
| **Precondition** | Loop-operator has read the agent's last output |
| **Runs at** | Step 2 of the internal flow |
| **Exit — Pass** | Stall type identified → select and apply minimum intervention |
| **Exit — Fail** | Cannot determine stall type from available information → ask human for more context (last agent message, when it last produced output) |
| **Protects against** | Applying the wrong intervention — which can make the stall worse or destroy work in progress |

| Stall type | Description | Common cause |
|------------|-------------|--------------|
| Cycle stall | Agent outputs same content repeatedly | Agent doesn't know previous output was delivered |
| Tool loop stall | Same tool call repeated with same parameters | Dependency not resolved; agent expects different result |
| Handoff stall | Agent marked complete but next phase never started | Main Claude didn't receive or act on completion signal |
| Scan stall | Agent reading files with no analysis output | Too many files; no stopping condition defined |
| Pass-limit stall | Correction loop exceeded maximum passes | ui-reviewer > 2, code-reviewer > 1 |
| Context loss stall | Agent re-asks questions it already answered | Context window exhausted; earlier conversation lost |
| Fix-loop stall | Every fix creates a new error of the same type | Agent patching symptoms, root cause unaddressed |

---

### Minimum Intervention per Stall Type

The principle: do the smallest thing that unblocks the loop. Do not restructure, restart, or take over.

**Cycle stall:**
Send a context anchor to the stalled agent:
```
"Your previous output was received. Do NOT regenerate it.
 Continue from: [next step in the flow]"
```

**Tool loop stall:**
Break the dependency the tool call is trying to resolve. If the tool is searching for a file that doesn't exist — create the stub. If a grep returns zero results — provide the answer directly instead of letting the agent loop on the search.

**Handoff stall:**
Read the previous agent's output. Identify the next agent that should have been triggered. Launch it manually with the completion report as its input context.

**Scan stall:**
Scope the scan with a SendMessage:
```
"Do not scan the entire project. Scope to: lib/src/features/[module]/ only.
 If more files are needed, ask before scanning further."
```

**Pass-limit stall:**
Block the additional pass. Escalate to human with the list of remaining issues. Do not run a third pass. The 2-pass limit exists because issues that survive two correction rounds require human judgment, not another automated pass.

**Context loss stall:**
Provide a context summary:
```
"Context summary: You have already completed [X], decided [Y], found [Z].
 Continue from: [next step]"
```

**Fix-loop stall:**
Identify the root issue the agent is patching around. Read the last three fix attempts, find the common pattern, and either provide the root-cause fix direction directly or escalate to human if it requires architectural judgment.

---

### What the Loop Operator Never Does as an Intervention

These are hard prohibitions — not guidelines:

```
❌ Override a Confirmation Gate — human approval cannot be bypassed
❌ Override the DATA GATE — systematic-debugger needs the console log, not a workaround
❌ Write production code to unblock a stalled developer
❌ Restart the entire pipeline (destroys all completed phases)
❌ Delete a stalled agent's output and redo it
❌ Increase the correction pass limit beyond its maximum
❌ Make architectural decisions when a planner is stalled on one
```

The moment the loop-operator starts doing any of these, it has taken over the task rather than unblocking it. That is the wrong role.

---

### Verification After Intervention

After applying an intervention:

```
[ ] Did the agent produce new output (different from the stall output)?
[ ] Did the pipeline advance to the next phase?
[ ] Is the new output making progress toward the goal?
```

If all three: intervention succeeded. Report outcome.

If any fail: one more intervention attempt with a different approach.

After two failed interventions → escalate to human:

```
⛔ Loop Operator — Escalating to Human

Stall type: [type]
Interventions attempted:
  1. [what was tried] — result: [what happened]
  2. [what was tried] — result: [what happened]

Why it's still stuck: [honest assessment]

What the human should do: [specific action — not "try again"]
```

---

### Monitoring the Quality Loop Pipeline

When Main Claude requests pipeline health status, the loop-operator reads `docs/FR/_pipeline_status.md` and any recent agent output to report:

```
Phase 1 (ui-reviewer):        ✅ COMPLETE
Phase 2 (code-reviewer):      🔄 IN_PROGRESS
Phase 3 (security-reviewer):  ⏳ WAITING
Phase 4a (doc-updater):       ⏳ WAITING
Phase 4b (project-map):       ⏳ WAITING
```

Expected phase transitions happen in sequence. If a phase stays `IN_PROGRESS` for longer than its expected duration (ui-reviewer: ~2-3 minutes for 2 screens; code-reviewer: ~2-3 minutes for 5 files) without output, it becomes a stall candidate.

---

### Case Scenarios

| Symptom reported | Diagnosis | Action | Output |
|-----------------|-----------|--------|--------|
| "Agent seems stuck" — last message is "Please share the console log" | WAIT | No intervention | "Not a stall — systematic-debugger hit the DATA GATE. Share the console log to unblock." |
| "Nothing is happening" — agent asked a question 10 minutes ago | WAIT | No intervention | "The agent is waiting for your answer to: [question]. Reply to unblock." |
| ui-reviewer on pass 3 | Pass-limit stall | Block pass 3, escalate | List remaining issues; explain human judgment required |
| Developer agent produced same output twice | Cycle stall | Context anchor message | "Output received. Continue from step [N]." |
| Quality loop Phase 2 never started after Phase 1 completed | Handoff stall | Launch code-reviewer manually | "Phase transition missed. Launched code-reviewer with ui-reviewer output." |
| Agent reading 50 files, no output for 5 minutes | Scan stall | Scope restriction message | "Scoped to lib/src/features/[module]/. Agent now producing analysis." |
| Fix attempt 4, same null error type | Fix-loop stall | Root cause identification | "Root issue is [X]. Provided direction. OR escalated if architectural." |
| Loop-operator invoked, nothing is actually stuck | All green | No intervention | "All phases healthy. Current status: [table]" |

---

### Common Mistakes

**Mistake 1: Diagnosing a DATA GATE as a stall**

**Symptom:** User says "the debugger is broken, it's just asking for logs." Loop-operator intervenes, tries to bypass the gate, provides its own analysis. The gate was the correct behavior — it was waiting for the console log.

**Cause:** Loop-operator read the "Please share the console log" message as an error output rather than a gate output.

**Fix:** Add these exact phrases to the WAIT indicator list in the agent file. Any message that matches a known gate output pattern is always a WAIT, never a STALL.

---

**Mistake 2: Restarting the pipeline to fix a handoff stall**

**Symptom:** Phase 1 (ui-reviewer) completed. Phase 2 never started. Loop-operator restarts the pipeline from Phase 1. ui-reviewer runs again. All Phase 1 work is repeated.

**Cause:** Loop-operator treated "pipeline not advancing" as "pipeline needs to restart" rather than "the handoff from Phase 1 to Phase 2 needs to be manually triggered."

**Fix:** For handoff stalls, the correct intervention is to read Phase 1's output and manually launch Phase 2 with that output as context. Phase 1 is COMPLETE — it does not rerun.

---

**Mistake 3: Applying an intervention before ruling out WAIT**

**Symptom:** Loop-operator injects a context anchor into an agent that was correctly waiting for human confirmation. The agent receives the anchor and proceeds without the human's answer. A Confirmation Gate is bypassed.

**Cause:** STALL/WAIT classification step was skipped.

**Fix:** STALL/WAIT classification is non-optional and runs before any intervention is selected. If the last agent output contains a Confirmation Gate message, any WAIT phrases, or an explicit question to the human → it is always a WAIT.

---

## [Flutter-GetX Specifics] — Loop Operator Agent

The loop-operator is nearly framework-agnostic — it monitors pipeline phase transitions regardless of what technology the developer agent is writing. One GetX-specific context applies.

---

### GetX Build Runner as a Legitimate Long-Running Operation

After any session where the developer agent modified a GetX controller that uses code generation, the user must run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This can take 60-120 seconds on a large project. If the loop-operator is monitoring during this period and sees no agent output, it may misclassify this as a scan stall or a tool loop stall.

**The correct diagnosis:** build_runner is not an agent operation — it is a shell command the user runs manually. If the pipeline appears paused while the user is running build_runner, that is a WAIT (user is doing manual work), not a STALL.

The loop-operator should check: did the developer agent's completion report include the note `"⚠️ Build runner must be run manually"` before diagnosing a stall? If yes → the pause is expected.

---

## Agent Reference

This table covers every agent referenced in Chapter 10 and in the standard Quality Loop. Use it to answer "which agent does X" without re-reading each agent's section.

| Agent | Writes Code | Reviews Code | Investigates | Documents | Plans |
|-------|------------|-------------|--------------|-----------|-------|
| fr-analyst | ❌ | ❌ | ✅ requirements | 3 FR files | ✅ feature |
| planner | ❌ | ❌ | ✅ architecture | implementation plan | ✅ system |
| developer | ✅ feature code | ❌ (self-validates) | ❌ | registries + error_learnings | ❌ |
| systematic-debugger | ❌ | ❌ | ✅ root cause | backend_issues.md | ❌ |
| ui-design-enforcer | ❌ | ❌ | ❌ | Design Brief | ✅ design |
| ui-reviewer | ❌ | ✅ UI/UX only | ❌ | image_list.md | ❌ |
| code-reviewer | ❌ | ✅ code quality | ❌ | ❌ | ❌ |
| security-reviewer | ✅ fixes only | ✅ security | ❌ | ❌ | ❌ |
| doc-updater | ❌ | ❌ | ❌ | ✅ registries | ❌ |
| project-map | ❌ | ❌ | ❌ | ✅ project_map.md | ❌ |
| tdd-guide | ✅ tests only | ❌ | ❌ | ❌ | ✅ test plan |
| build-error-resolver | ✅ fixes only | ❌ | ❌ | ❌ | ❌ |
| refactor-cleaner | ✅ removals only | ❌ | ❌ | ❌ | ❌ |
| e2e-runner | ✅ tests only | ❌ | ❌ | ❌ | ✅ test plan |
| loop-operator | ❌ | ❌ | ✅ loop health | ❌ | ❌ |

### Agent Safety Rules

> **CRITICAL:** refactor-cleaner refuses to run when: test coverage is below 60%, during active feature work on the same branch, or right before a release. These are not soft guidelines — the agent blocks and states the reason. Running a refactor while a feature is half-built on the same branch produces merge conflicts that are harder to untangle than the original duplication.

> **CRITICAL:** ui-reviewer caps at 2 correction passes per feature. code-reviewer caps at 1. If issues survive the maximum passes, they require human judgment — not another automated pass. loop-operator enforces these caps.

> **NOTE:** security-reviewer writes fixes only for the specific vulnerabilities it finds. It does not refactor surrounding code, improve naming, or expand scope beyond the security issue it was invoked for.

### Who Owns What (Protected File Assignments)

Each documentation file has exactly one owner agent. No other agent writes to files it doesn't own.

| File | Owner | No other agent writes here |
|------|-------|---------------------------|
| `docs/memory/component_registry.md` | developer | doc-updater reads, never writes |
| `docs/memory/api_registry.md` | developer | doc-updater reads, never writes |
| `docs/memory/error_learnings.md` | developer + systematic-debugger | all others: read only |
| `docs/FR/_pipeline_status.md` | developer (status) + fr-analyst (creation) | all others: read only |
| `docs/maps/project_map.md` | project-map | all others: read only |
| `docs/backend_issues/backend_issues.md` | systematic-debugger (Case B only) | no other agent writes here |
| Design Brief | ui-design-enforcer | never written by developer or main Claude |

Violating this ownership table produces unreliable documentation. If doc-updater writes to error_learnings.md, future agents reading that file cannot trust that entries reflect real mistakes — they may reflect doc-updater's interpretation of what a mistake looked like. Trust requires known authorship.

---

*Next: [Chapter 11: MCP Plugins — Claude Mem]*
