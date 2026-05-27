# Chapter 7: Rules System (.claude/rules/)

> **Applies to:** Both
> **Prerequisites:** [Chapter 4: CLAUDE.md File], [Chapter 5: settings.json]
> **Estimated read + setup time:** ~25 minutes

---

## TL;DR

The rules system is a directory of Markdown files in `.claude/rules/` that encode your project's coding standards — style, testing, security, git workflow. Rules are organized in two layers: `common/` files apply to everything, language-specific directories (like `dart/` or `typescript/`) override common rules for files matching those languages. Without this system, each agent invents its own style; with it, every agent follows the same documented standards. Rules are not the same as CLAUDE.md — they are the detailed reference material that agents read when needed, not the short routing logic that loads every session.

---

## What This Is

The rules system is a set of Markdown files organized under `.claude/rules/`. These files define the project's coding standards with enough detail to include code examples, checklists, and rationale. They are the difference between "use immutable patterns" (a CLAUDE.md line) and a full explanation of *what immutability means in this project, with before/after examples* (a rules file).

The directory has two layers:

```
.claude/rules/
  common/              ← applies to all files, all languages
    coding-style.md    ← immutability, naming, file size
    git-workflow.md    ← commit format, PR process
    testing.md         ← coverage targets, TDD order
    security.md        ← security checklist
    agents.md          ← orchestra: trigger table, quality tiers
    development-workflow.md
    patterns.md
    performance.md

  dart/                ← applies only to .dart and pubspec.yaml files
    coding-style.md    ← extends common, adds Dart-specific patterns
    testing.md         ← extends common, adds Flutter test frameworks
    security.md        ← extends common, adds mobile security rules
    patterns.md
```

Language-specific directories (`dart/`, `typescript/`, `python/`, etc.) override specific common rules for files matching their language. The rule: **specific beats general**. If `dart/coding-style.md` and `common/coding-style.md` conflict on the same point, the dart version applies when working with Dart files.

### How It Compares to CLAUDE.md

| | CLAUDE.md | rules/ |
|--|-----------|--------|
| Purpose | Identity, routing triggers, quick references | Detailed standards with code examples |
| Length limit | ~500 lines — every line costs context | No practical limit — detail is the point |
| Read by | Main Claude, every session, automatically | Agents, per their Pre-Step instructions; auto-applied by paths |
| Format | Markdown prose with tables | Markdown with code blocks and checklists |
| What breaks if wrong | Every session starts with wrong routing | Agents write code that violates documented standards |
| Example content | `"Use ColorHelper for all colors"` | The full ColorHelper class with correct/incorrect examples |

The design principle: CLAUDE.md has 500-line budget pressure. Putting detailed rules there bloats it and degrades quality on every session. Rules/ files have no such pressure — they're loaded selectively.

---

## Why It Exists (The Problem It Solves)

**Without a rules system:** Each agent session starts from scratch. The developer agent writes code using inline `Color(0xFF...)` because nothing told it not to. The code-reviewer approves it because it has no coding standard to compare against. The next session, the same violation appears again.

**With a rules system:** Coding standards are documented once, in detail, with examples. Agents read the relevant rule file before starting work. The standard applies consistently whether it's the developer agent, code-reviewer, or ui-reviewer doing the checking.

The concrete failure mode without rules:

```
Session 1: developer agent uses Color(0xFF...) for a hardcoded color
           → code-reviewer has no standard to cite → approves
Session 2: developer agent uses Colors.red
           → ui-reviewer has no standard → approves
Session 3: developer agent uses ColorHelper correctly
Session 4: ... inconsistency compounds forever
```

With a rule in `dart/coding-style.md` that defines the ColorHelper requirement with examples:

```
Every session: developer agent reads coding-style.md during Pre-Step
               → sees the before/after examples
               → writes ColorHelper.primary, not Color(0xFF...)
               → code-reviewer cites coding-style.md line when reviewing
               → consistent across all sessions and all agents
```

### What This Does NOT Do

