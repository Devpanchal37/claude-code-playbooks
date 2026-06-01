# Chapter 17: Predefined Prompt Patterns

> **Applies to:** Both
> **Prerequisites:** Chapter 9: Orchestra Management, Chapter 10: Core Agents Deep Dive
> **Estimated read + setup time:** ~25 minutes

---

## TL;DR

This chapter gives you exact, copy-paste prompt templates for every workflow in the agentic setup. Most developers use unstructured prompts — this bypasses agent gate sequences, triggers the wrong pipeline, and produces wrong output. The patterns here are not style suggestions: they are functional interfaces. Use them verbatim, fill in the bracketed parts, and the correct agent fires with the correct gates intact.

---

## Why Prompt Format Matters

The orchestration system runs on pattern matching. Main Claude reads your message, classifies it against the trigger table in `agents.md`, and routes it to the correct agent — or handles it directly.

When a prompt is unstructured, two failures happen:

**Failure 1 — Wrong classification.** Main Claude routes to the wrong agent, or skips the agent entirely and responds directly when a specialized agent should fire.

**Failure 2 — Gate bypass.** The correct agent fires, but Main Claude adds its own analysis before passing the prompt. The agent receives a pre-interpreted version of the original input. Agents with classification gates — especially `systematic-debugger` — are designed to fire their gates on raw input. Pre-interpreted input bypasses those gates and causes the agent to skip directly to execution with no evidence.

Every prompt pattern in this chapter solves a specific classification or gate problem. The **Wrong usage** section of each pattern shows exactly which failure mode the correct format prevents.

---

## The Five Prompt Types

Main Claude applies one of these five classifications to every message before deciding what to do:

| Type | Signal words / patterns | What fires | When to use |
|------|------------------------|------------|-------------|
| `BUG` | `bug::`, `issue::`, `fix [something]`, "broken", "wrong value", "not working" | `systematic-debugger` → `developer` | You observe incorrect behavior at runtime |
| `BUILD` | `develop`, `implement`, `build`, `add`, `create` | `developer` (or `planner` → `developer`) | You want code written |
| `CAPTURE` | Describes behavior without an action verb | `fr-analyst` | You want requirements captured before any code is written |
| `PLAN` | `plan`, `design approach for`, `how would you structure` | `planner` | You want an implementation strategy — no code yet |
| `INFO` | `what is`, `how does`, `explain`, `show me`, question mark without action verb | Main Claude answers directly | You want information, not action |

> **CRITICAL:** `BUG`, `CAPTURE`, and `BUILD` trigger different pipelines. A poorly worded prompt triggers the wrong one. "I want to add a filter to the profile screen" triggers `BUILD` — the developer agent starts writing code immediately. "The profile screen should show a filter by age and distance" triggers `CAPTURE` — fr-analyst generates FR documents first. Know which pipeline you want before you type.

---

## Prompt Patterns

---

### Prompt 1: New Feature Capture

**When to use:** When you have a feature idea and want FR documents (Flow Requirements, API Requirements, Implementation Tasks) generated before any code is written. Use this when the feature involves more than one screen or one API endpoint, or when business rules need to be clarified.

**Who uses it:** Developer types this to Main Claude.

**Expected outcome:** FR analyst launches, conducts a Socratic intake, and generates three FR files. No code is written until you explicitly ask for implementation.

**Template:**
```
[Describe what the feature does for the user and why it exists. Include: which screens are
involved, what data the user sees or enters, any business rules you know about.
Do NOT include: file names, layer suggestions, which agent to use, or architectural decisions.]
```

**Correct usage example:**
```
I want to add a filter system to the profile discovery screen. Users should be able to
filter profiles by age range, distance in kilometers, and gender preference. Currently
the discover screen shows all available profiles without any filtering. The filters should
persist between sessions.
```

**Wrong usage (and why it fails):**
> Wrong: "Add a filter feature. Create a FilterController in the presentation layer. Add a
> GET /api/filter endpoint. Use a BottomSheet with dropdown widgets."
>
> Why: Action verbs (`Add`, `Create`) classify this as `BUILD`, skipping FR analysis entirely.
> The developer agent starts writing code before requirements are confirmed. Architecture
> decisions made here may contradict what the planner would have recommended.

