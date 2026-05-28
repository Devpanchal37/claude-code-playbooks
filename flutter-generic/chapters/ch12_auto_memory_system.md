# Chapter 12: Auto-Memory System

> **Applies to:** Both
> **Prerequisites:** [Chapter 11: MCP Plugins (Claude Mem)]
> **Estimated read + setup time:** ~15 minutes

---

## TL;DR

Auto-memory is a folder of plain Markdown files in `.claude/projects/[hash]/memory/` that Claude reads across sessions to remember user preferences, corrections, and project state. Unlike the Claude Mem MCP database (which stores discovered patterns in a searchable semantic database), auto-memory is human-readable, directly editable, and organized by type — feedback, user, project, reference. `MEMORY.md` is the index Claude reads first to decide which files to load. Without this system, Claude resets to generic defaults every session and repeats mistakes you already corrected.

---

## What This Is

Auto-memory is file-based persistent memory. It lives in a folder that Claude Code creates per project: `.claude/projects/[project-hash]/memory/`. Each memory is a separate Markdown file with YAML frontmatter that declares its name, description, and type. `MEMORY.md` is the index listing all memory files — Claude reads this first and uses the one-line descriptions to decide which files are relevant to the current task.

This system runs entirely in plain text. You can open any memory file, edit it, delete an entry, or add new ones manually. Nothing is hidden in a database.

### How It Compares to Claude Mem MCP

These two systems coexist and serve different access patterns.

| | Auto-Memory | Claude Mem MCP |
|--|-------------|----------------|
| **Storage format** | Markdown files on disk | Structured searchable database |
| **Search** | Claude reads MEMORY.md index → opens relevant files | Semantic search via `smart_search`, `get_observations` |
| **Written by** | Main Claude (automatic) + human (direct edit) | Agents, as part of their workflow Pre-Step |
| **Best for** | User preferences, corrections, active project decisions | Past session decisions, package gotchas, non-obvious patterns |
| **Editable** | Yes — open and edit any file directly | No — append-only database |
| **Scope** | Per-project, per-developer (not committed to git) | Per-installation (or shared server for teams) |

Use auto-memory for information that needs to be curated and corrected over time. Use Claude Mem for information that agents write automatically and retrieve by keyword.

---

## Why It Exists (The Problem It Solves)

**Without auto-memory:**

Claude opens a session with no knowledge of who you are, what you've corrected before, or what the current project state is. You tell Claude not to use a specific pattern — it follows the instruction for that session. Next session, Claude uses the pattern again. You correct it again. This cycle repeats indefinitely because there is no mechanism to persist the correction across sessions.

**With auto-memory:**

Corrections become permanent. When you tell Claude "always use SafeArea on the Scaffold body," Claude saves a feedback memory. The next session, it reads that memory before making any layout decisions and applies the rule without being reminded. The same applies to preferences, project context, and user profile.

The compounding effect: after 5–10 sessions, Claude has a working model of how you prefer to work, what mistakes to avoid, and the current state of the project. Each session builds on the last instead of starting from zero.

### What This Does NOT Do

- Auto-memory does not replace `docs/memory/error_learnings.md`. That file is for non-obvious technical mistakes during implementation — wrong package usage, unexpected API behavior, framework gotchas. Auto-memory is for developer preferences and workflow corrections, not technical findings.
- It does not track git history or code changes. Use `git log` for that.
- It does not store current-session task state. Use the TodoWrite tool for in-session tracking.
- It is not shared between developers on the same project. The memory folder is per-developer, not committed to git. See [Chapter 18: Team Collaboration] for what to commit vs. gitignore.

---

## How It Works

### Memory Types

Every memory file has one of four types, declared in its frontmatter. The type determines when Claude creates the file and when it loads it.

#### Type: `feedback`

Corrections and confirmations about how Claude should approach work — what to avoid and what to keep doing.

**When saved:** When you correct Claude's approach ("don't do X"), or when Claude makes a non-obvious choice and you accept it without pushback.

**When used:** Before writing code, before choosing patterns, before triggering agents — any decision-making moment.

