# Agent Orchestration

## ⛔ MAIN CLAUDE FORBIDDEN ACTIONS (Read this first — always)

Main Claude is an **orchestrator only**. The following are permanently forbidden in the main conversation:

| Forbidden | Correct alternative |
|-----------|-------------------|
| Using `Edit` / `Write` on any `.dart` file | → delegate to `developer` agent |
| Using `Edit` / `Write` on `pubspec.yaml` / `pubspec.lock` | → delegate to `developer` agent |
| Writing implementation plan content directly | → use `planner` agent to produce content |
| Analyzing client feedback / change docs manually | → use `fr-analyst` agent |
| Applying code review fixes inline | → delegate corrections to `developer` agent |

**The only tools Main Claude uses directly:**
- `Agent` — to launch subagents
- `Read` / `Grep` / `Glob` — to validate agent output
- `Bash` — `flutter analyze` only, to verify agent output
- `Edit` — for `.md` config/rules files only (never `.dart` or `pubspec`)

---

## 🚨 MANDATORY FIRST ACTION CHECKPOINT

**BEFORE ANY IMPLEMENTATION - STOP AND CHECK THESE TRIGGERS:**

---

## 🐛 BUG / ISSUE TRIGGER — HIGHEST PRIORITY CHECK

If the human's message starts with `bug::` or `issue::` — this is ALWAYS a bug fix session.

**Exact format the human uses:**
```
bug:: [description of what the user sees]
issue:: [description of what the user sees]
```

**What you do immediately:**
```
1. LAUNCH systematic-debugger (foreground) — MANDATORY. No exceptions.
   Pass: the raw bug/issue description + screen/module inferred from description + project root.
   NOTHING ELSE. No investigation steps. No file suggestions. No hypotheses.

2. systematic-debugger runs its own gate sequence internally.
   TWO POSSIBLE RESPONSES — both are correct, handle each differently:

   RESPONSE A — "⏸️ DATA MISMATCH DETECTED — please share console/API log output"
   → The agent hit the DATA GATE. It found the endpoint name and is asking for the console log.
   → THIS IS CORRECT. Do NOT investigate yourself. Do NOT add extra analysis/instructions.
   → Copy the agent's message to the human word-for-word. Nothing more. Wait.
   → When human pastes the console block:
      - Stateful runtime: SendMessage to the same systematic-debugger agent ID.
      - Stateless runtime (this runner): launch systematic-debugger exactly once more with ONLY:
        1) original bug description,
        2) inferred screen/module,
        3) raw console block exactly as pasted.
         Forwarding contract:
         - Stateful: message body MUST be ONLY the raw pasted console block.
         - Stateless: payload MUST contain ONLY the three required raw context blocks above (no added analysis, hypotheses, or instructions).
      ❌ FORBIDDEN: "Here is the console log: [paste] Key observations: 1. The endpoint is... 2. The response contains..."
      ❌ FORBIDDEN: "The log shows X. Now investigate: 1. Find the screen... 2. Confirm if..."
      ❌ FORBIDDEN: Any sentence you wrote yourself — even one word before or after the paste
      ✅ CORRECT (stateful):   The raw console block exactly as the human pasted it. Zero additions.
      ✅ CORRECT (stateless):  Exactly the 3 required raw blocks only (original bug, inferred screen/module, raw console block). Zero added analysis/instructions.

   RESPONSE B — Handoff Brief with root cause
    → Proceed to step 4 ONLY when the brief explicitly includes evidence-confirmed root cause.
    → Required evidence status in brief: `CONFIRMED` (runtime API log proof and/or direct code evidence).
    → If the brief uses assumption language (for example: likely, maybe, appears, probably) or lacks evidence lines,
       DO NOT launch developer. Ask the human for missing confirmation inputs first.

3. NEVER do this when you receive RESPONSE A:
   ❌ "It seems the agent didn't run — let me investigate directly"
   ❌ "The agent tool seems to be returning meta-commentary" — launch the agent again
   ❌ Launch a second or third agent because the first one "didn't run properly"
   ❌ Ask the human to add the logs yourself
   ❌ Form your own hypothesis about the bug
   ❌ Add observations, summaries, or "Key points from the log" before forwarding to agent
   The DATA GATE response IS the agent working correctly.
   Stateful transport: one launch continues via same ID.
   Stateless transport: one additional launch with accumulated raw context is allowed.

4. ROOT-CAUSE LOCATION GATE (MANDATORY)
   - If systematic-debugger confirms Flutter-side root cause → proceed to step 5.
   - If systematic-debugger confirms backend-side root cause → skip developer/code-reviewer/security-reviewer.
     Ensure backend issue is logged in `docs/backend_issues/backend_issues.md`, then present backend handoff summary to human.
5. LAUNCH developer (foreground) — Correction Pass Mode only (Flutter-side only)
   Pass: root cause + fix description from systematic-debugger
   Precondition: systematic-debugger brief evidence status is `CONFIRMED`.
6. developer applies the minimal fix only
7. developer runs flutter analyze
8. APPLY REVIEW GATE (MANDATORY)
   - Tier 1 (simple UI/widget/text): skip code-reviewer and security-reviewer.
   - Tier 2 (logic/state/data flow): run code-reviewer with strict targeted scope.
   - Tier 3 (shared files/new API/auth/storage/input): run code-reviewer; run security-reviewer only if sensitive surface changed (auth, tokens, Hive, socket events).
9. Present summary to human: root cause, fix applied, files changed, review gate used
```