> **NOTE:** The `CAPTURE` type only fires when there is no action verb. If you accidentally
> type "implement" or "add" at the start, Main Claude routes to `BUILD`. When in doubt,
> start with "The [feature] should..." and describe behavior only.

---

### Prompt 2: Bug Report

**When to use:** Any time you observe incorrect behavior at runtime — wrong value displayed, action that should trigger something doesn't, screen state that shouldn't persist does.

**Who uses it:** Developer types this to Main Claude.

**Expected outcome:** `systematic-debugger` launches immediately. It classifies the bug (data mismatch → DATA GATE fires and asks for console log; UI-only → fast track; logic/state → full investigation). You do not touch code until the debugger produces a confirmed Handoff Brief.

**Template:**
```
bug:: [One sentence describing what the user sees, from the user's perspective — not a technical description]
```

**Correct usage examples:**
```
bug:: The message count badge shows 0 even though I can see unread messages in the chat list.
```
```
bug:: After accepting a connection request, the profile card is still visible in the discover stack instead of being removed.
```
```
bug:: The profile photo upload succeeds on the device but the photo does not appear on subsequent app opens.
```

**Wrong usage (and why it fails):**
> Wrong: "bug:: The MessageController.unreadCount observable is not updating. Check the
> socket event listener in ChatService. I think the event name might be wrong."
>
> Why: The technical analysis in the prompt tells `systematic-debugger` which files to read
> before it runs its DATA GATE. For a count mismatch, the DATA GATE is supposed to fire
> first and ask for the console log. Pre-loaded file suggestions bypass the gate, and the
> agent reads source files instead — producing unverified hypotheses with false confidence.

> **CRITICAL:** `bug::` is only for runtime behavioral bugs. Do NOT use `bug::` for build
> or compile errors. That triggers `systematic-debugger`, which is the wrong agent for
> build failures. See Prompt 4 for the correct build error format.

---

### Prompt 3: Console Log Paste After DATA GATE

**When to use:** After `systematic-debugger` responds with "⏸️ DATA MISMATCH DETECTED — please share the console/API log output." This response means the agent identified a data mismatch and is waiting for runtime evidence before forming any hypothesis.

**Who uses it:** Developer pastes this to Main Claude.

**Expected outcome:** `systematic-debugger` receives the raw log, reads the API response, and determines whether the correct data was returned from the backend (Flutter parsing bug) or whether the backend itself returned wrong data (backend issue).

**Template:**
```
[Paste the raw console output exactly as it appears — nothing else]
```

**Correct usage example:**
```
I/flutter (12034): --- API Response ---
I/flutter (12034): GET /api/v1/users/me/matches
I/flutter (12034): Status: 200
I/flutter (12034): Body: {"data":{"matches":[],"total":0},"success":true}
I/flutter (12034): -------------------
```

**Wrong usage (and why it fails):**
> Wrong: "Here is the console log. Key observations: 1. The endpoint returned an empty
> matches array. 2. The total is 0. 3. I think the filter parameter is being dropped.
> Now investigate: does the repository correctly pass the filter to the endpoint?"
>
> Why: Every sentence you add after the paste is analysis. `systematic-debugger` has its
> own analysis logic — it reads the log and draws its own conclusions. Your analysis
> overrides the agent's own reasoning and pushes it toward your hypothesis before it
> reads the evidence. Paste the log. Nothing else.

> **NOTE:** If the console log is truncated or missing, do not paste a partial log with
> "[truncated]" markers. The agent will ask you how to retrieve the full output
> (usually a cURL command against the endpoint). Follow its exact instruction.

---

### Prompt 4: Build Error Report

**When to use:** When `flutter analyze` fails, the project fails to compile, or `pub get` produces errors. This is the only trigger that fires `build-error-resolver`.

**Who uses it:** Developer types this to Main Claude.

**Expected outcome:** `build-error-resolver` launches and fixes the build errors with minimal diffs. It does not make architectural changes — it only fixes what broke.

