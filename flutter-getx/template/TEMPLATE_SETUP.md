# Flutter + GetX Claude Code Setup — Template Guide

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

After completing setup, run this grep to confirm the app name placeholder is gone:

```bash
grep -r "{{APP_NAME}}" . --include="*.md" --include="*.json"
```

Should return zero results — every `{{APP_NAME}}` replaced with your actual app name.
