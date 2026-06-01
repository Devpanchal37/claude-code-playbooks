# Chapter 22: Keeping the Setup Current

> **Applies to:** Both
> **Prerequisites:** Chapter 8: Agent Creation Guide, Chapter 9: Orchestra Management, Chapter 14: Docs Folder Structure
> **Estimated read + setup time:** ~20 minutes

---

## TL;DR

Agent setups decay. An agent written for a project at week 4 has assumptions baked in — folder paths, shared entities, API patterns — that will be wrong by week 16. Without a maintenance protocol, the setup starts producing outdated code and wrong advice while appearing to work. This chapter defines what triggers a maintenance pass, what each trigger requires you to update, and a monthly health check that catches decay before it causes rework.

---

## What This Is

"Keeping the setup current" is not about updating Claude Code itself — it is about keeping your project-level configuration (agents, CLAUDE.md, instruction files, docs) aligned with the actual current state of the project.

The setup has two types of staleness:

| Type | How it happens | How it shows |
|------|---------------|--------------|
| **Structural staleness** | Project grows new modules, shared entities, new API patterns — agents still assume the old structure | Developer agent generates files in wrong locations; planner creates plans for non-existent entities |
| **Behavioral staleness** | Agent output quality gradually degrades — agents skip gates, produce shorter analyses, miss known mistake patterns | Code-reviewer stops catching violations; systematic-debugger produces assumptions instead of confirmed root causes |

Both types are silent. There is no error message when an agent produces stale output. The only way to catch them is regular, deliberate review.

---

## Why It Exists (The Problem It Solves)

**Without a maintenance protocol:**

A project starts with three modules. The developer agent knows the shared entities, the API patterns, and the folder structure. By month 3, there are nine modules. Three new shared entities were added. An API pattern changed. But no one updated `ARCHITECTURE.md` or the developer agent's Pre-Step entity list.

The developer agent starts generating code that references old shared entity shapes. The code-reviewer doesn't catch it because the code-reviewer's review criteria was also never updated. The planner generates plans that sequence implementation in an order that doesn't match the current dependency graph.

Rework cost at this point: 2–3 days to untangle what the agent produced versus what the project actually is.

**With this protocol:** Each triggering event has a specific checklist. The checklist takes 15–30 minutes. Rework is caught at the feature level, not the module level.

---

## What Decays and Why

### Agents

Agents are written at a specific moment in time. Their instructions reference:
- File paths that may move as the project restructures
- Entity names that may be renamed or split
- API patterns that may be superseded by newer conventions
- Compliance rules that may need additions as new antipatterns are discovered

**Decay signal:** The agent produces output that was correct 2 months ago but conflicts with current code.

### `CLAUDE.md`

CLAUDE.md grows over time as more rules are added. After 6 months, it may have contradictory rules (an early rule that was softened by a later rule, neither one removed). It may also reference docs that no longer exist or agents that were renamed.

**Decay signal:** Main Claude behaves inconsistently — sometimes following a rule, sometimes ignoring it. Usually caused by contradictory rules in CLAUDE.md, not by Claude itself.

### Instruction files (`ARCHITECTURE.md`, `UI_INSTRUCTION.md`, `API_INSTRUCTION.md`)

These files define what "correct" looks like. When the project adopts a new pattern — a new approach to error handling, a new design token, a new API response structure — the instruction files must be updated first. If they aren't, every subsequent agent run generates code to the old standard.

**Decay signal:** The developer agent generates code that the team has moved away from, but which matches what `ARCHITECTURE.md` still says.

### `docs/memory/` registries

`component_registry.md` and `api_registry.md` grow stale when:
- A component is refactored and renamed — the old name is still in the registry
- An endpoint is deprecated — the registry still shows it as available
- A component is deleted — the registry still points to it

**Decay signal:** An agent recommends reusing a component that no longer exists, or building an API call against an endpoint that has been replaced.

### `error_learnings.md`

Error learnings are always additive, but they can become misleading:
- An entry documents "never do X" — but a library update now makes X correct
- An entry documents a framework-specific pattern — but the project switched libraries
- An entry references a file path that no longer exists