**Template:**
```
flutter analyze is failing with [N] errors:

[Paste the exact error output from the terminal]
```

**Correct usage example:**
```
flutter analyze is failing with 3 errors:

lib/src/features/profile/presentation/screens/profile_screen.dart:45:12: Error: The
method 'ProfileController.loadUser' isn't defined for the class 'ProfileController'.
Try correcting the name to the name of an existing method.

lib/src/features/profile/data/repositories/profile_repository_impl.dart:23:5: Error:
'ProfileRepository' doesn't implement 'fetchProfile'. Try implementing the missing methods.
```

**Wrong usage (and why it fails):**
> Wrong: "bug:: flutter analyze is failing. Fix the compilation errors."
>
> Why: The `bug::` prefix triggers `systematic-debugger`, which is designed for runtime
> behavioral bugs. It will run its DATA GATE on a compiler error, which makes no sense —
> there is no API response to retrieve for a compile error. Use the build error format
> directly so `build-error-resolver` fires.

---

### Prompt 5: Development Request With Existing Plan

**When to use:** When an Implementation Tasks file already exists at `docs/FR/[ModuleName]/[ModuleName]_Implementation_Tasks.md`. The FR documents ARE the plan — no planner step needed.

**Who uses it:** Developer types this to Main Claude.

**Expected outcome:** `developer` agent launches, reads the FR files, and executes the complete implementation workflow: domain → data → presentation → route registration → pipeline status update. You wait for the REVIEW checkpoint.

**Template:**
```
develop [ModuleName]
```

**Correct usage examples:**
```
develop ProfileFilter
```
```
develop ChatNotifications
```
```
develop OnboardingFlow
```

**Wrong usage (and why it fails):**
> Wrong: "develop ProfileFilter. Create a FilterController with an RxList<String>
> for selected genders and two RxDouble values for age range. Use a BottomSheet.
> Call /api/v1/profiles/filter with query params."
>
> Why: The developer agent reads the FR Implementation Tasks file for this information.
> If you paste architecture decisions into the prompt, the agent may follow your
> instructions instead of the FR spec — producing code that conflicts with the agreed
> implementation plan.

> **NOTE:** If the implementation tasks file doesn't exist yet for the module you want
> to develop, use Prompt 6 (development request without a plan) instead. The developer
> agent does not create FR documents — that is the fr-analyst's responsibility.

---

### Prompt 6: Development Request Without Existing Plan

**When to use:** When you want code written for a feature that has no existing FR implementation plan. This triggers planner first, then developer after you confirm the plan.

**Who uses it:** Developer types this to Main Claude.

**Expected outcome:** `planner` launches and produces an implementation plan. You review the plan and either confirm it or request changes. After confirmation, `developer` launches with the plan as context.

**Template:**
```
I want to implement [feature name]. Here's the context:

- What it does: [one sentence describing the user-visible behavior]
- Screens involved: [list screens]
- API endpoints needed: [list or "unknown"]
- Constraints: [anything the planner must respect — existing components, performance requirements, business rules]
```

**Correct usage example:**
```
I want to implement a photo reordering feature. Here's the context:

- What it does: Users can drag photos in their profile to change the order. The new order
  is saved to the server immediately on drop.
- Screens involved: ProfileEditScreen (existing)
- API endpoints needed: PATCH /api/v1/users/me/photos/reorder (not yet implemented)
- Constraints: Must work with the existing photo grid widget. Must show an optimistic
  update before the API confirms, with a rollback if the API fails.
```

**Wrong usage (and why it fails):**
> Wrong: "Implement photo reordering. Create a ReorderableGridView widget with a
> PATCH endpoint call."
>
> Why: The `implement` verb triggers `developer` directly, skipping the planner. The
> developer agent receives no implementation plan and no FR documents. It will ask
> clarifying questions that the planner would have resolved systematically. The code
> produced without a plan is more likely to contradict existing architecture patterns.

---

### Prompt 7: Informational Question

**When to use:** When you want information about the codebase, the setup, or how something works — and you do NOT want any code written or any agent launched.