**🚨 PROMPT CONSTRUCTION RULE — NEVER VIOLATE:**
When launching `systematic-debugger` for the INITIAL bug report, pass ONLY this — nothing more:
```
Bug description: [exact user message]
Screen/module: [inferred from description]
Project root: {{PROJECT_ROOT}}
```
For STATELESS follow-up after DATA GATE (human pasted logs), launch once more with ONLY:
1) original bug description,
2) inferred screen/module,
3) raw pasted console block.
FORBIDDEN in the prompt: investigation phases, file paths to check, hypotheses to explore,
"check if X param is missing", "read rest_apis.dart", "find the endpoint", "return confirmed root cause".
Reason: pre-loaded investigation instructions bypass the agent's DATA GATE, causing it to skip
to static analysis and return fabricated HIGH-confidence root causes without runtime evidence.

**CRITICAL:** For `bug::` / `issue::` — NEVER skip systematic-debugger. NEVER go direct to developer.
The systematic-debugger's purpose is to find the ROOT CAUSE before any code is changed.
A developer who skips systematic-debugger and guesses the fix will create new bugs.

---

## Development Request Triggers (LAUNCH IMMEDIATELY)

**Step 0 — Before launching developer, check: does an implementation plan already exist?**
- ✅ `docs/FR/**/*_Implementation_Plan.md` exists for this feature → skip planner, go straight to developer
- ❌ No plan exists AND feature is complex (>3 files, new module, cross-module) → launch planner first
- ❌ Bug fix or minor change (any size) → always use the Bug/Issue Trigger above

| User Request Pattern | Required Agent | Launch Mode | Condition |
|---------------------|---------------|-------------|-----------|
| `bug:: [description]` | `systematic-debugger` → (`developer` OR backend handoff) | **foreground** | ALWAYS — never skip debugger |
| `issue:: [description]` | `systematic-debugger` → (`developer` OR backend handoff) | **foreground** | ALWAYS — never skip debugger |
| "client gave feedback / changes / review doc" | `fr-analyst` → `developer` | **foreground** | ALWAYS — fr-analyst maps feedback to files, classifies UI/text vs logic/API, then developer implements only the approved changes |
| "update based on [doc/feedback/comment]" | `fr-analyst` → `developer` | **foreground** | ALWAYS — never analyze feedback manually in main conversation |
| "develop [module]" | `ui-design-enforcer` → `developer` | **foreground** | When module includes new screens |
| "develop [module]" | `developer` | **foreground** | Implementation plan exists, no new screens |
| "develop [module]" | `planner` → `developer` | **foreground** | No implementation plan, complex feature |
| "implement [feature]" | `ui-design-enforcer` → `developer` | **foreground** | Feature includes new screen(s) |
| "implement [feature]" | `developer` | **foreground** | No new screens (logic/data only) |
| "build [system]" | `planner` → `developer` | **foreground** | Always plan first for new systems |
| "fix [bug]" (informal) | `systematic-debugger` → (`developer` OR backend handoff) | **foreground** | Treat same as `bug::` trigger |
| "add [component]" | `developer` | **foreground** | Always skip planner — minor change |
| "create [file/class/method]" | `developer` | **foreground** | Always skip planner — minor change |
| ANY other code writing request | `developer` | **foreground** | Even single lines - NO manual coding |

