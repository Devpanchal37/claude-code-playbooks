# Chapter 21: Mistakes & Lessons Learned

> **Applies to:** Both
> **Prerequisites:** All other chapters — this chapter is written last and references every component
> **Estimated read + setup time:** ~25 minutes (read-only — no setup steps)

---

## TL;DR

This chapter documents what actually went wrong during the design, setup, and operation of this agentic system — not hypothetical failure modes, but real failures with real symptoms and real fixes. Every entry here was discovered by running the setup on actual projects and hitting the wall at full speed. Read this before you build anything. The mistakes are ordered by category, not by severity, because the worst mistake in any category depends entirely on your project.

---

## How to Use This Chapter

Skim the category headings and read the mistakes that match where you are in your setup. If you are:

- **Just starting:** Read Agent Design Mistakes and CLAUDE.md Mistakes first — these cause the most rework if you get them wrong at the start.
- **Setup complete, experiencing weird behavior:** Read Behavioral Bugs in Agents — the issue you're seeing is likely documented here.
- **Setup working, scaling to a team:** Read Orchestra Mistakes and Documentation Mistakes — these are the ones that appear at scale, not at setup time.
- **Something is "almost right" but not quite:** Read Memory System Mistakes — subtle memory issues produce subtle symptoms.

Each entry follows the same format:

**Symptom:** What you see that tells you something is wrong.  
**What went wrong:** The root cause.  
**Fix:** The exact correction.  
**How to prevent it:** The upstream change that stops this from recurring.

---

## Agent Design Mistakes

### Mistake: Agent scope too broad — one agent for multiple concerns

**Symptom:** The agent produces output that is partially correct for one task and partially wrong for another. When you ask it to "review and fix" code, the review section is good but the fix section introduces new problems. When you ask it to "plan and implement," the plan is complete but the implementation ignores the plan.

**What went wrong:** The agent was given two responsibilities — review and fix, or plan and implement — that require different information, different reasoning depth, and different output formats. The agent resolves the conflict by averaging the two: it does each task at 60% quality instead of one task at 100%.

**Fix:** Split the agent. One agent reviews. A different agent fixes (the developer agent, in Correction Pass Mode). One agent plans. A different agent implements. The handoff between them is a brief — a structured output that passes the first agent's conclusion to the second as context.

**How to prevent it:** Before creating any agent, answer: "What is the single thing this agent is responsible for?" If the answer contains "and," the scope is too broad.

---

### Mistake: Agent instructions written as paragraphs — treated as advisory

**Symptom:** The agent sometimes follows the rule, sometimes ignores it. There is no error — the agent just doesn't apply the constraint consistently. The same input produces different behavior on different days.

**What went wrong:** Instructions written as prose paragraphs ("When you receive a bug report, you should first check...") are treated as guidelines by the agent, not as mandatory constraints. The agent weighs them against other context and sometimes decides the context overrides the guideline.

**Fix:** Rewrite every mandatory rule as a numbered list under a bold heading with explicit gate language:

```
## ⛔ MANDATORY GATE — NO EXCEPTIONS

1. On every bug report, BEFORE reading any source file:
   → Check if the report describes a data mismatch (wrong value, wrong count)
   → If YES: fire DATA GATE immediately. Do not proceed to Step 2.
   → If NO: proceed to Step 2.

2. ...
```

The structure — numbered, imperative verbs, explicit branch conditions — removes the ambiguity that lets the agent treat the rule as optional.

**How to prevent it:** When writing any agent instruction that must always apply, ask: "Could an agent reading this decide it doesn't apply in some cases?" If yes, rewrite it as a gate with explicit exit conditions for every path.

---

### Mistake: Missing the Pre-Step — agent re-makes known mistakes every session

**Symptom:** The developer agent generates a pattern that you corrected two weeks ago. You add the fix to `error_learnings.md`. Three sessions later, the same pattern appears again. The agent has no memory of the correction.

**What went wrong:** The agent file has no Pre-Step that reads `error_learnings.md` before beginning work. Each session starts cold. The agent has no way to know what was discovered in previous sessions.

**Fix:** Add a mandatory Pre-Step block to the agent file, before any implementation step:

```
## Pre-Step (MANDATORY — runs before any implementation)

1. Query claude-mem: search for [module-name] and [feature-type] — apply any past decisions found
2. Read docs/memory/error_learnings.md — grep for [module] and [pattern-type]
3. Check docs/memory/component_registry.md — grep before creating any new widget
4. Check docs/memory/api_registry.md — grep before adding any new API call
5. Check docs/FR/_pipeline_status.md — find current task state and any [CHECKPOINT] lines

No implementation until Pre-Step is complete.
```

**How to prevent it:** Every agent that writes code must have a Pre-Step. Without it, the agent is operating without its own institutional memory.

---

### Mistake: Output format not specified — Main Claude can't parse the result

**Symptom:** The agent produces different formats each time — sometimes a bulleted list, sometimes prose, sometimes a structured table. Main Claude receives the output and sometimes correctly routes to the next step, sometimes doesn't, because it can't reliably identify the evidence status or root cause in an unstructured output.

**What went wrong:** The agent file has no explicit output format specification. The agent produces whatever format feels natural for the current input. When Main Claude needs to extract a specific field from the output (e.g., "Evidence Status: CONFIRMED"), it fails if the agent wrote "I have confirmed the root cause is..."

**Fix:** Add an explicit output template to the agent file and require the agent to use it exactly:

```
## Output Format (MANDATORY — use this template exactly)

**Handoff Brief**
Evidence Status: CONFIRMED | UNCONFIRMED
Root Cause: [one sentence — file:line or API endpoint]
Fix Direction: [what to change, not how]
Files Changed: [list only if applicable]
```

**How to prevent it:** When designing an agent, specify the output format before specifying any of the implementation steps. The output format is what other agents and Main Claude depend on — it must be a contract, not a suggestion.

---

## Orchestra Mistakes

### Mistake: Agent file created but not registered in agents.md

**Symptom:** The agent file exists at `.claude/agents/[name].md`. You can open it and it looks correct. But when you send the trigger message, Main Claude does not launch the agent — it handles the task itself or ignores the trigger.

**What went wrong:** An agent file without an entry in `agents.md` is invisible to the orchestra. Main Claude does not scan `.claude/agents/` looking for matching agents. It only consults `agents.md` to decide what to launch.

**Fix:** Open `agents.md` and add the trigger entry:

```
| "develop [module]" | `developer` | foreground | Always |
```

Then test the trigger immediately by sending the exact trigger message and verifying the agent launches.

**How to prevent it:** Every time you create an agent file, treat the `agents.md` update as a required second step — not an optional follow-up. An agent without an orchestra entry doesn't exist from the system's perspective.

---

### Mistake: Trigger registered in the wrong category — agent fires for wrong messages

**Symptom:** You type `bug:: [description]` and the developer agent launches instead of the systematic-debugger. Or you describe a feature requirement and the developer agent fires immediately before any planning or FR analysis.

**What went wrong:** The trigger entry is in the wrong section of `agents.md` — either the trigger pattern is too broad (matches more messages than intended) or it's categorized under the wrong heading and Main Claude reads the wrong priority.

**Fix:** Review the trigger pattern. Bug triggers must match only `bug::` and `issue::` prefixes — they should not match generic messages that contain the word "fix" buried in a longer request. Use anchored patterns where possible. Separate categories clearly with headings in `agents.md`.

**How to prevent it:** After adding any trigger entry, test it with 3 different message types: one that should match, one that should not match, and one edge case. Verify the correct agent fires for each.

---

### Mistake: Foreground mode where background was fine — Main Claude blocked unnecessarily

**Symptom:** After each feature, Main Claude waits for the doc-updater to complete before responding to you. You can't ask a follow-up question or check something while documentation is updating. Sessions feel slow at the end of every feature.

**What went wrong:** The doc-updater agent is set to foreground mode in `agents.md`. Main Claude waits for it to finish before continuing. But doc-updater's output is not needed by Main Claude before the next action — it is an independent task that can run while the conversation continues.

**Fix:** Set doc-updater (and project-map) to background mode in `agents.md`. They produce output that Main Claude does not need to read — they write directly to files.

**How to prevent it:** When adding an agent to the orchestra, explicitly decide: does Main Claude need this agent's output to decide what to do next? If yes → foreground. If no → background.

---

### Mistake: Not defining raw vs. processed prompt — DATA GATE bypassed