- Rules are not code linters — they don't run automatically on save like `dart format`. They are read by agents as context.
- Rules don't replace `flutter analyze` or CI checks — they are a complement, not a substitute
- Rules don't automatically apply to Main Claude's inline responses — Main Claude uses CLAUDE.md rules. The rules/ system is primarily for agents.
- A rule file that no agent is instructed to read is effectively dead documentation. Writing the file is step 1. Wiring agents to read it is step 2.

---

## How It Works

### Directory Layout

```
.claude/
  rules/
    common/                ← no paths frontmatter → applies globally
      coding-style.md
      git-workflow.md
      testing.md
      security.md
      agents.md            ← special: this IS the orchestra configuration
      development-workflow.md
      patterns.md
      performance.md
    dart/                  ← paths frontmatter → applies to .dart files only
      coding-style.md
      testing.md
      security.md
      patterns.md
    typescript/            ← if this project also has TypeScript
      coding-style.md
      testing.md
```

The directory name (`dart/`, `typescript/`, `flutter/`) is your convention — Claude Code reads all subdirectories under `rules/`. Choose names that match your tech stack.

### The Paths Frontmatter (Auto-Scoping)

Language-specific rule files include a YAML frontmatter block at the top that tells Claude Code which file types this rule applies to:

```yaml
---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---
# Dart/Flutter Coding Style
...
```

When Claude Code processes a `.dart` file, it automatically makes this rule file available as context. Rules without paths frontmatter (like all `common/` files) apply to every file and every context.

This auto-scoping means you do not need to explicitly instruct every agent to read every rule. The right rules surface automatically based on which files are being worked on. For truly critical rules that must be read regardless of file context, add them to `common/` without a paths restriction.

### The Layering Mechanism

```
Working on: lib/src/features/profile/profile_screen.dart (a .dart file)
      ↓
Claude Code loads:
  common/coding-style.md    ← global, always loaded
  common/testing.md         ← global, always loaded
  common/security.md        ← global, always loaded
  dart/coding-style.md      ← paths match *.dart → loaded
  dart/testing.md           ← paths match *.dart → loaded
      ↓
When common and dart rules conflict on the same point:
  dart/coding-style.md wins — specific overrides general
      ↓
Agent sees: the common baseline + dart-specific overrides
```

Each language-specific rule file should begin with a reference line explaining which common file it extends:

```markdown
> This file extends [common/coding-style.md](../common/coding-style.md) with Dart-specific content.
```

This makes the override relationship explicit. A reader seeing both files understands which one takes precedence and why.

### How Agents Consume Rules

There are three consumption patterns. All three can coexist in one project.

**Pattern 1 — Auto-applied (paths frontmatter):**
Rules with a `paths` block are automatically applied to matching file contexts. No agent instruction needed. This is the default behavior for language-specific rules.

**Pattern 2 — Agent Pre-Step (explicit):**
For rules critical enough to always be read by a specific agent, add an explicit read instruction to the agent's Pre-Step section:

```markdown
## Pre-Step (MANDATORY — RUNS BEFORE ANYTHING ELSE)
1. Read `rules/common/coding-style.md` — immutability, naming, file limits
2. Read `rules/dart/coding-style.md` — Dart-specific overrides
```

This is used when the agent needs to actively reason about the rules, not just have them as background context. For example, the code-reviewer agent reads rules explicitly so it can cite specific violations by rule name.

**Pattern 3 — CLAUDE.md surfacing:**
For the most critical rules — the ones that must be in Main Claude's active memory every single session — add a one-line reference in CLAUDE.md pointing to the full rule:

```markdown
## UI Compliance — Zero Tolerance
| Violation | Rule |
|-----------|------|
| `Color(0xFF...)` anywhere | → use `ColorHelper.xxx` (full rule: rules/dart/coding-style.md) |
```

CLAUDE.md holds the short version (one line per rule). The rules file holds the full version (examples, rationale, edge cases).

> **WARNING:** Only put rules in CLAUDE.md that must fire on every session. Adding 20 rules to CLAUDE.md that only apply to specific agents bloats the main context and degrades session quality.  
> Instead: put agent-specific rules in the agent file or in rules/ for that agent to read via Pre-Step.

---

## Setup