**Who uses it:** Developer types this to Main Claude.

**Expected outcome:** Main Claude answers directly from its loaded memory files and codebase knowledge. No agent fires.

**Template:**
```
[Question ending with "?" — no action verb at the start]
```

**Correct usage examples:**
```
What does the doc-updater agent write to component_registry.md?
```
```
How does the systematic-debugger decide between a Flutter-side and backend-side root cause?
```
```
Which screens depend on UserEntity?
```

**Wrong usage (and why it fails):**
> Wrong: "Explain how the systematic-debugger works and then fix the chat badge count."
>
> Why: Two intents in one message — informational and a bug fix — creates ambiguity.
> Main Claude may handle both directly instead of launching `systematic-debugger` for
> the fix. Separate your questions from your action requests. One message, one intent.

> **TIP:** Informational questions about the codebase are answered more accurately when
> Main Claude checks `docs/maps/project_map.md` and the registries. If you're asking
> about which files depend on something, say: "Check the project map for which modules
> depend on [EntityName]." This saves Main Claude a cross-file Grep and gets you a faster
> answer.

---

### Prompt 8: Planning Request

**When to use:** When you want a detailed implementation strategy produced but do not want code written yet. Useful for complex features, architectural decisions, and multi-module changes.

**Who uses it:** Developer types this to Main Claude.

**Expected outcome:** `planner` agent launches and produces a phased implementation plan: overview, API contracts, domain layer files, data layer files, presentation layer files, registration steps, testing strategy, and risks. No code is written until you confirm the plan and send a `develop` command.

**Template:**
```
Plan the implementation of [feature or system]. 

Context:
- [Describe the feature and why it exists]
- [Any existing components to reuse]
- [Any constraints — deadline, performance, existing contracts]
- [Any decisions already made that the planner must respect]
```

**Correct usage example:**
```
Plan the implementation of a real-time typing indicator in the chat screen.

Context:
- When a user types in the chat input, the other participant sees "typing..." in the chat header
- Socket.IO is already set up in the project (ChatService handles socket events)
- The typing indicator should disappear 3 seconds after the last keystroke
- The existing ChatRoomScreen and ChatRoomController must be modified — no new screens
```

**Wrong usage (and why it fails):**
> Wrong: "Design approach for typing indicator. Use a debounce timer with socket.emit."
>
> Why: Prefixing with a solution ("use a debounce timer") constrains the planner before
> it analyzes the problem. The planner's value is in surfacing risks, checking existing
> patterns, and sequencing correctly. Pre-loaded solutions short-circuit this analysis.

---

### Prompt 9: Agent Unexpected Output Correction

**When to use:** After an agent produces output that is wrong, incomplete, or off-target — and you want to identify the root cause and fix the agent file rather than just retry.

**Who uses it:** Developer fills this in and gives it to Main Claude.

**Expected outcome:** Main Claude reads the agent file, identifies which gate produced the incorrect behavior, and proposes an exact diff of the agent instruction that needs to change. After the fix, the agent must be re-tested with the original trigger scenario.

**Template:**
```
Agent issue report

Agent: [agent-name]

Scenario:
  Exact user message: [copy-paste the message you sent]
  What Main Claude passed to the agent: [copy-paste or describe — was it raw or enriched?]

Expected behavior:
  [Describe gate by gate what should have happened]

Actual behavior:
  [Describe gate by gate what actually happened]

Root cause classification (check all that apply):
  [ ] Gate was present but trigger condition wasn't specific enough
  [ ] Gate was present but Main Claude pre-processed the prompt and bypassed it
  [ ] Instruction existed but was in paragraph form — agent treated it as advisory
  [ ] Instruction was missing entirely
  [ ] Agent's classification table had a gap — input fell into the wrong category
  [ ] Agent produced output but format didn't match specification
  [ ] Other: [describe]

Proposed fix:
  [Quote the existing text] → [Quote the replacement text]
```