**Symptom:** You send `bug:: profile count shows 0`. Main Claude launches systematic-debugger but adds context first: "I think the issue might be in the discover controller. Investigate the profile count calculation." The systematic-debugger reads the source files and produces a hypothesis. No DATA GATE fires. You receive a root cause based on static analysis, not confirmed evidence.

**What went wrong:** Main Claude pre-processed the bug description and added its own analysis before passing it to the agent. The systematic-debugger received an enriched prompt instead of the raw bug description. Its DATA GATE fires on raw data-mismatch descriptions — but when the prompt already contains an investigation direction, the agent follows that direction instead of its own gate sequence.

**Fix:** Add an explicit prompt construction rule to `CLAUDE.md` and `agents.md`:

```
PROMPT CONSTRUCTION RULE — Bug Reports (CRITICAL):
When launching systematic-debugger for the initial bug report,
pass ONLY:
  Bug description: [exact user message]
  Screen/module: [inferred from description]
  Project root: [path]

NEVER add:
  Investigation steps
  File suggestions
  Hypotheses
  "Check if X param is missing"
```

**How to prevent it:** For any agent whose first step is a classification gate — a gate that fires on unprocessed input — the launch prompt must be raw. Document this explicitly in `agents.md` for every agent that has a classification gate as its first step.

---

### Mistake: Main orchestrator rewrote delegated output — conflicting intake paths

**Scope:** Cursor IDE orchestration issue only (Cursor main-agent + subagent transport behavior). Not a universal issue across all IDEs/runtimes.

**Symptom:** A delegated agent returns clarification questions, but Main Claude asks a second, different set in the parent message. The human now sees two intake tracks and is forced to reconcile conflicts.

**What went wrong:** Main Claude prioritized baseline "helpful" rewriting behavior (summarize/rephrase/add context) instead of strict orchestration transport behavior. Delegated output was treated as editable draft, not source-of-truth payload.

**Fix:** Add a global orchestration output contract in `CLAUDE.md` and `agents.md`:
- Verbatim relay is default for delegated outputs
- Transform only on explicit user request (summarize/rephrase/rewrite/expand)
- Parent must not add parallel clarification questions when delegate already asked
- Add mandatory pre-send integrity check: no additions, no rewording, no reordering without permission

**How to prevent it:** Enforce "strict orchestrator mode" as a project-wide rule: project rules always override assistant default behaviors. For delegated workflows, raw transport beats readability optimization unless the human explicitly asks for transformation.

---

## CLAUDE.md Mistakes

### Mistake: CLAUDE.md grew too large — Main Claude spends context loading rules

**Symptom:** Main Claude's responses to simple questions feel slower. In complex sessions, Main Claude occasionally ignores a rule it followed correctly in earlier sessions. When you check context usage, it's at 30–40% before any real work has started.

**What went wrong:** CLAUDE.md grew to 600–800+ lines over time as rules were added session by session. Main Claude now spends a significant portion of its context window loading and processing the rules file before the first user request is even answered.

**Fix:** Audit CLAUDE.md. Move anything that is detailed documentation (full examples, long explanations) to the relevant agent file or instruction file. CLAUDE.md should contain triggers, quick references, and critical rules — not the detailed rationale and examples for each rule. Target: under 400 lines.

**How to prevent it:** When adding a new rule to CLAUDE.md, first ask: does this belong in an agent file instead? Rules that only apply during one agent's operation belong in that agent's file. Only project-wide rules that Main Claude needs on every session belong in CLAUDE.md.

---

### Mistake: Agent-specific instructions placed in CLAUDE.md — instructions conflict

**Symptom:** The developer agent behaves differently than the developer agent file specifies. When you read `CLAUDE.md`, you find instructions for what the developer agent should do. When you read `developer.md`, you find different (or contradicting) instructions for the same scenario. The agent sometimes follows one, sometimes the other.

**What went wrong:** Instructions for the developer agent were added to CLAUDE.md because it was faster than opening the agent file. Over time, the CLAUDE.md version and the agent file version diverged.

**Fix:** Remove all agent-specific instructions from CLAUDE.md. CLAUDE.md should reference which agent handles which trigger — nothing more. The agent file is the authoritative source for how that agent behaves.

**How to prevent it:** CLAUDE.md contains orchestration (which agent fires when). Agent files contain agent behavior (what the agent does when it fires). Never mix these.