**Body structure:** Lead with the rule. Then `**Why:**` (the reason it matters or the reason you gave). Then `**How to apply:**` (the condition — every Scaffold, before any TextStyle, whenever choosing between two patterns).

```markdown
---
name: Scaffold SafeArea Pattern
description: Always wrap Scaffold body in SafeArea — never use extendBodyBehindAppBar or MediaQuery.padding.top hacks
type: feedback
---

Always use `body: SafeArea(child: ...)` on every Scaffold.

**Why:** extendBodyBehindAppBar causes content to bleed behind the status bar.
Manual MediaQuery.padding.top offsets are fragile and device-specific.
SafeArea handles all system UI insets automatically and consistently.

**How to apply:** Every Scaffold body gets SafeArea — no exceptions. Never add
a second SafeArea inside child widgets when body-level SafeArea is already present —
that causes double padding.
```

#### Type: `user`

Information about the developer's role, expertise, and preferences that helps Claude calibrate responses.

**When saved:** When Claude learns something about who the developer is — their experience level, domain background, or communication preferences.

**When used:** When deciding how to explain something, how much detail to include, which analogies are relevant.

**Body structure:** Short factual description. No Why/How-to-apply needed — this is profile information, not a rule.

```markdown
---
name: Developer background
description: Senior Flutter developer, 4 years experience, new to GetX — frame GetX via Bloc/Provider analogues
type: user
---

Senior Flutter developer with 4 years experience using Bloc and Provider. Currently
migrating to GetX for the first time. Has strong Dart and Clean Architecture background.
Prefers concise technical responses — no explanations of basic Flutter or Dart concepts.
```

#### Type: `project`

Current project state, active decisions, constraints, and timelines.

**When saved:** When the project state changes in a way that affects future decisions — code freeze dates, architecture decisions, modules in progress, acknowledged tech debt.

**When used:** When making implementation suggestions, choosing patterns, or deciding scope.

**Body structure:** Lead with the fact or decision. Then `**Why:**` (the motivation — constraint, stakeholder requirement, incident). Then `**How to apply:**` (how this shapes future suggestions). Always convert relative dates to absolute dates when saving — "next Friday" becomes "2026-05-09."

```markdown
---
name: Release code freeze
description: No non-critical merges after 2026-05-10 — team cutting release branch
type: project
---

Non-critical changes are frozen from 2026-05-10 as the mobile team cuts a release branch.

**Why:** Release branch stability — any non-critical change merged after this date risks
introducing instability before the release window.

**How to apply:** Flag any non-critical PR work scheduled after 2026-05-10. For
genuinely urgent changes only, confirm explicitly with the human before proceeding.
```

#### Type: `reference`

Pointers to where information lives in external systems — design files, issue trackers, dashboards.

**When saved:** When Claude learns that a specific type of information lives in a specific external location.

**When used:** When the user references something external, or when Claude needs context that might be in an external system.

**Body structure:** State what the resource is and what it contains. One short paragraph is sufficient.

```markdown
---
name: Bug tracker location
description: All known bugs tracked in Linear project "APP-BUGS" — check before investigating as a new issue
type: reference
---

Bugs and known issues are tracked in the Linear project "APP-BUGS". Before investigating
any reported issue as a new bug, check this project — the issue may already be known,
assigned, or have a workaround documented.
```

---

### MEMORY.md — The Index

`MEMORY.md` is not a memory file. It is an index. Every time Claude saves a new memory file, it adds a one-line pointer to `MEMORY.md`. Claude reads `MEMORY.md` at session start to decide which memory files are relevant before loading any of them.

```markdown
# Memory Index

## Feedback
- [feedback_scaffold_safe_area.md](feedback_scaffold_safe_area.md) — Always wrap Scaffold body in SafeArea — never use extendBodyBehindAppBar or MediaQuery.padding.top hacks
- [feedback_no_manual_coding.md](feedback_no_manual_coding.md) — NEVER write code in main conversation — always use developer agent, no exceptions

## Project
- [project_font_rule.md](project_font_rule.md) — Plus Jakarta Sans is the only allowed font — Inter and Poppins are forbidden in TextStyle

## User
- [user_background.md](user_background.md) — Senior Flutter developer, first time with GetX — frame GetX explanations via Bloc/Provider analogues

## Reference
- [reference_design_files.md](reference_design_files.md) — Figma design system at [URL] — check before proposing any UI changes
```