**Decay signal:** An agent avoids a pattern that is now correct, citing an error_learnings entry that is no longer valid.

---

## Maintenance Triggers

Each of these events requires a specific maintenance pass. Do not defer — deferred maintenance compounds.

### Trigger 1 — New module added

A new feature module is created and reaches the DONE state in the pipeline.

**Required updates:**

1. **project-map agent scope:** If the project-map agent has a hardcoded list of modules it scans, add the new module. Run the project-map agent to regenerate `docs/maps/project_map.md`.

2. **`docs/memory/component_registry.md`:** Verify the new module's reusable components are registered. If the developer agent didn't register them, add the entries manually using the registry format.

3. **`docs/memory/api_registry.md`:** Verify the new module's API endpoints are registered.

4. **`docs/FR/_pipeline_status.md`:** Confirm the new module's entries are marked DONE. Clean up any stale IN_PROGRESS or REVIEW entries that were left from the development cycle.

5. **`ARCHITECTURE.md` canonical module reference:** If this new module is more cleanly structured than the previously designated canonical reference module, update the reference. See [Chapter 19: GetX + Clean Architecture] for the canonical module concept.

---

### Trigger 2 — Shared entity changed

A change is made to an entity that multiple modules depend on — a field is added, removed, or renamed.

**Required updates:**

1. **`docs/maps/project_map.md`:** Run the project-map agent immediately after the entity change is committed. The Blast Radius Matrix must reflect the new field structure.

2. **Developer agent Pre-Step entity list:** If the developer agent's Pre-Step explicitly lists shared entities to check before modifying, update the list to reflect the new field names.

3. **`docs/memory/component_registry.md`:** Any registered component that displays or processes the changed field must have its registry entry updated.

4. **`error_learnings.md`:** If the entity change exposed a pattern that caused bugs — for example, modules that cached the old field name — add an entry so agents avoid that pattern in future work.

---

### Trigger 3 — New API pattern introduced

A new approach is adopted for HTTP calls, response parsing, authentication headers, or error handling — and the new approach is meant to be the standard going forward.

**Required updates:**

1. **`docs/instructions/API_INSTRUCTION.md`:** Update the pattern documentation to reflect the new standard. Mark the old pattern as deprecated if it still appears in existing code.

2. **Developer agent:** If the developer agent's implementation loop has an explicit step for creating API calls, verify it references the instruction file that now has the updated pattern.

3. **`docs/memory/api_registry.md`:** Add a note to any endpoint entries that still use the old pattern: `[PATTERN: old — update on next touch]`. This prevents the agent from using an old endpoint as a template for new ones.

4. **Code-reviewer agent:** If the code-reviewer checks for API pattern compliance, update its criteria to include the new pattern and flag the old one.

---

### Trigger 4 — Recurring mistake discovered

A mistake appears in two or more features during code review. This is a signal that an agent is not catching it at generation time.

**Required updates:**

1. **`error_learnings.md`:** Add the entry immediately with Mistake / Correct / Pattern format.

2. **Developer agent widget placement gate:** If the mistake is a widget-level or code-generation-level pattern, add it as a check in the developer agent's widget placement gate. The gate fires before every widget is placed — this is where the mistake should be caught.

3. **Code-reviewer criteria:** If the mistake is something the code-reviewer should catch but didn't, add it to the code-reviewer's review criteria.

4. **`CLAUDE.md` zero-tolerance table:** If the mistake is severe enough to warrant project-ending status (ships to production → user impact), add it to the zero-tolerance table.

---

### Trigger 5 — Agent output quality degrading

You notice an agent producing shorter analyses, skipping gates, making assumptions instead of confirming, or generating output that doesn't match its output format specification.

**Required updates:**

1. **Run the validation prompt from [Chapter 8: Agent Creation Guide]:** Give Main Claude the validation prompt and test 5 scenarios for the degraded agent. Identify which gate is failing.

2. **Use the feedback form from [Chapter 8: Agent Creation Guide]:** Fill in the exact scenario, expected behavior, actual behavior, and root cause classification.