**Correct usage example:**
```
Agent issue report

Agent: systematic-debugger

Scenario:
  Exact user message: "bug:: Profile photo count shows 4 but only 3 photos appear"
  What Main Claude passed to the agent: "Bug description: Profile photo count shows 4 but
  only 3 photos appear. I believe this may be a rendering issue in the photo grid widget.
  Check PhotoGridWidget and PhotoController."

Expected behavior:
  Gate 1 (DATA GATE): fires immediately — count mismatch detected. Agent asks for
  console log. No file reading until log is provided.

Actual behavior:
  Agent read PhotoGridWidget and PhotoController directly. Produced a root cause hypothesis
  about an off-by-one error in the photo list rendering.

Root cause classification:
  [x] Gate was present but Main Claude pre-processed the prompt and bypassed it

Proposed fix:
  The prompt construction rule in CLAUDE.md must be enforced. Main Claude must never
  add hypotheses to the agent launch prompt for bug reports.
```

**Wrong usage (and why it fails):**
> Wrong: "The systematic-debugger got it wrong. Try again."
>
> Why: Retrying without identifying root cause produces the same result. The agent's
> behavior was not random — it followed the instructions it received. The issue is either
> in the agent file itself or in how Main Claude constructed the prompt. The feedback
> form forces you to distinguish between the two before changing anything.

---

### Prompt 10: Updating the Orchestra After an Agent Misbehaves

**When to use:** After identifying (via Prompt 9) that the root cause is in the agent file or the orchestra routing — not in Main Claude's prompt construction.

**Who uses it:** Developer types this to Main Claude.

**Expected outcome:** Main Claude updates the agent file with the exact change identified in the feedback form, then re-tests the original failure scenario to confirm it now passes.

**Template:**
```
Update [agent-name] based on this confirmed root cause:

Root cause: [The specific gate or instruction that failed — from the feedback form]

Change required:
  Existing text: "[exact text from the agent file that needs to change]"
  Replace with: "[exact replacement text]"

After making this change, re-test this scenario:
  [Paste the original trigger message that caused the failure]

Expected result after the fix:
  [Describe what should happen at each gate with the corrected agent]
```

**Correct usage example:**
```
Update systematic-debugger based on this confirmed root cause:

Root cause: The DATA GATE trigger condition says "count or value mismatch" but not
"visual count mismatch" — so a photo count discrepancy (visual display vs. data)
was not being detected.

Change required:
  Existing text: "DATA GATE fires when: API returns wrong count, wrong value, or amount"
  Replace with: "DATA GATE fires when: API returns wrong count, wrong value, amount,
  OR when a visual display count does not match the data count (e.g., 4 photos shown
  vs 3 displayed)"

After making this change, re-test this scenario:
  bug:: Profile photo count badge shows 4 but only 3 photos appear on the screen

Expected result after the fix:
  Gate 1 (DATA GATE) fires. Agent asks for console/API log. No file reading occurs.
```

---

### Prompt 11: Testing Whether an Agent Fires Correctly

**When to use:** After creating a new agent, after modifying an agent file, or when you suspect an agent is not firing for inputs it should handle.

**Who uses it:** Developer types this to Main Claude.

**Expected outcome:** Main Claude sends the test scenario to the agent, then reports what the agent did at each gate — pass, fail, or redirected.

**Template:**
```
Test this scenario for [agent-name]:

Trigger input: [Exact message to send to the agent]

Expected gate behavior:
  Gate 1 — [Gate name]: should [pass/trigger] because [condition]
  Gate 2 — [Gate name]: should [pass/trigger] because [condition]
  Final output: [What the agent should produce]

Report what the agent actually did at each gate and whether the output matched.
```

**Correct usage example:**
```
Test this scenario for systematic-debugger:

Trigger input: "bug:: The unread message count shows 0 after receiving a new message"

Expected gate behavior:
  Gate 1 — DATA GATE: should trigger because this is a count mismatch
  Agent should ask for console log and not read any files

Report what the agent actually did at each gate and whether the output matched.
```

**Wrong usage (and why it fails):**
> Wrong: "Does the systematic-debugger work?"
>
> Why: This is an `INFO` prompt — Main Claude answers from memory and says "yes, it
> should work." No actual test runs. Always specify the exact trigger input and the
> expected gate behavior, so the test produces binary pass/fail evidence.