---

### Mistake: Vague language in rules — agent ignores the rule

**Symptom:** CLAUDE.md says "you should try to check the component registry before creating new widgets." The developer agent regularly creates duplicate widgets. It is not technically ignoring the rule — it checked the registry and decided a new widget was appropriate. But it checks it briefly and moves on.

**What went wrong:** "Should try to" is permission to not do it. The agent interprets "should try" as "this is advisory, do it if it's convenient."

**Fix:** Rewrite every rule that must always apply using imperatives:

```
WRONG:  "You should try to check the component registry before creating new widgets."
RIGHT:  "BEFORE creating any widget: grep component_registry.md for the widget name.
         If a match exists → USE IT, do not create a duplicate.
         Only if no match exists → create the new widget and register it."
```

**How to prevent it:** Read every rule in CLAUDE.md and highlight any hedging language: "should," "try to," "when possible," "generally," "consider." Each one is a gap. Rewrite them as "always," "never," "before X, do Y," "if A then B."

---

## Memory System Mistakes

### Mistake: No claude-mem Pre-Step — agents re-discover known solutions every session

**Symptom:** Every new session, an agent recommends a pattern that was tried and rejected two months ago. Or it re-discovers a package gotcha that took a full session to diagnose the first time. The solution exists in claude-mem but the agent never sees it.

**What went wrong:** The agent file has no Pre-Step that queries claude-mem. Each agent session starts with no access to past decisions, unless those decisions were also written to `error_learnings.md`.

**Fix:** Add the claude-mem query to every major agent's Pre-Step:

```
Pre-Step 1: Query claude-mem
  - smart_search("[module-name] pattern")
  - smart_search("[feature-type] decision")
  - Apply findings before forming any plan or hypothesis
```

**How to prevent it:** Claude-mem queries cost almost nothing. Every agent that makes implementation or investigation decisions should query it before starting. The only agents that don't need it are purely mechanical agents (doc-updater, project-map) that execute without judgment.

---

### Mistake: Storing too much in auto-memory — memory becomes noise

**Symptom:** Auto-memory files are large. Main Claude loads them at session start but the content doesn't appear to help. Sometimes Main Claude references a memory that is irrelevant to the current task or contradicts what the current code says.

**What went wrong:** Auto-memory accumulated entries that are too broad, too specific (entire code blocks), or too transient (mid-session state that expired after the session). The memory index (MEMORY.md) is now full of entries that sound relevant based on their title but contain stale content.

**Fix:** Audit the memory files. Remove entries that:
- Contain code blocks (code belongs in the codebase, not memory)
- Reference git history or recent changes (git log is authoritative)
- Document debugging solutions or fix recipes (the fix is in the code)
- Describe current in-progress work (belongs in todo list or pipeline status, not memory)

**How to prevent it:** Before saving any memory entry, apply the exclusion checklist: is this derivable from the code? From git? From docs? If yes — don't save it. Only save what is non-obvious and would be lost if the conversation ended.

---

### Mistake: Not updating error_learnings.md after a mistake is fixed — next session repeats it

**Symptom:** A session ends with a corrected mistake. The fix is in the code. But `error_learnings.md` still shows the old, wrong pattern as if it were never corrected. In the next session, the developer agent reads the entry and avoids the corrected pattern, thinking it is also wrong.

**What went wrong:** The fix was applied to the code but the entry in `error_learnings.md` was never updated to reflect what "correct" looks like. The entry documents the mistake without documenting the resolution.

**Fix:** Whenever a mistake entry leads to a code fix, append the resolution to the entry:

```
## [2025-01-10] Wrong pattern for X
**Mistake:** [what was wrong]
**Correct:** [what is right]
**Pattern:** [the general rule]
**Resolved:** [2025-01-15] Fixed in lib/src/features/... — correct pattern is now in the codebase
```

**How to prevent it:** Treat `error_learnings.md` updates as part of the fix process, not a separate documentation task. The error learning protocol requires two triggers — human corrects a mistake, AND agent encounters and solves a non-obvious issue. Both must write to the file before the session ends.

---

## Documentation Mistakes

### Mistake: Skipping the backend verification loop — built on wrong API contract