3. **Update the agent file:** Based on the feedback form root cause:
   - Gate trigger too vague → tighten the trigger condition
   - Gate was advisory prose → rewrite as numbered list with mandatory language
   - New input type not covered → add it to the classification table
   - Output format drifted → restore the explicit output template

4. **Re-run the failing validation scenario:** Confirm the specific gate now behaves correctly.

5. **Do not assume other gates are fine:** When one gate degrades, check the two adjacent gates in the sequence — behavioral decay is rarely isolated to a single step.

---

## Monthly Health Check

Run this check once per month, or at the end of every major feature release — whichever comes first.

### The check

**Step 1 — CLAUDE.md audit (5 minutes)**

Read `CLAUDE.md` from top to bottom. For each rule, ask:
- Is this rule still true? (project hasn't moved past it)
- Is there another rule in this file that contradicts it?
- Does this rule reference a file, agent, or path that still exists?

Flag any rule that fails these checks. Update or remove it.

**Step 2 — `agents.md` trigger audit (5 minutes)**

For each trigger entry in `agents.md`:
- Does the agent file it references still exist with the same name?
- Is the trigger pattern still the correct way to invoke this workflow?
- Is the launch mode (foreground/background) still correct for this step?

**Step 3 — Agent health check for the 4 core agents (15 minutes)**

Run the validation prompt from [Chapter 8: Agent Creation Guide] for each of these agents:
- Developer agent
- Systematic debugger
- Planner agent
- Code-reviewer

For each: test one simple scenario and one complex scenario. Verify the agent fires the correct gates and produces output in the correct format. Do not test edge cases — the goal is to confirm the happy path still works. Edge cases are covered by the feedback form process (Trigger 5 above).

**Step 4 — Registry freshness check (5 minutes)**

Pick 5 entries at random from `component_registry.md` and 5 from `api_registry.md`. Verify each one:
- The file path in the entry still exists (`git ls-files [path]`)
- The component or endpoint name still matches what's in the code (`grep -r "[name]" lib/`)

If more than 1 of 5 entries is stale, run a full registry audit — the registries have drifted significantly.

**Step 5 — `error_learnings.md` review (5 minutes)**

Scan the entries. For each one older than 3 months:
- Is the mistake still possible with the current codebase? (library updated, pattern removed)
- Does the entry reference a file or entity that still exists?

Mark stale entries as `[SUPERSEDED — reason]` at the top of the entry, same as the pattern in [Chapter 20: Updating the Architecture or State Management].

### Health check output

After completing the 5 steps, write a one-line entry in `docs/memory/error_learnings.md` under a new heading:

```
## [YYYY-MM-DD] Monthly Health Check
**Status:** All clear | X issues found and fixed
**Fixed:** [brief list of what was corrected, if anything]
**Pattern:** [any systemic decay pattern observed]
```

This entry serves as a timestamp and audit trail. If a pattern of decay is appearing in multiple monthly checks (e.g., registry always drifts after new modules), that is a signal to automate the check or adjust the developer agent's documentation step.

---

## Validation

### Validation Test 1: Decay detection — stale registry entry

**Purpose:** Verify you can detect a stale registry entry before it causes agent rework.

**Setup:** Delete or rename a component that is registered in `component_registry.md`. Do not update the registry entry.

**Trigger:**
```bash
git ls-files lib/src/ | grep "[old-component-name]"
```

**Expected result:** No output — the file doesn't exist.

**Then:**
1. Ask the developer agent to build a feature that would logically reuse that component
2. Observe whether the developer agent recommends the now-deleted component from the registry

**If the agent recommends a deleted component:** The registry has stale entries. Run the registry freshness check from Step 4 above on all entries, not just a random sample.

---

### Validation Test 2: Agent health — gate still fires

**Purpose:** Verify a specific agent gate has not decayed.

**Setup:** Use the systematic-debugger's DATA GATE as the test case.

**Trigger:**
```
bug:: The profile count shows 0 but profiles are visible on screen.
```

**Expected result:** Systematic-debugger fires the DATA GATE immediately: `⏸️ DATA MISMATCH DETECTED — please share the console/API log output`. It does NOT read source files or produce a hypothesis.

**If the agent reads source files and produces a hypothesis instead:** The DATA GATE has decayed. Run the validation prompt from Chapter 8 for systematic-debugger, find the gate that is failing, and apply the feedback form process (Trigger 5 above).

---

## Common Mistakes

### Mistake 1: Treating maintenance as optional

**Symptom:** Agent output is "close enough." Developers start manually correcting what agents produce instead of updating the agents. Within 4–6 weeks, the setup is being worked around rather than worked with.

**Cause:** Maintenance feels like overhead when it is actually the thing that keeps the overhead low. Each skipped maintenance pass makes the next development cycle cost more in corrections.

**Fix:** Book the monthly health check as a recurring calendar item. 30 minutes per month prevents hours of rework per sprint.

---

### Mistake 2: Updating docs but not agents, or agents but not docs

**Symptom:** `ARCHITECTURE.md` says one thing; the developer agent generates another. Code-reviewer flags code that matches the instruction file. Conflicting sources of truth create unpredictable agent behavior.

**Cause:** A trigger-4 or trigger-3 maintenance pass was completed halfway. The instruction file was updated but the consuming agents were not, or vice versa.

**Fix:** Every maintenance trigger has a complete list of files to update. Never update the first item on the list and skip the rest — each item is a required update, not a suggestion.

---

### Mistake 3: Adding to error_learnings but not updating the agent gate

**Symptom:** The same mistake appears in code review across multiple features even though it's in `error_learnings.md`. The agent reads the entry during its Pre-Step but does not prevent the pattern during code generation.

**Cause:** Adding to error_learnings.md documents the mistake but does not prevent it. The prevention comes from adding the check to the developer agent's widget placement gate or the code-reviewer's criteria.

**Fix:** For every error_learnings entry, explicitly decide: is this severe enough to add to the widget placement gate? If yes, add it there. If no, the entry serves as a reminder only — acceptable for rare or ambiguous patterns.

---

### Mistake 4: Running the health check but not recording it

**Symptom:** By the third monthly check, no one remembers whether the registry was audited last month or two months ago. The check becomes irregular and its value as a decay-detection signal is lost.

**Cause:** The health check results were not written to `error_learnings.md`.

**Fix:** Always write the one-line entry at the end of each health check, even if the result is "all clear." The audit trail is the value — it shows decay trends over time.

---

### Mistake 5: Waiting for visible failure before running the health check

**Symptom:** The health check is only run after a developer notices the developer agent generating wrong code or a code-reviewer missing an obvious violation. By this point, the decay has already produced rework.

**Cause:** Health checks feel unnecessary when everything appears to be working. Decay is invisible until it tips into visible failure.

**Fix:** The monthly cadence is the signal, not visible failure. If the health check passes with no issues, it took 30 minutes and confirmed the setup is healthy — that is a good outcome. If it finds issues, it prevented rework. Both outcomes justify the time.

---

## [Flutter-GetX Specifics]

### Additional decay surfaces in the GetX setup

Playbook B has more moving parts than a generic Flutter setup. These components decay faster and have specific maintenance actions beyond what the generic triggers cover.

---

### GetX compliance rules decay

The `CLAUDE.md` zero-tolerance table is a living contract. Two things cause it to go stale:

**1 — New antipatterns discovered but not added:**
When a new zero-tolerance violation is found (e.g., a new type of hardcoded value, a new way developers bypass `ColorHelper`), it must be added to the table. The table is only useful if it covers everything that has been found to cause production issues.

Check the zero-tolerance table during each monthly health check:
- Are there any recurring code-review findings in the last month that aren't in the table?
- Do all items in the table still reference valid parts of the codebase (`ColorHelper`, locale key format, font name)?

**2 — Items that no longer apply:**
If the project switches UI libraries or drops a design system dependency, table entries that reference the old library become misleading noise. Mark them as `[REMOVED — reason]` rather than deleting them — the reasoning for why they existed is valuable.

---

### Widget placement gate maintenance

The developer agent's widget placement gate is the most active enforcement mechanism in the setup. It fires before every widget is placed. Because it runs so frequently, it is also the most likely to develop gaps as new patterns are introduced.

After each new GetX pattern is adopted on the project, check the widget placement gate:
- Does it check for this pattern?
- Does the check fire at the right moment (before placement, not after)?

Specific checks to verify are still present and working:

| Check | Gate behavior |
|-------|--------------|
| `Color(0xFF...)` usage | Blocks — must use `ColorHelper.xxx` |
| `Colors.xxx` usage | Blocks — must use `ColorHelper.xxx` |
| String literal in widget file | Blocks — must use `locale.xxx` |
| Wrong font family | Blocks — must be `'Plus Jakarta Sans'` |
| Missing shimmer on async load | Blocks — all async screens must have loading state |
| `Obx` wrapping non-observable widget | Flags — `Obx` child must access `.value` or a reactive observable |
| Controller in `IndexedStack` tab without `permanent: true` | Blocks — will auto-dispose unexpectedly |

If any of these checks are missing from the gate, add them. The gate catches these at generation time — far cheaper than catching them in code review.

---

### GetX error_learnings entries — decay faster than generic entries

GetX-specific entries in `error_learnings.md` are tied to a specific version of GetX's behavior. Some entries that were correct for GetX 4.6.x may be wrong for GetX 4.7.x. During each monthly health check, scan entries that reference:
- `Obx` closure behavior
- `RxList` mutation patterns
- Controller disposal lifecycle
- `Get.put` vs. `Get.lazyPut` behavior

For each entry: check if the described behavior matches the current GetX version in `pubspec.yaml`. If a GetX version bump introduced a change, mark the affected entries superseded and add a corrected entry with the current version number in the title:

```
## [SUPERSEDED — GetX 4.7.3 changed behavior] RxList must use .assignAll()
## [2025-01-15] GetX 4.7.3 — RxList .assignAll() still required; = operator still incorrect
```

---

### Canonical reference module — update when a better example exists

The `ARCHITECTURE.md` canonical reference module is the module developers (and the planner agent) use as a structural template for new modules. As the project matures, early modules often have imperfect structure. Later modules, implemented with more experience, are cleaner.

During each major feature release review, ask: is the current canonical module still the best structural example in the codebase? If a newly completed module is cleaner — more consistent naming, cleaner layer separation, better test structure — update the canonical reference.

Update in:
1. `docs/instructions/ARCHITECTURE.md` — the canonical module line
2. The planner agent — the reference module in its plan template

This single update propagates correct structure to every new feature going forward.

---

### `API_INSTRUCTION.md` and versioned endpoint changes

If the backend API introduces versioned endpoints (e.g., `/api/v1/` → `/api/v2/`), update `API_INSTRUCTION.md` to specify which version to use for new endpoints. Add a migration note for existing endpoints:

```
# Endpoint versioning
New endpoints: use /api/v2/ prefix
Existing endpoints: remain on /api/v1/ until migrated — see api_registry.md for per-endpoint version
```

Update `api_registry.md` entries with a `[VERSION: v1 — migrate to v2 on next touch]` note for all endpoints that have not yet been migrated. The developer agent will read this note and know to use the updated path when building new functionality that touches an old endpoint.

---

## Reference

| Item | Value |
|------|-------|
| Maintenance triggers | New module, shared entity change, new API pattern, recurring mistake, degrading agent |
| Health check cadence | Monthly or at end of every major feature release |
| Health check duration | ~30 minutes |
| Health check output | One-line entry in `docs/memory/error_learnings.md` |
| Agent validation prompt | See [Chapter 8: Agent Creation Guide] — Validation subsection |
| Agent feedback form | See [Chapter 8: Agent Creation Guide] — Feedback Form subsection |
| Stale entry format | `[SUPERSEDED — reason]` prefix on the entry |
| GetX-specific check | Widget placement gate — verify all 7 checks are still present after every GetX update |
| Canonical module update | `ARCHITECTURE.md` + planner agent — update when a better module example exists |

---

*Next: [Chapter 21: Mistakes & Lessons Learned]*
