# Flutter Generic Claude Code Setup — Template Guide

> This is your onboarding checklist. Follow it top-to-bottom before starting your first session.

---

## Step 1: Define Your Variables

Fill in every placeholder below. You'll use these values when editing the files in Step 2.

| Placeholder | What It Means | Your Value |
|-------------|---------------|-----------|
| `{{APP_NAME}}` | Your app's display name | |
| `{{APP_DESCRIPTION}}` | One sentence describing your app | |
| `{{PROJECT_ROOT}}` | Absolute path to your project root (backslashes) | |
| `YOUR_PROJECT_ROOT` | Same path, forward slashes, no drive colon (for settings.json) | |
| `YOUR_HOME` | Your home folder path (e.g. `c/Users/yourname`) | |
| `YOUR_USERNAME` | Your OS username | |
| `YOUR_PROJECT_KEY` | Claude's internal project key (shown in `.claude/projects/`) | |
| `{{APP_FONT}}` | Primary font family (e.g. `Inter`, `Poppins`) | |
| `{{DESIGN_BENCHMARK}}` | 2 competitor apps your UI should match in quality | |
| `{{APP_BUSINESS_RULES}}` | Your app's core mechanics and constraints | |
| `{{CLIENT_NAME}}` | Client's name (or your own) | |
| `{{CLIENT_LOCATION}}` | Client's location | |
| `{{AGENCY_NAME}}` | Your studio / agency name | |
| `{{STATE_MANAGEMENT}}` | Your chosen state management package (e.g. `riverpod ^2.6.1`, `flutter_bloc ^9.0`, `provider ^6.1`, `getx ^4.7.3`) | |
| `{{ROUTING_SOLUTION}}` | Your navigation package (e.g. `go_router`, `auto_route`, `GetX named routes`, `Navigator 2.0`) | |
| `{{DI_SOLUTION}}` | Your dependency injection approach (e.g. `get_it`, `riverpod`, `injectable`, `GetX`, `provider`) | |
| `{{ARCHITECTURE}}` | Your chosen architecture pattern (e.g. `Clean Architecture (domain/data/presentation)`, `MVVM (view/viewmodel/model)`, `Simple layered (screens/services/models)`) | |

---

## Step 2: File-by-File Changes

### `CLAUDE.md`
| What | Where | Replace |
|------|-------|---------|
| App name | Line 1 | `{{APP_NAME}}` |
| App name + description | Line 103 | `{{APP_NAME}}` and `{{APP_DESCRIPTION}}` |
| Project root path | Line 215 (bug prompt block) | `{{PROJECT_ROOT}}` |

---

### `.claude/settings.json`

| What | Where | Replace |
|------|-------|---------|
| Project read permissions | Lines 4–9 | `YOUR_PROJECT_ROOT` (forward slashes, no colon — e.g. `d/projects/my_app`) |
| Home `.claude` read permission | Line 10 | `YOUR_HOME` (e.g. `c/Users/yourname`) |
| Bash find command path | Line 15 | `YOUR_PROJECT_ROOT` |
| Bash ls command path | Line 16 | `YOUR_PROJECT_ROOT` |
| `additionalDirectories` | Lines 35–38 | `YOUR_USERNAME` and `YOUR_PROJECT_KEY` |