### Prerequisites Check

- [ ] `.claude/` directory exists at project root
- [ ] You have identified the language(s) your project uses (Dart, TypeScript, Python, etc.)
- [ ] CLAUDE.md exists with at least the Session Start Protocol (see [Chapter 4: CLAUDE.md File])

### Step-by-Step

**1. Create the rules directory structure**

```bash
mkdir -p .claude/rules/common
mkdir -p .claude/rules/dart    # replace 'dart' with your language
```

**2. Create `common/coding-style.md`**

Minimum content — expand as your project develops standards:

```markdown
# Coding Style

## Immutability (CRITICAL)

Always create new objects, never mutate existing ones.

WRONG: modify(original, field, value) → changes original in-place
CORRECT: update(original, field, value) → returns new copy with change

## File Organization

- High cohesion, low coupling
- 200–400 lines typical per file. 800 lines maximum.
- Organize by feature/domain, not by type

## Naming

- Classes: PascalCase
- Files, variables, parameters: snake_case
- Constants: lowerCamelCase
- Private members: _prefix

## Error Handling

- Handle errors explicitly at every level
- Never silently swallow errors
- Provide user-friendly messages in UI-facing code
```

**3. Create `common/git-workflow.md`**

```markdown
# Git Workflow

## Commit Message Format

<type>: <description>

<optional body>

Types: feat, fix, refactor, docs, test, chore, perf, ci

## Pull Request Workflow

1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan
```

**4. Create `common/testing.md`**

```markdown
# Testing Requirements

## Minimum Coverage: 80%

## Test-Driven Development (MANDATORY)

1. Write test first (RED)
2. Run test — it should FAIL
3. Write minimal implementation (GREEN)
4. Run test — it should PASS
5. Refactor (IMPROVE)
6. Verify coverage 80%+

## Test Types Required

1. Unit Tests — individual functions, use cases
2. Integration Tests — API endpoints, database operations
3. E2E Tests — critical user flows
```

**5. Create `common/security.md`**

```markdown
# Security

## Mandatory Checks Before Every Commit

- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated at system boundaries
- [ ] No sensitive data in logs or error messages
- [ ] Authentication/authorization verified on new endpoints
- [ ] Rate limiting on all new API endpoints

## Secret Management

- NEVER hardcode secrets in source code
- ALWAYS use environment variables
- Rotate any secret that may have been exposed
```

**6. Create the language-specific rules file with paths frontmatter**

Create `dart/coding-style.md` (replace `dart` and contents with your language):

```markdown
---
paths:
  - "**/*.dart"
  - "**/pubspec.yaml"
---
# Dart Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Dart-specific content.

## Formatting

- `dart format` for auto-formatting (run after every file write)
- `flutter analyze` for static analysis (run before marking work REVIEW)
- `dart fix --apply` for auto-fixable lint issues

## Null Safety

- Never use `!` (null bang) without proof the value is non-null
- Prefer `?.`, `??`, `??=` and early returns over force-unwrapping
- Use `required` for constructor parameters that must be provided

## Widget Conventions

- Always use `const` constructors and `super.key`
- One widget class per file; file name matches class in snake_case
- Keep `build()` methods free of logic — all logic belongs in a controller layer
```

**7. Verify the README is in place**

Create `.claude/rules/README.md` explaining the structure to new team members:

```markdown
# Rules

## Structure

Rules are organized into a common layer plus language-specific directories.

- `common/` — universal principles, always applied
- `dart/` — Dart/Flutter specific, applied to .dart and pubspec.yaml files

## Priority

When language-specific rules conflict with common rules,
the language-specific file takes precedence.

## Adding a new rule

1. Identify which file it belongs in (common or language-specific)
2. Write it in imperative form ("Always X", "Never Y")
3. Add a before/after code example
4. If critical enough for every session → add a one-liner to CLAUDE.md
5. If agent-specific → add a Pre-Step read instruction to the agent file
```

### Minimum Required Files