**Symptom:** Flutter implementation is complete. Backend integration starts. The response structure doesn't match what the Flutter code expects — wrong field names, wrong types, pagination in a different format. Part of the Flutter implementation must be rewritten.

**What went wrong:** The API requirements were documented in `API_Requirements.md` and immediately used as the basis for Flutter implementation — without the backend team confirming feasibility or the actual response format. The Flutter code was built against a spec the backend didn't agree to.

**Fix:** The API_Requirements.md generated by the FR analyst goes to the backend team before any Flutter work starts. Flutter implementation starts only after the backend confirms the endpoint spec. If the backend needs to change anything, the FR analyst updates the spec, the backend confirms again, then Flutter starts.

**How to prevent it:** Add an explicit gate in `docs/FR/_pipeline_status.md`: status goes from `⏳ PENDING` to `🔄 IN_PROGRESS` only after backend has added a confirmation comment to API_Requirements.md. Do not start Flutter implementation on a PENDING API spec.

---

### Mistake: No CHECKPOINT entries — session interruption loses progress

**Symptom:** A feature implementation is interrupted mid-session (context window fills, connection drops, session ends unexpectedly). The next session starts and there is no record of which files were completed, which were partially written, and which weren't started. The developer agent starts from the beginning, potentially overwriting work.

**What went wrong:** The developer agent was not writing `[CHECKPOINT]` entries to `_pipeline_status.md` as it completed each file. The only record of progress is the conversation history, which is gone.

**Fix:** Add a checkpoint requirement to the developer agent's implementation loop:

```
After completing each file in a 4+ file task:
  Update docs/FR/_pipeline_status.md with:
  [CHECKPOINT] [timestamp] Completed: [file path]
  [CHECKPOINT] [timestamp] Next: [next file path]
```

At session start, Main Claude reads `_pipeline_status.md` for any `[CHECKPOINT]` lines and resumes from there.

**How to prevent it:** The developer agent's self-validation checklist must include: "Have I written [CHECKPOINT] entries for every completed file in this task?" This check runs before the agent marks the feature as REVIEW.

---

### Mistake: Component registry falls behind — duplicate widgets created

**Symptom:** Two different screens have nearly identical card widgets. A code reviewer spots them in a PR. One was created in sprint 2, one in sprint 5. The sprint 5 developer didn't know the sprint 2 widget existed because the registry wasn't updated after sprint 2.

**What went wrong:** The developer agent created the sprint 2 widget and registered it in `component_registry.md`. But the component_registry.md was not committed or was overwritten by a merge, and the entry was lost. The sprint 5 developer agent grepped an empty or outdated registry and found no match.

**Fix:** Two changes:
1. Treat `component_registry.md` updates as part of the feature commit — not a separate "documentation task" that gets deferred.
2. After any merge that could affect `component_registry.md`, immediately verify the registry is complete using the registry freshness check from [Chapter 22: Keeping the Setup Current].

**How to prevent it:** The developer agent's documentation update step (writing to component_registry.md) must happen before `flutter analyze` runs, not after. If it runs after, there is no enforcement mechanism to catch a missed update before the session ends.

---

## Behavioral Bugs in Agents

These are bugs observed in actual agent sessions — specific to the gate design of the agents described in this playbook.

---

### Behavioral Bug: DATA GATE bypassed by pre-loaded investigation steps

**Symptom:** You send `bug:: count shows 0`. Main Claude adds "I believe this is in the discover controller, investigate the count calculation logic." Systematic-debugger launches, reads source files, produces a hypothesis. No DATA GATE fires. The output sounds confident. It is based entirely on static analysis.

**Root cause:** Main Claude wrote investigation instructions into the launch prompt. The systematic-debugger received a prompt that already had a direction ("investigate the count calculation logic"). Its DATA GATE fires on raw data-mismatch descriptions — the enriched prompt bypassed it because the agent followed Main Claude's direction instead of its own gate sequence.

**How it was found:** A data bug was diagnosed as a Flutter-side controller issue. The developer agent applied a fix. The fix did nothing. The actual issue was a backend response sending `null` instead of `0` — visible only in the API log, which the DATA GATE would have requested immediately if it had fired.

**Prevention:** The prompt construction rule in `CLAUDE.md` and `agents.md` must be explicit and include examples of FORBIDDEN additions. "NEVER add investigation steps" is not enough — show exactly what "adding investigation steps" looks like so it can be recognized before the prompt is sent.