---

## The Complete Feature Implementation Flow

This section shows the full lifecycle of a feature from first mention to merged code. It answers: which prompts do you use at each step, what is automated, what requires human action, and what to do when a step fails to trigger.

### Step-by-Step: Implement a New Feature

```
1. CAPTURE requirements
   ─────────────────────────────────────────────────────────
   You type:       "[Describe the feature and its user behavior — no action verb]"
   What fires:     fr-analyst (background)
   Human action:   Answer the fr-analyst's clarifying questions one at a time
   Output:         3 FR files in docs/FR/[ModuleName]/
   ─────────────────────────────────────────────────────────

2. REVIEW API requirements
   ─────────────────────────────────────────────────────────
   You do:         Open docs/FR/[ModuleName]/[ModuleName]_API_Requirements.md
   You send:       This file to the backend developer for feasibility confirmation
   Wait for:       Backend to confirm the endpoint contract is implementable
   Human action:   If backend needs changes → describe the changes to fr-analyst
                   fr-analyst updates the API_Requirements.md file
                   Re-confirm with backend
   Output:         Confirmed API contract (required before any Flutter code)
   ─────────────────────────────────────────────────────────

3. IMPLEMENT the feature
   ─────────────────────────────────────────────────────────
   You type:       "develop [ModuleName]"
   What fires:     developer agent (foreground)
   Human action:   None — developer runs the full implementation loop autonomously
   Output:         All domain/data/presentation files written, routes registered,
                   pipeline status marked REVIEW
   ─────────────────────────────────────────────────────────

4. QUALITY LOOP (automatic, managed by Main Claude)
   ─────────────────────────────────────────────────────────
   Step 4a:        ui-reviewer fires for new screens
                   → If corrections needed: developer applies them
                   → Max 2 correction passes
   Step 4b:        code-reviewer fires (targeted to changed files only)
                   → If CRITICAL/HIGH issues: developer fixes
   Step 4c:        security-reviewer fires IF sensitive surface changed
                   (auth, tokens, storage, user input, API boundaries)
   Step 4d:        doc-updater fires (background) — updates registries
   Step 4e:        project-map fires (background, after doc-updater)
   ─────────────────────────────────────────────────────────

5. REVIEW and COMMIT
   ─────────────────────────────────────────────────────────
   You do:         Review the quality loop output
   You type:       Confirm or request additional changes
   You do:         Run flutter analyze manually to verify clean
   You do:         Commit with conventional commit message
   ─────────────────────────────────────────────────────────
```

### What Is Automated vs. What Requires Human Action

| Step | Automated | Requires You |
|------|-----------|--------------|
| FR intake | fr-analyst asks questions | Answer questions one at a time |
| API confirmation | — | Send API_Requirements.md to backend; confirm it's feasible |
| Implementation | developer agent runs end-to-end | Nothing — wait for REVIEW |
| UI review | ui-reviewer produces corrections | Confirm or reject corrections |
| Code review | code-reviewer produces findings | Confirm fix direction if needed |
| Security review | security-reviewer flags issues | Confirm CRITICAL fixes are applied |
| Doc updates | doc-updater + project-map (background) | Nothing |
| Commit | — | Write commit message, run git commands |

The pattern: humans provide intent and confirm output. Agents execute and verify.

### When a Step Fails to Trigger

If an expected agent does not fire, there are three causes:

**Cause 1 — Wrong prompt type.** Your message was classified as `INFO` or `BUILD` when it should have been `CAPTURE`. Re-read the prompt classification table and rephrase.

**Cause 2 — Missing orchestra entry.** The agent file exists but is not registered in `agents.md`. Check: does `agents.md` have a trigger entry for this agent? If not, add it. See [Chapter 9: Orchestra Management] for the trigger table format.

**Cause 3 — Systematic misclassification.** The agent fires for some inputs but not others. Use Prompt 11 to test the specific scenario. If it fails, use the Agent Feedback Form from Prompt 9 to identify which gate or classification rule is missing.

**How to restart from any step:**