### Planning Request Triggers (OPTIONAL)
| User Request Pattern | Required Agent | Launch Mode | When |
|---------------------|---------------|-------------|------|
| "plan [feature]" | `planner` | **foreground** | **For planning-only requests** |
| "design approach for [system]" | `planner` | **foreground** | **For architectural planning** |

---

## Post-Implementation Quality Tiers

> The tier is determined by the systematic-debugger (for bugs) or main Claude (for features).
> Match the tier to the change — never over-review a simple fix.

---

### ⚡ Tier 1 — FAST TRACK (Simple UI / Widget Fix)
**When:** Widget property change, widget removal/addition, text/label change, maxLength, color, reorder, hide/show.

| Check | Required | Notes |
|-------|----------|-------|
| `flutter analyze` | ✅ YES | Developer runs this — must be clean |
| code-reviewer agent | ❌ NO | Not needed for 1-2 line widget changes |
| ui-reviewer agent | ❌ NO | Not needed |
| security-reviewer | ❌ NO | Not needed |
| Summary | ✅ YES | Developer outputs: what changed, file, line |

**Summary format for Tier 1 (developer produces this, no separate agent):**
```
✅ Fix applied
File: lib/src/features/<module>/presentation/<screen>.dart:<line>
Change: [what was added/removed/changed — one line]
flutter analyze: clean
```

---

### 🔍 Tier 2 — LOGIC FIX (State / Data / Behavior Fix)
**When:** GetX state, Obx, API data flow, Socket.IO events, pagination, Hive, navigation result, null handling.

| Check | Required | Notes |
|-------|----------|-------|
| `flutter analyze` | ✅ YES | Must be clean |
| code-reviewer agent | ✅ YES | **Targeted** — only changed files, not full scan |
| ui-reviewer agent | ❌ NO | Unless fix changes visible UI layout |
| security-reviewer | ❌ NO | Unless fix touches auth/token/Hive storage/socket events/API input boundary |
| doc-updater | ❌ NO | Unless a new pattern was introduced |
| Summary | ✅ YES | code-reviewer produces this |

**Code-reviewer instruction for Tier 2:** Review ONLY the changed function/method and its direct callers. Do not scan the entire file. Do not grep project-wide unless a dependency question arises.

---

### 🏗️ Tier 3 — NEW FEATURE / SHARED FILE CHANGE
**When:** New screen, new API endpoint, shared model change, GetX Binding modified, socket service changed, new component, cross-module change.

| Phase | Agent | Mode | Correction Loop | When |
|-------|-------|------|----------------|------|
| 1 — UI Review | `ui-reviewer` | foreground | Max 2 passes | Only if new screen(s) added |
| 2 — Code Review | `code-reviewer` | foreground | 1 pass → developer fixes → done | Always |
| 3 — Security Review | `security-reviewer` | foreground | 1 pass → fix CRITICAL | Only if: new API, auth, token, Hive storage, socket events, user input, payment, file upload, permission boundary |
| 4a — Doc Update | `doc-updater` | background | No loop | Always |
| 4b — Map Update | `project-map` | background | After doc-updater | Always |
| — | `build-error-resolver` | foreground | User-triggered only | User-triggered only |