---

### Behavioral Bug: FR analyst asked all questions at once — incomplete requirements

**Symptom:** The FR analyst sends one message with all 9 intake questions. The developer answers them in a single response — brief answers to each, because the volume of questions is overwhelming. The resulting FR files have incomplete edge case coverage and missing UI states.

**Root cause:** The FR analyst was designed to ask all clarifying questions in one message for efficiency. In practice, a human given 9 questions at once provides brief answers to each. A human given one question at a time provides thorough answers.

**How it was found:** A feature was implemented against an FR that missed 3 UI states. The FR analyst had asked about UI states but the human's answer was "the usual loading, error, success" — because it was question 7 of 9 in a single message. Implementation based on the brief answer missed empty state and a specific error variant.

**Prevention:** The FR analyst's intake process should send one question at a time, in dependency order. Depth of a single answer is more valuable than breadth of all answers. The agent file should explicitly state: "Send one question. Wait for the answer. Then send the next."

---

### Behavioral Bug: Developer agent re-read instruction files multiple times per task

**Symptom:** Token usage for a single feature implementation is 3–4x higher than expected. Context window fills mid-feature. The developer agent reads `UI_INSTRUCTION.md` at the start of a session, then reads it again before implementing each screen, then reads it again when checking compliance.

**Root cause:** The developer agent's instruction loading step was placed inside the per-feature loop instead of before it. For a 4-feature task, this meant 4 full reads of the instruction files.

**How it was found:** Token usage monitoring showed repeated file reads in the tool call history. The same file appeared 4 times across a single session.

**Prevention:** Instruction files (`UI_INSTRUCTION.md`, `ARCHITECTURE.md`, `API_INSTRUCTION.md`) are read once per session, not once per feature. The agent's instruction loading step must be placed before the per-feature loop begins, not inside it. Add this explicitly to the developer agent: "Instruction files are loaded once. Do not re-read them within the same session."

---

### Behavioral Bug: Agent produced a brief with a function name that didn't exist

**Symptom:** Systematic-debugger produces a Handoff Brief: "Root cause: `calculateProfileCount()` in `DiscoverController` returns `null` instead of `0`. Fix: add null coalescing." Developer agent opens the file. `calculateProfileCount()` does not exist — the calculation is inline. The agent writes a fix that calls a function that isn't there.

**Root cause:** The systematic-debugger produced the brief based on code inference rather than grep-confirmed existence. The function name in the brief was plausible based on the pattern, but wrong.

**How it was found:** The developer agent's edit produced a compile error. `calculateProfileCount` was referenced but never defined.

**Prevention:** The Brief Integrity Rule (from [Chapter 8: Agent Creation Guide]) must be enforced: every function name, class name, and endpoint string in a handoff brief must be confirmed to exist before the brief is written. The confirmation method: `grep -r "functionName" lib/` — if grep returns nothing, the function name must not appear in the brief.

---

## [Flutter-GetX Specifics]

### GetX-specific mistakes that don't appear in generic Flutter setups

These mistakes are specific to the GetX state management patterns enforced in Playbook B. They are documented separately because the fix involves GetX APIs and the prevention involves the widget placement gate — neither of which applies to generic Flutter projects.

---

### Mistake: IndexedStack tab controller missing `permanent: true`

**Symptom:** Switching between tabs on a bottom navigation bar causes one tab's state to reset. The controller for that tab appears to re-initialize every time the tab is selected. Data that was loaded is gone.

**What went wrong:** A controller used by a tab inside an `IndexedStack` was registered without `permanent: true`. GetX auto-disposes controllers when their associated route is popped from the navigation stack. An `IndexedStack` tab never pops — so the controller is not in the stack to be "popped" — but GetX's disposal mechanism still fires because the route context changes.

**Fix:** All controllers registered for `IndexedStack` tabs must use:
```dart
Get.put(ProfileController(), permanent: true)
```

**How to prevent it:** The widget placement gate in the developer agent must include this check: "Is this controller attached to an `IndexedStack` tab? If yes, verify `permanent: true`." This check fires before the widget is placed. The code-reviewer's criteria must also include this rule.

---

### Mistake: RxList replaced with `=` operator instead of `.assignAll()`