```
Step 1 failed → Re-send the CAPTURE prompt with clearer behavior description
Step 2 failed → Manual action — contact backend directly
Step 3 failed → Re-type "develop [ModuleName]" after verifying FR files exist
Step 4 failed → Ask Main Claude: "Run the quality loop for [ModuleName]" — names the exact agents
Step 5 failed → No agent involved — this is always manual
```

---

## Common Mistakes

### Mistake 1: Using `bug::` for build errors

**Symptom:** `systematic-debugger` fires for a `flutter analyze` error and asks for a console log. No log exists because it's a compiler error.

**Cause:** `bug::` triggers `systematic-debugger` for all prefixed messages, including compile failures.

**Fix:** Use the build error format (Prompt 4): "flutter analyze is failing with N errors: [paste errors]".

---

### Mistake 2: Adding technical analysis to a `bug::` prompt

**Symptom:** `systematic-debugger` reads source files and produces a hypothesis without asking for console logs — even for a count or value mismatch.

**Cause:** Technical context in the `bug::` message (file names, guesses, "I think it's in...") causes the agent to follow those investigation steps instead of running its DATA GATE.

**Fix:** `bug::` followed by exactly one sentence describing the observable behavior. Nothing else. No file references. No hypotheses.

---

### Mistake 3: Using `develop` without an existing plan for a complex feature

**Symptom:** Developer agent launches, asks for clarification, makes architectural decisions inline without a plan, or produces code that doesn't match any agreed structure.

**Cause:** `develop` without FR files means the developer agent has no plan to follow. It infers the implementation from the module name alone.

**Fix:** For complex features (new module, >3 files, new API contracts), use the CAPTURE → API confirmation → develop flow. Only use `develop [ModuleName]` directly when an Implementation Tasks file already exists.

---

### Mistake 4: Combining an informational question with an action request in one message

**Symptom:** Main Claude answers the question and also starts writing code, or answers the question and triggers the wrong agent for the action part.

**Cause:** Mixed intent in one message creates ambiguous classification. Main Claude picks one intent and often picks the wrong one.

**Fix:** Send two separate messages. First the question (INFO prompt). Then the action request after you have the information you need.

---

### Mistake 5: Retrying an agent without identifying the root cause

**Symptom:** Agent produces the same wrong output after retry, or produces a different wrong output that is equally wrong.

**Cause:** The agent's instruction is systematically incorrect — not context-dependent. Retrying gives it the same (or similar) instruction; the same gate fires the same way.

**Fix:** Use the Agent Feedback Form (Prompt 9) to identify the root cause. Only modify the agent file after the root cause is confirmed. Then test with the original trigger input before marking it fixed.

---

## [Flutter-GetX Specifics]

This section covers prompt patterns and prompt behaviors that are specific to the GetX + Clean Architecture stack.

---

### GetX Implementation Phases in the `develop` Prompt

When using `develop [ModuleName]`, the developer agent's internal implementation order follows the Clean Architecture dependency chain. If you need to communicate about a specific phase — for example, when a previous session completed only the domain layer — you can specify the starting phase:

**Template for resuming mid-implementation:**
```
develop [ModuleName] — continue from [phase name]

Completed phases:
  - [x] Phase 1: Models (entities, DTOs, model key constants)
  - [x] Phase 2: API layer (repository methods, data source, endpoint wiring)
  - [ ] Phase 3: Screens (controller, bindings, widget tree)
  - [ ] Phase 4: Locale keys
  - [ ] Phase 5: Navigation (routes, app_pages, callers)

Continue from Phase 3.
```

> **NOTE:** This is only needed when a session was interrupted mid-implementation and a
> `[CHECKPOINT]` entry was written to pipeline_status.md. On a fresh `develop` command,
> the developer agent reads the checkpoint automatically and resumes from the last
> completed phase.

---

### Locale Key Planning Prompt

**When to use:** Before running `develop [ModuleName]` for a feature that involves new user-facing text. This prompt adds a locale key enumeration section to the Implementation Tasks file. Without it, developers risk hardcoding strings or missing translatable text.