### ✅ Reviewer Gate + Stateless Scope Contract (MANDATORY)

Before launching `code-reviewer` or `security-reviewer`, classify the fix tier and enforce this contract.

**Gate decision:**
- Tier 1: no reviewer agents.
- Tier 2: code-reviewer targeted; add security-reviewer only if sensitive-surface changes.
- Tier 3: code-reviewer always; add security-reviewer only if sensitive-surface changes.

**Sensitive-surface changes (security-reviewer trigger):**
- Authentication, tokens, session handling
- API endpoints/request builders/response validation
- Local Hive storage of sensitive values
- User input validation/sanitization paths
- Socket.IO event emission/reception on auth-gated rooms
- File uploads, permissions/role checks

**Scope contract for stateless agents (required on every launch):**
- Include changed file paths explicitly.
- Include changed methods/functions explicitly.
- Include direct callers only.
- State "Do not scan whole project unless dependency proof is required."
- Include previous reviewer findings when relaunching after fixes.

**Prompt template — code-reviewer (targeted):**
```
Tier: [Tier 2 or Tier 3]
Changed files: [exact list]
Changed methods: [exact list]
Direct callers: [exact list or "none"]
Task: Review only listed methods and direct callers. Do not scan entire file/project unless dependency proof is required.
Output: Critical/high findings first with file:line and minimal fix direction.
```

**Prompt template — security-reviewer (conditional):**
```
Trigger reason: [which sensitive surface changed]
Changed files: [exact list]
Data flow scope: [entry point -> storage/network/sink]
Task: Review only this scope for exploitable issues. Ignore unrelated modules.
Output: Critical vulnerabilities first with file:line and concrete mitigation.
```

> **Why foreground?** Main Claude must read each agent's output to feed corrections to developer agent. Background agents don't allow this feedback loop.

---

## 🔥 CRITICAL WORKFLOW SEQUENCES

**For `bug::` / `issue::` Reports:**
```
1. systematic-debugger classifies the bug:
   ├─ ⚡ FAST TRACK (widget/UI fix)
   │    → developer applies fix
   │    → flutter analyze
   │    → developer outputs Tier 1 Summary (no code-reviewer)
   │    → done
   │
   └─ 🔍 FULL INVESTIGATION (logic/state/crash)
        → systematic-debugger runs Phase 1-3 → produces Handoff Brief
            → root-cause location gate:
                  Flutter-side root cause → developer correction pass
                  Backend-side root cause → log in docs/backend_issues/backend_issues.md (no developer pass)
            → flutter analyze (Flutter-side path only)
         → apply reviewer gate (Flutter-side path only):
               Tier 2 → code-reviewer (TARGETED — changed files only)
                   + security-reviewer only if sensitive surface changed
               Tier 3 + sensitive surface → code-reviewer + security-reviewer
        → done
```

**For Development Requests:**
```
1. User: code request → run planner decision gate first, then launch `developer` when gate allows
2. Developer executes COMPLETE CLAUDE.md workflow:
   - Module intake and FR analysis
   - Per-feature implementation loops with checkpointing
   - Code implementation (per {{ARCHITECTURE}} layer order — see ARCHITECTURE.md)
   - Self-validation checklists
   - Documentation updates (component_registry, api_registry, error_learnings)
   - Pipeline status marked REVIEW
3. Developer reports completion → MAIN CLAUDE takes over
4. Main Claude runs Post-Implementation Quality Loop:
   - ui-reviewer → developer fixes → ui-reviewer (max 2 passes) [new screens only]
   - apply reviewer gate:
     Tier 1 → skip code-reviewer and security-reviewer
     Tier 2 → code-reviewer (targeted scope only)
     Tier 3 → code-reviewer + conditional security-reviewer (sensitive changes only)
   - doc-updater (background, Phase 4a)
   - project-map (background, Phase 4b — after doc-updater)
5. Main Claude presents final summary to user
```