| File | What it covers | Who reads it |
|------|----------------|-------------|
| `common/coding-style.md` | Naming, immutability, file size, error handling | Developer agent, code-reviewer |
| `common/git-workflow.md` | Commit format, PR process | Developer agent, doc-updater |
| `common/testing.md` | Coverage targets, TDD order, test types | Developer agent, tdd-guide |
| `common/security.md` | Security checklist before commit | Security-reviewer, developer |
| `common/agents.md` | Orchestra: trigger table, quality tiers, routing | Main Claude (every session) |
| `[lang]/coding-style.md` | Language-specific overrides with examples | Developer agent, code-reviewer |
| `[lang]/testing.md` | Framework-specific test patterns | Developer agent, tdd-guide |

> **NOTE:** `common/agents.md` is special — it contains the orchestra configuration (which agent fires for which trigger). Main Claude reads it every session to make routing decisions. All other files in `common/` are read by agents per their Pre-Step, not by Main Claude automatically.

---

## How to Add a New Rule

When a new standard emerges during development (a team decision, a mistake that gets documented, a new library pattern):

1. **Identify which file it belongs in.** Is it universal (common/) or language-specific (dart/)? Could it contradict an existing common rule? If yes → put it in the language-specific file with a note about the override.

2. **Write it in imperative form.** Not "should" or "consider." Use "Always", "Never", "Must."

3. **Add a before/after code example.** Rules without examples are ignored. Examples make compliance unambiguous.

4. **Decide the surfacing level:**
   - Rule applies to all contexts, critical enough to load every session → one-liner in CLAUDE.md
   - Rule applies only when a specific agent runs → Pre-Step read instruction in that agent's file
   - Rule applies when matching file types are worked on → paths frontmatter handles it automatically

5. **Check for conflicts.** Search for related rules in other files. If conflict exists: resolve it explicitly — either update the older rule, or add a note in the language-specific file explaining why it overrides the common version.

---

## Validation

### Validation Test 1: Rules Are Loaded When Working on a Matching File

**Purpose:** Confirm that a language-specific rule with paths frontmatter is made available when Claude works on a matching file.

**Setup:**
- `dart/coding-style.md` exists with `paths: ["**/*.dart"]` frontmatter
- A distinctive rule is in the file, e.g.: `Never use inline Color values. Always use ColorHelper.`

**Trigger:**
Ask Claude to review a Dart file that has an inline Color value:
```
Review lib/src/utils/profile_card.dart for coding style violations.
```

**Expected result:**
Claude cites the ColorHelper rule specifically, not just a generic "hardcoded values" observation. It references that inline Color values are not allowed — which it could only know from the dart/coding-style.md rule.

**If Claude gives a generic response without citing the specific rule:**
→ Verify the paths frontmatter is formatted correctly (YAML block at the very top of the file, before any content). A malformed frontmatter block means the paths scoping doesn't apply.

---

### Validation Test 2: Language Rule Overrides Common Rule

**Purpose:** Confirm that a language-specific rule takes precedence over the corresponding common rule.

**Setup:**
- `common/coding-style.md` contains: "Use immutable data patterns"
- `dart/coding-style.md` contains an override: "Reactive observables in GetX controllers use `.value` mutation — this is expected and correct for controller state."

**Trigger:**
Ask Claude a question that would trigger both rules:
```
Is it okay to use .value mutation on a GetX observable in a controller?
```

**Expected result:**
Claude explains that controller observables are an exception to the general immutability rule — citing the dart/ rule override, not blindly applying the common rule.

**If Claude cites only the common rule (says mutation is wrong):**
→ The language-specific file is not being loaded, or the override explanation is missing. Check that `dart/coding-style.md` has the paths frontmatter, and add a clear note: `> **Override:** This is an intentional exception to [common/coding-style.md] immutability. GetX reactivity requires value mutation.`

---

### Validation Test 3: Agent Pre-Step Reads the Rule

**Purpose:** Confirm that an agent with a Pre-Step rule read instruction actually uses the rule.

**Setup:**
- A developer agent has in its Pre-Step: `Read rules/common/security.md before any implementation`
- `common/security.md` lists: "Never log authentication tokens"

**Trigger:**
Launch the developer agent and ask it to implement a login feature.