**Symptom:** A list on screen does not update when new data arrives. The observable is updated in the controller but `Obx` does not rebuild. The list appears frozen even though the controller has the new data.

**What went wrong:** The controller used `myList = newData` to replace the `RxList`. The `=` operator on an `RxList` replaces the reference — but `Obx` is watching the original reference. The `Obx` closure is observing a reference that no longer points to the list being updated.

**Fix:** Always use `.assignAll()` for full list replacement:
```dart
// Wrong
myList = newData;

// Correct
myList.assignAll(newData);
```

**How to prevent it:** Add to the developer agent's widget placement gate: "Does this controller update an `RxList`? Verify `.assignAll()` is used for replacement — never `=`." Add to `error_learnings.md` with date.

---

### Mistake: `Obx` wrapping a widget that doesn't access an observable

**Symptom:** `Obx` is wrapping a widget. The wrapped widget never rebuilds when the observable changes. Or: the wrapped widget rebuilds constantly, even when its displayed data hasn't changed.

**What went wrong (variant A — no rebuild):** The widget inside `Obx` does not access any `.value` or reactive observable directly in its own closure. It accesses the value through a child widget or through a non-reactive method. `Obx` only rebuilds when an observable is accessed inside its own closure — not in child closures.

**What went wrong (variant B — too many rebuilds):** A coarse `Obx` wraps a large widget tree. One observable in the closure changes frequently (e.g., a timer tick). The entire wrapped tree rebuilds on every tick.

**Fix (variant A):** Move the `Obx` closer to the specific widget that reads the observable. Or read the `.value` directly inside the `Obx` closure:
```dart
Obx(() => Text(controller.count.value.toString()))
```

**Fix (variant B):** Split the `Obx` into smaller scopes, each wrapping only the widget that reads the specific observable.

**How to prevent it:** The widget placement gate must check: "If this widget uses `Obx`, does the `Obx` closure itself access a `.value` or reactive observable? If not, the `Obx` is misplaced — move it."

---

### Mistake: Backend issue logged as Flutter-side — fix applied to wrong layer

**Symptom:** The developer agent applies a fix to the Flutter repository or controller. The bug persists. A second fix is attempted. The bug still persists. On closer inspection, the API response was returning the wrong value from the start — the Flutter code was parsing it correctly.

**What went wrong:** The systematic-debugger classified the bug as Flutter-side without seeing the API log. The DATA GATE should have fired — this was a data mismatch bug — but the gate was bypassed (see DATA GATE bypass entry above). A hypothesis was formed based on source code. The hypothesis was wrong. Two fixes were applied to code that was not the problem.

**Fix:** Undo any Flutter changes that were applied without confirmed evidence. Obtain the API log. Verify whether the response contains the correct value. If the value is wrong in the response → this is a backend bug. Log it to `docs/backend_issues/backend_issues.md` and hand off to the backend team.

**How to prevent it:** DATA GATE must fire on every data mismatch bug, without exception. If a fix was applied and didn't work, and the original bug was a data value mismatch — the fix was built on an unconfirmed hypothesis. Do not attempt a second fix. Obtain the API log first.

---

### Mistake: Cross-screen event names not agreed before implementation — sender and receiver never connect

**Symptom:** One screen fires an event to update another screen. The second screen never updates. Both screens are running and their controllers are initialized. Debugging shows the event is being fired but the listener is never triggered.

**What went wrong:** The screen that fires the event used `eventBus.fire(MatchAcceptedEvent())`. The screen that listens used `eventBus.on<RequestAcceptedEvent>()`. Two developers independently named the same logical event differently — one called it `MatchAccepted`, the other called it `RequestAccepted`. Sender and receiver use different class names. The listener never matches.

**How it was found:** A badge count that should decrement after accepting a match request stayed at the old number. Investigation revealed two different event class names in the codebase for the same logical event.

**Fix:** Delete one of the event classes. Pick the canonical name (prefer the one that matches the domain entity). Update all senders and receivers to use the canonical class.

**How to prevent it:** Cross-screen event names must be agreed in `Flow_Requirements.md` before implementation starts. The FR document must include a "Cross-Screen Events" table: event name | fired by | consumed by. The developer agent must check this table before creating any event class — if the event already has a name in the FR, use that name exactly.