**For Complex Features WITHOUT an existing plan:**
```
1. Check docs/FR/**/*_Implementation_Plan.md — does a plan exist for this feature?
2. NO plan found → Launch `planner` first (foreground)
3. Planner creates detailed implementation strategy
4. Launch `developer` with planner's strategy (foreground)
5. Developer executes complete workflow based on plan
```

**For Complex Features WITH an existing plan (FR pipeline complete):**
```
1. Check docs/FR/**/*_Implementation_Plan.md — plan exists ✅
2. Skip planner — FR docs ARE the plan
3. Launch `developer` directly with FR file paths as context (foreground)
4. Developer executes complete workflow based on FR docs
```

**NO EXCEPTIONS. NO BYPASSING. VIOLATION = WORKFLOW FAILURE.**

---

## Memory Check (MANDATORY — Before ANY Agent Launch)

Before launching any agent for any task, check:
```
1. docs/memory/error_learnings.md — grep for module/feature name + symptom keywords
2. docs/memory/component_registry.md — grep for widget name before creating new
3. docs/memory/api_registry.md — grep for endpoint before adding new API function
4. docs/FR/_pipeline_status.md — check if similar work is already in progress
```

> If a relevant error learning exists → treat it as a hypothesis, not proof.
> For `bug::` / `issue::`, NEVER skip systematic-debugger and NEVER auto-apply a memory fix without current-session confirmation.

---

## Agent Modes

**Foreground agents** — used when main Claude needs the output to decide next steps (review loops, correction briefs, bug fix output).
**Background agents** — used when output is not needed immediately (doc-updater, project-map).

> `flutter analyze` is run **by the developer agent** after every fix. Build-error-resolver is only launched when the user explicitly reports a build error.

---

## Available Agents

Located in `.claude/agents/` (project-level):

| Agent | Purpose | Trigger |
|-------|---------|---------|
| `systematic-debugger` | **Root cause investigation for all bug:: and issue:: reports; logs backend-confirmed issues to docs/backend_issues/backend_issues.md** | `bug::` / `issue::` prefix — ALWAYS first |
| `fr-analyst` | Convert requirements to FR documentation packages | New feature described |
| `planner` | Implementation planning and architectural strategy | Complex feature, no FR exists |
| `developer` | **Complete CLAUDE.md development workflow executor** | Any code request; Correction Pass Mode for bug fixes |
| `ui-reviewer` | Post-implementation UI design quality review | Phase 1 of Quality Loop (new screens only) |
| `code-reviewer` | Code quality, GetX conventions, Clean Architecture | Phase 2 of Quality Loop; bug fixes only when reviewer gate selects Tier 2 or Tier 3 |
| `security-reviewer` | Security vulnerabilities and auth/API/socket review | Phase 3 of Quality Loop; conditional on sensitive-surface changes |
| `doc-updater` | Update docs/memory/ registries after changes | Phase 4a of Quality Loop |
| `project-map` | Regenerate project structure map + deep change impact matrix | Phase 4b — after doc-updater; on-demand before touching shared files |
| `tdd-guide` | Test-driven development, RED/GREEN/REFACTOR | Developer triggers per feature |
| `architect` | System design and architectural decisions | Complex cross-module decisions |
| `build-error-resolver` | Fix build/compile errors | User-triggered only |
| `e2e-runner` | Integration test generation and execution | User-triggered only |
| `refactor-cleaner` | Dead code removal and consolidation | User-triggered only |

---

## Parallel Execution

ALWAYS launch independent agents in parallel — never sequentially when they don't depend on each other:

```
# GOOD: one message, multiple Agent tool calls
- code-reviewer on auth module (background)
- security-reviewer on auth module (background)

# BAD: wait for first to finish before starting second
```

---

## Multi-Perspective Analysis

For complex architectural problems, use split-role sub-agents:
- Senior engineer — correctness and architecture
- Security expert — vulnerabilities and exposure
- Consistency reviewer — naming, patterns, conventions