**Who uses it:** Developer gives this to fr-analyst (or asks Main Claude to add it to an existing Implementation Tasks file).

**Template:**
```
Add a locale key enumeration to [ModuleName]_Implementation_Tasks.md.

For each new screen or user-visible text element in this module, list:
- Key name (using the locale.xxx convention from the project's localization file)
- English value
- Which screen or widget uses it

Format as a table under "New Locale Keys Required" at the end of the file.
```

**Correct usage example:**
```
Add a locale key enumeration to ProfileFilter_Implementation_Tasks.md.

For each new screen or user-visible text element in the ProfileFilter module, list:
- Key name (using the locale.xxx convention)
- English value
- Which screen or widget uses it

Format as a table under "New Locale Keys Required" at the end of the file.
```

---

### Cross-Screen Event Planning Prompt

**When to use:** When a feature updates state across multiple screens simultaneously. In GetX, cross-screen events rely on named string constants and a shared event bus. If two developers implement the sender and receiver independently with different event names, they never connect — and this class of bug is invisible until integration testing.

**Who uses it:** Developer gives this to fr-analyst before FR generation, or adds to an existing Flow_Requirements.md.

**Template:**
```
Add a cross-screen event table to [ModuleName]_Flow_Requirements.md.

For each action in this module that updates state on another screen, list:
- Event name (the string constant used in the event bus)
- Fired by (which controller fires it)
- Consumed by (which controller listens for it)
- What state changes on the consumer side

Format as a table under "Cross-Screen Events" in the Flow_Requirements file.
```

**Correct usage example:**
```
Add a cross-screen event table to ConnectionRequest_Flow_Requirements.md.

When a connection request is accepted, both the discover stack and the notification
badge must update. List the event that bridges them:
- Event name
- Fired by (which controller)
- Consumed by (which controllers listen)
- What each consumer does when the event fires
```

> **CRITICAL:** Never let two developers independently implement the event emitter
> and the event listener for the same logical action. The sender and receiver must
> agree on the event name string constant before either is implemented. This is the
> entire purpose of the cross-screen events table — shared agreement before coding.

---

### Controller Type Specification in Bug Reports

When reporting a GetX controller bug, specifying whether the controller is permanent or non-permanent helps `systematic-debugger` classify the bug faster. A controller that was disposed when it shouldn't have been, or never disposed when it should have been, is a distinct class of bug from a data or state bug.

**When to add this context to a `bug::` prompt:**
Only when the bug involves: a screen that was navigated away from and back to, unexpected state reset, or a controller error after navigation.

**Extended bug report format for controller lifecycle bugs:**
```
bug:: [description of what the user sees]
Context: [ControllerName] — [permanent / non-permanent]
```

**Example:**
```
bug:: After going back from the profile screen and returning, the profile photo list is empty.
Context: ProfileController — non-permanent
```

> **NOTE:** Do NOT add this context for data mismatch bugs. Adding controller type
> context to a count or value mismatch bug tells the agent to investigate the
> controller before it runs its DATA GATE — the same bypass failure as adding
> file names. Only add context when the bug is explicitly about navigation/lifecycle.

---

## Reference

| Item | Value |
|------|-------|
| Prompt types | `BUG`, `BUILD`, `CAPTURE`, `PLAN`, `INFO` |
| Bug report trigger | `bug:: [one sentence from the user's perspective]` |
| Build error trigger | "flutter analyze is failing with N errors: [paste]" |
| Development trigger (plan exists) | `develop [ModuleName]` |
| Development trigger (no plan) | "I want to implement [feature]. Here's the context: ..." |
| Feature capture trigger | Describe behavior, no action verb |
| Planning trigger | "Plan the implementation of [feature]" |
| Agent test trigger | "Test this scenario for [agent-name]: ..." |
| Complete feature flow | CAPTURE → API confirm → develop → quality loop → commit |
| GetX implementation phases | Models → API layer → Screens → Locale keys → Navigation |
| Cross-screen event planning | Add "Cross-Screen Events" table to Flow_Requirements.md before coding |

---

*Next: Chapter 15: Skills*