---

## You'll Know These Are Fixed When

Run this check after addressing any mistake from this chapter.

**Agent scope:** Launch the agent with a request outside its defined scope. It should redirect, not attempt to answer.

**Agent gate consistency:** Send the same trigger input three times across three separate sessions. The agent should fire the same gate with the same behavior every time.

**Pre-Step coverage:** Ask the agent what it found in `error_learnings.md` for the current module. If it can answer specifically, the Pre-Step is working. If it says "I don't have that information," the Pre-Step is missing or not loading the file.

**Raw prompt compliance:** Send a `bug::` trigger. In the same message, Main Claude should send only the structured 3-line prompt to systematic-debugger — nothing more. Check the agent's launch prompt in the tool call log to verify no investigation steps were added.

**Registry freshness:** Pick 5 entries from `component_registry.md` and confirm they all exist in the codebase. If all 5 are valid, the registry is current enough to trust.

**Output format stability:** Run a major agent (developer, systematic-debugger, planner) three times on different inputs. The output format should match the template in the agent file every time. If the format varies, the output template in the agent file needs to be made more explicit.

**GetX-specific checks:**
- Ask the developer agent to implement a bottom-nav tab screen. Verify the generated controller uses `Get.put(..., permanent: true)`.
- Ask the developer agent to implement a list that fetches from API. Verify the generated code uses `.assignAll()` not `=` for list replacement.
- Send `bug:: [data value wrong on screen]`. Verify the DATA GATE fires before any source file is read.

---

## Reference

| Category | Mistakes documented |
|----------|---------------------|
| Agent Design | 4 |
| Orchestra | 5 |
| CLAUDE.md | 3 |
| Memory System | 3 |
| Documentation | 3 |
| Behavioral Bugs | 4 |
| GetX-Specific | 5 |
| **Total** | **27** |

All mistakes in this chapter have corresponding prevention rules in earlier chapters. The cross-references:

| Mistake | Primary chapter |
|---------|----------------|
| Agent scope | [Chapter 8: Agent Creation Guide] — 8.1, 8.2 |
| Paragraph instructions | [Chapter 8: Agent Creation Guide] — 8.4 |
| Missing Pre-Step | [Chapter 10: Core Agents Deep Dive] — all agents |
| Output format | [Chapter 8: Agent Creation Guide] — 8.5 |
| Orchestra registration | [Chapter 9: Orchestra Management] — 9.2 |
| Wrong trigger category | [Chapter 9: Orchestra Management] — 9.3 |
| Foreground/background | [Chapter 9: Orchestra Management] — 9.4 |
| Raw vs. processed prompt | [Chapter 8: Agent Creation Guide] — 8.9 |
| Delegated output rewritten by parent | [Chapter 9: Orchestra Management] — 9.6 |
| CLAUDE.md size | [Chapter 4: CLAUDE.md File] |
| Agent instructions in CLAUDE.md | [Chapter 4: CLAUDE.md File] |
| Vague language | [Chapter 4: CLAUDE.md File] |
| claude-mem Pre-Step | [Chapter 11: MCP Plugins] |
| Auto-memory noise | [Chapter 12: Auto-Memory System] |
| error_learnings updates | [Chapter 14: Docs Folder Structure] |
| Backend verification loop | [Chapter 14: Docs Folder Structure] |
| Checkpoint entries | [Chapter 14: Docs Folder Structure] |
| Registry drift | [Chapter 22: Keeping the Setup Current] |
| DATA GATE bypass | [Chapter 10: Core Agents Deep Dive] — 10.2 |
| FR intake volume | [Chapter 10: Core Agents Deep Dive] — 10.1 |
| Instruction re-reads | [Chapter 16: Token Efficiency] |
| Brief integrity | [Chapter 8: Agent Creation Guide] — 8.5 |
| permanent: true rule | [Chapter 19: GetX + Clean Architecture] |
| RxList .assignAll() | [Chapter 19: GetX + Clean Architecture] |
| Obx scope | [Chapter 19: GetX + Clean Architecture] |
| Backend vs. Flutter classification | [Chapter 10: Core Agents Deep Dive] — 10.2 |
| Cross-screen event names | [Chapter 19: GetX + Clean Architecture] |

---

*This is the final chapter of the playbook.*