**Rules for MEMORY.md:**

- One line per entry. Maximum ~150 characters per line including path and description.
- Group by type using H2 headings: Feedback, Project, User, Reference.
- The one-line description is the signal Claude uses to decide whether to open the file without reading it. A vague description ("some feedback about widgets") means the memory is never loaded. A specific one ("Always use SafeArea — extendBodyBehindAppBar causes content to bleed") means it loads every time a Scaffold is written.
- Lines after ~200 are truncated and not loaded. Keep the index tight.

---

### How Claude Uses Memory at Session Start

Claude reads `MEMORY.md` on every session start. It does not open every memory file — that would consume context on irrelevant information. It scans the one-line descriptions and opens only the files that are relevant to the current task.

```
Session starts
      ↓
Claude reads MEMORY.md (index only — fast, low context cost)
      ↓
Scans one-line descriptions against current task
      ├─ UI work → loads feedback entries about layout, colors, fonts
      ├─ New feature → loads project entries (current state) + user entries (calibration)
      └─ Bug investigation → loads feedback about agent pipeline + any reference entries
      ↓
Opens only the relevant memory files
      ↓
Applies their content before taking any action
```

The one-line description in `MEMORY.md` is the gatekeeper. The more specific it is, the more reliably Claude loads the memory when it is needed and skips it when it is not.

---

## Setup

### Prerequisites Check

- [ ] Claude Code CLI installed and project initialized
- [ ] `.claude/` directory exists in the project root

### Step 1: Understand the file location

Claude Code automatically creates the memory folder when a memory is first saved. The path is:

**Windows:**
```
C:\Users\[username]\.claude\projects\[project-hash]\memory\
```

**macOS / Linux:**
```
~/.claude/projects/[project-hash]/memory/
```

The `[project-hash]` is derived from the project path. Claude Code manages this automatically — you never need to find or create it manually.

> **NOTE:** This folder is NOT inside your project's git repository. It lives in the Claude Code user data directory. It is per-developer and per-machine. See [Chapter 18: Team Collaboration] for the full discussion of what to commit.

### Step 2: Save your first memory

Tell Claude something you want remembered across sessions:

```
"Remember: in this project, all loading states use a shimmer effect —
never use CircularProgressIndicator."
```

Claude will:
1. Classify this as a `feedback` memory
2. Create `feedback_shimmer_loading.md` in the memory folder
3. Add a pointer to `MEMORY.md`

The created file will look like:

```markdown
---
name: Loading state pattern
description: All loading states use shimmer — never use CircularProgressIndicator
type: feedback
---

All async loading states display a Shimmer skeleton, never CircularProgressIndicator.

**Why:** CircularProgressIndicator gives no structural preview of the incoming content.
Shimmer loading reduces perceived wait time and is consistent with the app's design
benchmark (Tinder/Bumble-level polish).

**How to apply:** Before writing any screen with async state: the loading branch must
use Shimmer.fromColors wrapping a skeleton layout. Refuse to write
CircularProgressIndicator on any screen without explicit human instruction.
```

### Step 3: Create memory files manually (optional)

You can create memory files directly without asking Claude. Useful when you want to set up preferences before starting a session.

1. Navigate to the memory folder for your project.
2. Create a new `.md` file with a descriptive snake_case name: `feedback_api_error_handling.md`.
3. Add the frontmatter and body:

```markdown
---
name: [Short descriptive name]
description: [One-line description — this exact line goes in MEMORY.md]
type: [user | feedback | project | reference]
---

[Rule or fact]

**Why:** [Reason this matters — consequence of violation or motivation]

**How to apply:** [When and where this rule kicks in — be specific]
```

4. Add the pointer to `MEMORY.md` under the correct type heading:

```markdown
- [feedback_api_error_handling.md](feedback_api_error_handling.md) — [one-line description]
```

---

## What NOT to Save in Memory