**Expected result:**
The agent does not add any token logging to the implementation. If asked why, it cites the security rule specifically.

**If the agent adds token logging anyway:**
→ The Pre-Step instruction is not specific enough, or the agent skipped its Pre-Step. Verify the agent file contains the read instruction as a clearly numbered, mandatory gate — not buried in prose.

---

## Common Mistakes

### Mistake 1: Putting agent-specific instructions in common rules files

**Symptom:** The `common/coding-style.md` file grows to 500+ lines and includes instructions like "When reviewing code, look for X" — which only applies to the code-reviewer.

**Cause:** It's tempting to add agent instructions wherever there's a convenient Markdown file. common/ rules feel like a natural place for all standards.

**Fix:** Keep common/ files as coding standards only. Agent-specific workflow instructions belong in the agent file itself. The rule: if it starts with "when you are [agent-name]" — it goes in the agent file, not in rules/.

---

### Mistake 2: Writing rules in hedging language that agents treat as optional

**Symptom:** Rules are documented but agents routinely ignore them. Code reviews keep catching the same violations.

**Cause:** Rules written as "prefer X" or "consider Y" are treated as advisory suggestions, not requirements.

**Fix:** Use imperative, binary language: "Always use X." "Never use Y." "X is required, Y is forbidden." Rules phrased as suggestions are suggestions — agents will apply judgment and skip them when convenient.

---

### Mistake 3: Rules that contradict each other across files

**Symptom:** Code review findings are inconsistent. An agent follows the rule in one session, contradicts it in another. The code-reviewer and developer agent cite different standards.

**Cause:** common/coding-style.md says one thing; dart/coding-style.md implicitly says another, and neither mentions the other.

**Fix:** When a language-specific rule overrides a common rule, state it explicitly in the language-specific file:

```markdown
> **Override from [common/coding-style.md]:** The general immutability rule applies to entities and DTOs.
> Controller state uses `.obs` and `.value` — this mutation is intentional and expected.
```

This makes the override visible and intentional, not an accidental contradiction.

---

### Mistake 4: Creating a rule file that no agent reads

**Symptom:** The rules/ directory has well-written files, but agents still violate the standards documented in them.

**Cause:** The rule file was created but never wired to any agent. Without paths frontmatter (for auto-apply) or a Pre-Step read instruction (for explicit load), the file is documentation that sits unread.

**Fix:** For every new rule file, do one of these:
1. Add the `paths` frontmatter block (for language-specific auto-scoping)
2. Add a Pre-Step read instruction in the agent(s) that should follow the rule
3. For critical rules: add a one-liner to CLAUDE.md to surface it every session

If the rule doesn't warrant any of these — it likely doesn't need its own file yet. Start as a comment in an existing file.

---

### Mistake 5: Duplicating rules/ content into CLAUDE.md

**Symptom:** CLAUDE.md grows past 600 lines. Main Claude spends 30–40% of its context window loading rules before any work begins. Response quality declines mid-session.

**Cause:** Rules that belong in `rules/dart/coding-style.md` are copy-pasted into CLAUDE.md with full examples because "I want Claude to always know them."

**Fix:** CLAUDE.md holds one-liners that reference rules/. The full rule lives in rules/. If a rule requires a before/after example to be understood, that example goes in rules/, not CLAUDE.md. CLAUDE.md's job is to surface the rule by name, not to contain it.

---

## Reference

| Item | Value |
|------|-------|
| Directory | `.claude/rules/` |
| Common files | `.claude/rules/common/` — no paths frontmatter, applies globally |
| Language files | `.claude/rules/[lang]/` — paths frontmatter, applies to matching file types |
| Conflict resolution | Language-specific wins over common |
| Auto-application | Via `paths` frontmatter in the file's YAML block |
| Explicit application | Pre-Step read instruction in the agent file |
| Critical-rule surfacing | One-liner reference in CLAUDE.md |
| Special file | `common/agents.md` — this is the orchestra configuration, read by Main Claude |
| Updated when | New standard established, mistake corrected, new library pattern adopted |

---

*Next: [Chapter 8: Agent Creation Guide]*