> **Finding YOUR_PROJECT_KEY:** Open Claude Code in your project. Check `C:\Users\<username>\.claude\projects\` — the folder name is your project key.

---

### `.claude/agents/fr-analyst.md`
| What | Where | Replace |
|------|-------|---------|
| Agent title | Line 8 | `{{APP_NAME}}` |
| Agent subtitle | Line 9 | `{{APP_NAME}}` |
| App description block | Lines 63–65 | `{{APP_NAME}}` and `{{APP_DESCRIPTION}}` |
| Business rules block | Lines 68–78 | Replace the `{{APP_BUSINESS_RULES}}` placeholder with your app's actual rules |
| Quality gates title | Line 84 | `{{APP_NAME}}` |
| UX benchmark | Line 86 | `{{DESIGN_BENCHMARK}}` |
| Role 3 description | Line 28 | Update if your app is not a consumer app |

**Business Rules block guidance — fill in:**
- What is the core user action? (e.g., "Users post tasks and hire providers")
- How does monetization work? (e.g., "Premium subscription unlocks X")
- Any safety / privacy requirements?
- Any state machine rules? (e.g., "Items have pending → active → completed states")

---

### `.claude/agents/ui-reviewer.md`
| What | Where | Replace |
|------|-------|---------|
| Agent description (frontmatter) | Line 3 | `{{APP_NAME}}` and `{{DESIGN_BENCHMARK}}` |
| Agent title | Line 8 | `{{APP_NAME}}` |
| Benchmark line | Line 16 | `{{DESIGN_BENCHMARK}}` |
| Font name (line + code block) | Lines 124–131 | `{{APP_FONT}}` (appears twice) |

---

### `.claude/agents/systematic-debugger.md`
| What | Where | Replace |
|------|-------|---------|
| Agent description (frontmatter) | Line 3 | `{{APP_NAME}}` |
| Agent title | Line 8 | `{{APP_NAME}}` |

---

### `.claude/agents/project_map.md`
| What | Where | Replace |
|------|-------|---------|
| Agent description (frontmatter) | Line 3 | `{{APP_NAME}}` |
| Cartographer intro | Line 12 | `{{APP_NAME}}` |

---

### `.claude/agents/ui-design-enforcer.md`
| What | Where | Replace |
|------|-------|---------|
| Agent description (frontmatter) | Line 3 | `{{APP_NAME}}` |
| Agent title | Line 8 | `{{APP_NAME}}` |
| Constraints check heading | Line 64 | `{{APP_NAME}}` |

---

### `docs/instructions/UI_INSTRUCTION.md`
| What | Where | Replace |
|------|-------|---------|
| Document title | Line 2 | `{{APP_NAME}}` |
| Document subtitle | Line 4 | `{{APP_NAME}}` |
| Component naming table header | Line 77 | `{{APP_NAME}}` |

---

### `docs/instructions/API_INSTRUCTION.md`
| What | Where | Replace |
|------|-------|---------|
| Document title | Line 1 | `{{APP_NAME}}` |
| Document subtitle | Line 4 | `{{APP_NAME}}` |
| Footer rule | Line 346 | `{{APP_NAME}}` |

---

### `.claude/rules/common/agents.md`
| What | Where | Replace |
|------|-------|---------|
| Project root in bug prompt template | Line 105 | `{{PROJECT_ROOT}}` |
| Project root (second occurrence) | Line ~215 | `{{PROJECT_ROOT}}` (search for `{{PROJECT_ROOT}}` — already templated if you see the placeholder) |

---

### `docs/memory/project_overview.md`
Fill in every `{{PLACEHOLDER}}` section:
- `{{APP_NAME}}` — your app name
- `{{APP_DESCRIPTION}}` — one-paragraph description
- `{{TARGET_USER_DESCRIPTION}}` — who uses it and why
- Core User Journey steps — your actual screens/flows
- Business Rules — your app's constraints
- Module Status table — your feature list
- `{{CLIENT_NAME}}`, `{{CLIENT_LOCATION}}`, `{{AGENCY_NAME}}`

---

### `docs/memory/api_registry.md`
- Rename the `[Feature Module]` section heading to match your first feature
- Delete example rows and add your own as you implement API calls
- Keep the Auth section as-is (generic OTP auth rows provided as starting point)

---

### `docs/memory/component_registry.md`
- Rename `[Feature Module]` sections to match your modules
- Delete example rows; add your own as you build components
- Keep Shared Widgets section — update widget names to match your actual shared widgets

---

### `docs/maps/project_map.md`
- Replace `{{APP_NAME}}` in the title
- Fill in Module Inventory after your first feature is built
- Update User Journey Map with your actual screen flow
- The rest auto-populates as the `project-map` agent runs

---

### `docs/FR/_pipeline_status.md`
- Rename `[Feature Module]` sections to your actual modules
- Add features as you plan them; update status as you build

---

## Step 2b: Fill In Your Stack Conventions

This template ships with empty placeholder blocks wherever GetX-specific patterns or Clean Architecture specifics would be. After completing Step 2, open each of the files below and fill in the placeholder comment blocks with your stack's actual conventions.

### `.claude/rules/dart/coding-style.md`
Find the `{{STATE_MANAGEMENT}} CONVENTIONS` block and replace it with your state management rules (allowed/banned patterns, how to access state, how to define state holders).

### `.claude/rules/dart/patterns.md`
Find the three placeholder blocks for State Management, Routing, and DI. Replace each with code examples from your chosen packages.

### `.claude/rules/dart/testing.md`
Find the `{{STATE_MANAGEMENT}} TESTING` block. Add test skeletons for your state management (how to mock controllers/notifiers/blocs, how to pump widgets, any package-specific teardown required).

### `.claude/agents/developer.md`
Find the `{{STATE_MANAGEMENT}} CONVENTIONS` section. Add the mandatory rules your developer agent must enforce (e.g. "Never use setState for feature state", "Always use ConsumerWidget with Riverpod", etc.).

### `.claude/agents/architect.md`
Find the `Stack Context` placeholder. Fill in your packages and versions. Find the `Feature Folder Structure` placeholder and add your architecture's folder layout (e.g. domain/data/presentation for Clean Architecture, or view/viewmodel/model for MVVM). Find the `Architecture Layers` placeholder and define each layer's responsibilities.

### `.claude/agents/planner.md`
Find the `Implementation Order` placeholder block. Fill in your layer build sequence (which layer comes first, second, third — e.g. domain → data → presentation for Clean Architecture).

### `docs/instructions/ARCHITECTURE.md`
**This is the most important file to fill in — the developer agent reads it every session.**
- **Architecture Overview** block: Write 2–3 sentences describing your `{{ARCHITECTURE}}` pattern.
- **Layer Definitions** section: Replace the "Example — Clean Architecture" block with your own layer names and responsibilities.
- **Build Order** block: Define which layer to implement first, second, third.
- **Request Flow Example** block: Trace a concrete user action (e.g. "User taps Login") through all your layers.

### `docs/instructions/UI_INSTRUCTION.md`
Find and fill in:
- `{{STATE_MANAGEMENT}}` block under "Architecture" — your state management access pattern (how widgets read state, how state is defined).
- `{{ROUTING_SOLUTION}}` block under "Navigation Rules" — your navigation call pattern (how to push, pop, replace routes).

### `docs/instructions/API_INSTRUCTION.md`
Find and fill in:
- `{{ROUTING_SOLUTION}}` router setup block — your router configuration pattern.
- `{{DI_SOLUTION}}` binding pattern block — how dependencies are registered per route/feature.
- `{{STATE_MANAGEMENT}}` state holder pattern block — the standard boilerplate for a new state holder.

### `.claude/skills/flutter-generic-patterns/SKILL.md`
This skill is a shell with section headers only. Fill in your stack's patterns so agents can reference it as a coding guide.

> **Tip:** If you're adopting a well-known stack (Riverpod, Bloc, Provider), add your filled-in skill to claude-mem after the first feature so every future session inherits it automatically.

---

## Step 3: Register Your Project Font

Your app font must be declared in `pubspec.yaml` (under `flutter: fonts:`) and set as the default in your `ThemeData`. Then update `{{APP_FONT}}` in ui-reviewer.md so the reviewer enforces it.

---

## Step 4: Add Your FR Docs

Use `docs/FR/_fr_template.md` as the template for every new feature:
1. Copy it into `docs/FR/<module>/FR_<FeatureName>.md`
2. Fill in all sections
3. Add a row to `docs/FR/_pipeline_status.md`

---

## Step 5: Start Building

Open Claude Code in your project root. Begin with:

```
develop [your first module]
```

The agents will pick up your CLAUDE.md, read the pipeline status, and execute the full workflow.

---

## Quick Verification

After completing setup, run this grep to confirm all placeholders are gone:

```bash
grep -r "{{APP_NAME}}\|{{STATE_MANAGEMENT}}\|{{ROUTING_SOLUTION}}\|{{DI_SOLUTION}}\|{{ARCHITECTURE}}" . --include="*.md" --include="*.json"
```

Should return zero results — every placeholder replaced with your actual values.

> **Note:** The `{{STATE_MANAGEMENT}}`, `{{ROUTING_SOLUTION}}`, `{{DI_SOLUTION}}`, and `{{ARCHITECTURE}}` placeholders appear inside comment blocks in the rules and agent files. Replacing those comment blocks with real content (Step 2b) counts as filling them in — you do not need to do a string replacement on them.