Auto-memory becomes noise when it stores the wrong things. Every loaded memory file consumes context — irrelevant entries dilute signal from useful entries and push the session toward its context limit faster.

| Category | Where it belongs instead | Why not auto-memory |
|----------|--------------------------|---------------------|
| Code patterns and conventions | `.claude/rules/` rule files | Rules apply to all developers; memory is per-developer |
| Architecture decisions | `docs/instructions/ARCHITECTURE.md` | Committed to git; visible to the entire team |
| API endpoint patterns | `docs/memory/api_registry.md` | Agent-maintained; structured for grep lookup |
| Reusable widget catalog | `docs/memory/component_registry.md` | Agent-maintained; structured for grep lookup |
| Git history / who-changed-what | `git log`, `git blame` | Always current; auto-memory snapshot would become stale |
| Debugging solutions, package gotchas | `docs/memory/error_learnings.md` | Structured for agent Pre-Step lookup; shared with team |
| Semantic past decisions | Claude Mem MCP | Needs keyword search; agents write it automatically |
| In-session task progress | TodoWrite tool | Session-scoped; has no value after current session ends |

**The test for whether something belongs in auto-memory:** Is this specific to how *this developer* works on *this project*, and would a future Claude session make a mistake without knowing it?

- "Always use SafeArea on every Scaffold body" → Yes. It is a workflow correction that is not in any rule file.
- "`UserEntity` has a `displayName` field" → No. Read the model file. It is already in the code.
- "We chose library X over Y because of Z" → Possibly. If it affects future architecture suggestions and is not in `ARCHITECTURE.md`, save it as a project memory.

---

## Keeping Memory Current

Memory files become stale. A project memory that said "we're mid-feature on ProfileModule" is wrong three months later. A feedback memory referencing a file path that was refactored is pointing at code that no longer exists.

**When to update a memory:**

- Project state changed (freeze lifted, module completed, architecture decision reversed)
- The code pattern in a feedback memory was intentionally changed project-wide
- A user preference evolved ("I used to prefer X, now I prefer Y")

**When to delete a memory:**

- The referenced file, function, or pattern no longer exists in the codebase
- The project state fact is no longer true and not worth correcting
- A feedback rule was superseded by a more general rule added to `.claude/rules/`

**How to update:**

Open the memory file directly and edit the body content. Update the one-line description in `MEMORY.md` if it has changed.

> **WARNING:** Before acting on a memory that names a specific file, function, or constant, verify it still exists. Claude should grep for the name or read the file before recommending it. "The memory says `ProfileController.onPhotoAdded` exists" is not the same as "it exists now." If a session reveals that a memory references non-existent code, Claude should update or remove the entry in that same session.

---

## Validation

### Validation Test 1: Memory is saved and persists

**Purpose:** Confirm Claude creates the file and loads it in future sessions.

**Setup:** A clean session with an empty or minimal memory folder.

**Trigger:**
Tell Claude: "Remember: in this project, all loading states use a shimmer effect — never CircularProgressIndicator."

**Expected result:**
A new file (e.g. `feedback_shimmer_loading.md`) appears in the memory folder with correct YAML frontmatter (`name`, `description`, `type`). `MEMORY.md` has a new entry pointing to it. In the next session, when you ask Claude to implement a loading state, it uses Shimmer without being reminded.

**If you see Claude write CircularProgressIndicator in the next session:**
→ The memory file exists but `MEMORY.md` was not updated. Check whether the pointer line was added. If missing, add it manually.

---

### Validation Test 2: MEMORY.md is read at session start

**Purpose:** Confirm Claude loads relevant memory before acting.

**Setup:** At least 2–3 memory files exist with specific, descriptive entries in `MEMORY.md`.

**Trigger:**
At the start of a new session, ask: "What do you remember about how I prefer to work on this project?"

**Expected result:**
Claude describes the preferences and rules from the loaded memory files. The summary should match the actual memory file content — not generic Claude defaults.

**If Claude says "I don't have any saved preferences":**
→ Check that `MEMORY.md` exists in the memory folder at the correct path. If the folder doesn't exist, no memory has ever been saved — start with Validation Test 1.

---

### Validation Test 3: Stale memory detection

**Purpose:** Confirm Claude does not blindly apply a rule about code that no longer exists.

**Setup:** Create a feedback memory that references a specific function name. Then rename or delete that function in the codebase.

**Trigger:**
Start a new session and give Claude a task involving the area where the function used to be.

**Expected result:**
Claude loads the memory, attempts to verify the referenced function exists, finds it missing, and flags the memory as potentially stale rather than applying a rule about non-existent code.

**If Claude applies the rule anyway:**
→ Add a line to the memory body: "Verify `[FunctionName]` exists before applying this rule." This makes the verification requirement explicit. Then update the memory to reflect the current correct function name.

---

## Common Mistakes

### Mistake 1: Writing code blocks into memory files

**Symptom:** A memory file contains a 30-line code block. Every session, Claude loads it and its context window fills with code before doing anything useful.

**Cause:** Saving "what correct code looks like" as a reference. Code belongs in the codebase and rules belong in `.claude/rules/`, not in memory.

**Fix:** Replace the code block with a one-sentence rule: "Use Shimmer.fromColors for all loading skeleton states." The correct code is already in the codebase as the reference.

---

### Mistake 2: Vague MEMORY.md descriptions

**Symptom:** Claude never loads a memory file that is relevant to every task.

**Cause:** The one-line entry in `MEMORY.md` is too generic — "some notes about fonts" — and Claude doesn't recognize it as relevant to the current decision.

**Fix:** Rewrite the description to be specific and name the violation it prevents:

```
Before: "— some notes about fonts"
After:  "— Plus Jakarta Sans is the only allowed font — Inter and Poppins are forbidden in TextStyle"
```

---

### Mistake 3: Feedback memories without Why and How-to-apply lines

**Symptom:** Claude applies the rule in obvious cases but misses edge cases. When asked why it made a choice, it only says "because the memory says so."

**Cause:** The memory states the rule but not the reason or conditions. Without **Why**, Claude cannot judge edge cases — it only knows the rule, not the principle behind it. Without **How to apply**, Claude doesn't know when the rule is active.

**Fix:** Add both lines to every feedback and project memory. The **Why** is the consequence of violating the rule. The **How to apply** is the triggering condition: "every Scaffold body," "before writing any TextStyle," "when choosing between two competing patterns."

---

### Mistake 4: Using auto-memory as a project log

**Symptom:** The memory folder has files documenting completed features, module structure, PR history. After a few months, the memory index is longer than CLAUDE.md and most entries are stale.

**Cause:** Auto-memory was used as a project journal instead of a preference and active-decision store.

**Fix:** Move static project information to `docs/instructions/ARCHITECTURE.md` (for architecture) or let it live in git history. Auto-memory is for rules and active state — facts that are still true and that change Claude's behavior today.

---

### Mistake 5: Corrections given but never persisted

**Symptom:** You correct Claude on the same mistake across multiple sessions. Nothing is ever saved.

**Cause:** Corrections phrased as casual pushback ("no, not like that") are not recognized by Claude as worth persisting. Claude saves memory when explicitly asked or when it makes a deliberate save decision — not for every passing correction.

**Fix:** After any meaningful correction, add: "Remember this for future sessions." For preferences you know upfront, add them to memory files manually before the first session starts rather than discovering them through repeated correction.

---

## Reference

| Item | Value |
|------|-------|
| **Memory folder (Windows)** | `C:\Users\[user]\.claude\projects\[project-hash]\memory\` |
| **Memory folder (macOS/Linux)** | `~/.claude/projects/[project-hash]/memory/` |
| **Index file** | `MEMORY.md` (in the memory folder) |
| **Managed by** | Main Claude (automatic saves) + human (direct file edits) |
| **Committed to git** | No — per-developer, per-machine |
| **Memory types** | `user`, `feedback`, `project`, `reference` |
| **MEMORY.md line limit** | ~200 lines (truncated after — keep index concise) |
| **Trigger to save manually** | "Remember this for future sessions" |
| **Session start behavior** | Claude reads MEMORY.md → opens only relevant files |

---

*Next: [Chapter 13: Project Map]*
