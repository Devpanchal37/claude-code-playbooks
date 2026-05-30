# Chapter 5: settings.json

> **Applies to:** Both
> **Prerequisites:** [Chapter 4: CLAUDE.md File]
> **Estimated read + setup time:** ~25 minutes

---

## TL;DR

settings.json is where Claude Code's runtime behavior is configured: which tool calls are pre-approved, which shell commands agents can run without prompting, which hooks fire automatically, and which MCP plugins are active. Without it, agents are interrupted by permission prompts mid-execution — breaking automated gate sequences. There are two settings files: one per-project, one per-user. They merge, with project-level settings taking precedence. Most developers need to touch only the project-level file.

---

## What This Is

settings.json is a JSON configuration file that the Claude Code runtime reads when a session starts. Unlike CLAUDE.md (which shapes Main Claude's identity and reasoning), settings.json controls the runtime environment: what is allowed to run, what hooks fire automatically, and which external tools are available.

There are two distinct files:

| File | Location | Scope | Who manages it |
|------|----------|-------|----------------|
| **User-level** | `~/.claude/settings.json` | All projects for this user | Individual developer |
| **Project-level** | `.claude/settings.json` at project root | This project only | Team — committed to git |

Both files are loaded on session start and merged. When the same key appears in both, the project-level value wins.

### How It Compares to CLAUDE.md

| | settings.json | CLAUDE.md |
|--|--------------|-----------|
| What it controls | Runtime permissions, hooks, plugins | Main Claude's identity and reasoning |
| Read by | Claude Code runtime (before session begins) | Main Claude (first thing in session) |
| Format | JSON | Markdown |
| Committed to git | Project-level file: yes | Yes |
| Changes take effect | Next session start | Next session start |
| Can block tool execution | Yes — deny a tool call outright | No — CLAUDE.md is advisory |

---

## Why It Exists (The Problem It Solves)

**Without a configured settings.json:** Every tool call that isn't universally pre-approved triggers a permission prompt. An agent running a 6-step gate sequence hits a prompt on step 2 and waits for human approval. The human approves. The agent runs step 3, hits another prompt. The automation that makes agents valuable is replaced by a manual approval loop.

**With a configured settings.json:** Pre-approved tools run silently. Agents complete their entire gate sequence without interruption. Hooks fire automatically after tool calls. The system runs the way it was designed.

The concrete failure mode:

```
Without settings.json configured:

Agent step 1: Read file → PROMPT: "Allow Read?" → human approves
Agent step 2: Grep for pattern → PROMPT: "Allow Bash?" → human approves
Agent step 3: Write file → PROMPT: "Allow Write?" → human approves
Agent step 4: Run flutter analyze → PROMPT: "Allow Bash(flutter analyze)?" → human approves

→ 4 prompts for one agent step sequence
→ Agent cannot run autonomously
→ Quality gates break when human isn't watching
```

### What This Does NOT Do

- settings.json does not define agent behavior or gate sequences — those go in agent files
- settings.json does not define which agent fires for which request — that goes in agents.md and CLAUDE.md
- settings.json does not store secrets — never put API keys or tokens in this file
- Allowing a tool in settings.json does not mean Claude will use it — it only means Claude *can* use it without prompting

---

## How It Works

### The Merge Order

```
Session starts
      ↓
Claude Code reads ~/.claude/settings.json (user-level)
      ↓
Claude Code reads .claude/settings.json (project-level)
      ↓
Merges both files — project-level values win on conflict
      ↓
Result: effective settings for this session
      ↓
Main Claude starts — reads CLAUDE.md
```

**What "wins on conflict" means in practice:**

If user-level allows `Bash(flutter analyze:*)` and project-level denies it, the project-level denial wins. If user-level allows `WebFetch(domain:github.com)` and project-level has no opinion, the user-level permission carries through.

> **WARNING:** A permission allowed at user-level but not listed at project-level is still active. To restrict it for a specific project, you must explicitly deny it in the project-level file. "Not listed" means "inherit from user-level" — not "denied."

### The Permission Pattern Syntax

Permissions use a `Tool(pattern)` syntax. The pattern controls which specific calls are approved:

| Pattern | Meaning |
|---------|---------|
| `"Read"` | Allow all Read calls |
| `"Read(path/*)"` | Allow Read only within that path |
| `"Bash(flutter analyze:*)"` | Allow `flutter analyze` with any arguments |
| `"Bash(git log:*)"` | Allow `git log` with any arguments |
| `"WebFetch(domain:github.com)"` | Allow WebFetch only to github.com |
| `"WebSearch"` | Allow all web searches |

The `:*` suffix on Bash patterns matches any argument after the command. `"Bash(flutter:*)"` matches `flutter analyze`, `flutter build`, `flutter clean`, and anything else starting with `flutter`. Be specific — `"Bash(flutter analyze:*)"` is safer than `"Bash(flutter:*)"`.

> **CRITICAL:** Never add `"Bash"` (with no pattern) to the allow list. This allows any shell command — including `rm -rf`, `git reset --hard`, and destructive operations. Agents running with unrestricted Bash access can delete files, push to remote, and overwrite local changes without a prompt.  
> If violated: an agent bug or a badly formed agent prompt can run a destructive shell command silently.

---

## Setup

### Prerequisites Check

- [ ] `.claude/` directory exists at project root
- [ ] Claude Code CLI is installed and `claude --version` works
- [ ] You know which tools your agents will need (check agent files for Bash calls)

### Step-by-Step

**1. Create the project-level settings file**

Create `.claude/settings.json` at the project root. Start with the minimum structure:

```json
{
  "permissions": {
    "allow": []
  },
  "hooks": {}
}
```

**2. Add permissions for the tools your agents need**

Every tool call an agent makes must either be pre-approved here or it will prompt. Add the minimum set your agents actually use. Start with these — they cover the core agent workflows:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Write",
      "Edit",
      "Grep",
      "Glob",
      "Bash(git log:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)"
    ]
  }
}
```

**3. Add Flutter-specific Bash permissions**

For Flutter projects, add the Flutter commands your developer agent runs:

```json
"Bash(flutter analyze:*)",
"Bash(flutter test:*)",
"Bash(flutter pub:*)",
"Bash(dart format:*)"
```

**4. Add WebFetch permissions if agents fetch external resources**

Restrict to the specific domains your agents actually need. Never allow all WebFetch:

```json
"WebFetch(domain:pub.dev)",
"WebFetch(domain:api.github.com)"
```

**5. Add additionalDirectories if agents read files outside the project root**

If your agents need to read agent files, rules, or memory from `~/.claude/`, add:

```json
"additionalDirectories": [
  "C:\\Users\\[username]\\.claude\\agents",
  "C:\\Users\\[username]\\.claude\\rules\\common"
]
```

On macOS/Linux:
```json
"additionalDirectories": [
  "/Users/[username]/.claude/agents",
  "/Users/[username]/.claude/rules/common"
]
```

**6. Register hooks**

Hooks fire automatically when specific tool calls complete. Add them under the `"hooks"` key. See [Chapter 6: Hooks] for full hook design guidance. The most common hook for a Flutter project:

```json
"hooks": {
  "PostToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [
        {
          "type": "command",
          "command": "dart format .",
          "timeout": 5000
        }
      ]
    }
  ]
}
```

**7. Add MCP plugin configuration if installing plugins**

MCP plugins (like Claude Mem) are registered in the user-level settings file, not project-level. See [Chapter 11: MCP Plugins] for the exact installation config.

---

### Configuration Reference

Complete annotated settings.json showing every meaningful key:

```json
{
  "permissions": {

    "allow": [
      // --- File system tools ---
      // Allow all Read calls project-wide (safe — Read is non-destructive)
      "Read",

      // Allow Write and Edit — needed for agents that create or modify files
      "Write",
      "Edit",

      // Allow search tools — agents use these constantly
      "Grep",
      "Glob",

      // --- Bash: allow specific commands only ---
      // Git read-only commands — safe to allow broadly
      "Bash(git log:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",

      // Flutter/Dart commands your developer agent runs
      "Bash(flutter analyze:*)",
      "Bash(flutter test:*)",
      "Bash(flutter pub:*)",
      "Bash(flutter clean:*)",
      "Bash(dart format:*)",

      // Package manager commands
      "Bash(gh api:*)",
      "Bash(gh search:*)",

      // --- Web access: restrict to specific domains ---
      "WebFetch(domain:pub.dev)",
      "WebFetch(domain:api.github.com)",
      "WebFetch(domain:raw.githubusercontent.com)"
    ],

    // Directories outside the project root that agents need to read
    // Common: shared agent files, rules, user-level memory
    "additionalDirectories": [
      "~/.claude/agents",
      "~/.claude/rules/common"
    ]
  },

  "hooks": {

    // PostToolUse: fires after a tool call completes
    "PostToolUse": [
      {
        // "matcher" uses | to combine tool names — fires after any Edit or Write call
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            // The shell command to run
            "command": "dart format .",
            // Timeout in milliseconds — hook is killed if it exceeds this
            "timeout": 5000
          }
        ]
      }
    ],

    // SessionStart: fires when the session begins, before Main Claude reads CLAUDE.md
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Session started'",
            "timeout": 2000
          }
        ]
      }
    ]
  }
}
```

---

### Model Selection (Set in Agent Files, Not settings.json)

Model selection per agent is controlled in the agent file's frontmatter, not in settings.json. This is a common point of confusion.

In `.claude/agents/[agent-name].md`:

```yaml
---
name: developer
description: Complete implementation workflow executor
tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
model: sonnet
---
```

The model values and when to use each:

| Model | Use when | Example agents |
|-------|----------|---------------|
| `haiku` | Deterministic, rule-following, no judgment needed — runs frequently | doc-updater, project-map, ui-design-enforcer |
| `sonnet` | Judgment-heavy work — code writing, investigation, review | developer, code-reviewer, systematic-debugger, fr-analyst |
| `opus` | Architectural reasoning — quality of thinking multiplies all subsequent work | planner |

**Why this matters for cost:** doc-updater and project-map run after every feature (Phase 4 of the quality loop). Using `sonnet` for these instead of `haiku` costs 3× more per invocation with no quality gain. These are deterministic tasks — find new component, format registry entry, write it. Haiku handles this correctly and cheaply.

---

## Validation

### Validation Test 1: Permission Allows Agent to Run Without Prompting

**Purpose:** Verify that `flutter analyze` runs without a permission prompt.

**Setup:**
Add `"Bash(flutter analyze:*)"` to the allow list in `.claude/settings.json`.

**Trigger:**
In a new session, type:
```
Run flutter analyze and tell me if there are any issues.
```

**Expected result:**
Main Claude runs `flutter analyze` without asking "Allow Bash command?" The output of `flutter analyze` appears in the response.

**If you see a permission prompt instead:**
→ The permission entry is missing or malformed. Check that it reads exactly `"Bash(flutter analyze:*)"` with the `:*` suffix. Without `:*`, the pattern matches only `flutter analyze` with no arguments — any argument triggers the prompt.

---

### Validation Test 2: Merge Order Check

**Purpose:** Verify that project-level settings override user-level settings.

**Setup:**
Add a permission to your user-level `~/.claude/settings.json` that is NOT in the project-level file.

**Trigger:**
Attempt to use the tool that the user-level permission covers, in a session for this project.

**Expected result:**
The tool runs without a prompt — the user-level permission carries through because the project-level file has no opinion on it.

**Now add a deny for the same tool at project level and repeat.**

**Expected result:**
The tool now prompts for permission — the project-level deny overrides the user-level allow.

---

### Validation Test 3: Hook Fires on File Write

**Purpose:** Verify the PostToolUse hook fires automatically after a Write call.

**Setup:**
Add a PostToolUse hook that runs a simple echo command after any Write:

```json
"PostToolUse": [
  {
    "matcher": "Write",
    "hooks": [{ "type": "command", "command": "echo HOOK_FIRED", "timeout": 3000 }]
  }
]
```

**Trigger:**
Ask Main Claude to create any small test file.

**Expected result:**
After the file is written, `HOOK_FIRED` appears in the terminal output (or session output, depending on your Claude Code version). The file creation and the hook output appear in sequence.

**If no hook output appears:**
→ Check the `"matcher"` value. It must exactly match the tool name: `"Write"`, `"Edit"`, `"Bash"`. Check the JSON is valid — an extra comma or missing brace breaks the whole file silently.

---

## Common Mistakes

### Mistake 1: Allowing All Bash

**Symptom:** Agents run shell commands without any prompting — including destructive ones.

**Cause:** `"Bash"` (no pattern) was added to the allow list, either intentionally ("to stop the prompts") or by copy-pasting an example.

**Fix:** Remove `"Bash"` from the allow list. Replace with specific patterns for each command the agents actually need:
```json
"Bash(flutter analyze:*)",
"Bash(git log:*)",
"Bash(dart format:*)"
```
If a new prompt appears for a command you want to allow, add the specific pattern — not the wildcard.

---

### Mistake 2: Permission Added But Prompt Still Appears

**Symptom:** A Bash permission is in the allow list but the tool still prompts.

**Cause:** The pattern doesn't match the actual command. Most common variants:
- Missing `:*` — `"Bash(flutter analyze)"` matches only the command with no args. `flutter analyze --no-fatal-infos` does not match.
- Wrong command name — `"Bash(flutter analyse:*)"` (typo) does not match `flutter analyze`.
- Whitespace inside the pattern — `"Bash( flutter analyze:*)"` (leading space) does not match.

**Fix:** Copy the exact command from the agent output when the prompt appeared, then construct the pattern from that. Use `:*` for any command that takes arguments.

---

### Mistake 3: Project settings.json Not Committed

**Symptom:** A second developer on the team is constantly getting permission prompts for commands the first developer pre-approved.

**Cause:** `.claude/settings.json` was added to `.gitignore` or simply never committed.

**Fix:** Commit `.claude/settings.json` to git. This is a team file, not a personal file. The user-level `~/.claude/settings.json` is personal — keep that out of git. The project-level file is shared — it must be in the repo.

Add this to `.gitignore` if not already there:
```
# Personal Claude settings — never commit
~/.claude/settings.json
```
And ensure the project-level file is NOT in `.gitignore`.

---

### Mistake 4: Secrets Stored in settings.json

**Symptom:** API keys, tokens, or passwords are hardcoded in the `"allow"` array or in a custom env vars section.

**Cause:** Developer needed agents to have access to an API key and put it directly in the config.

**Fix:** Never put secrets in settings.json. Settings.json is committed to git — any secret in it is in the git history permanently. Use environment variables instead:
- Set `MY_APP_API_KEY=xxx` in your shell profile or CI environment
- Reference it in agent prompts as `$MY_APP_API_KEY`
- Or use a `.env` file that is gitignored

---

### Mistake 5: Hook Timeout Too Short

**Symptom:** A hook command is registered but sometimes doesn't complete. No error is shown — the hook silently times out.

**Cause:** The `"timeout"` value (in milliseconds) is shorter than the command takes to run. `flutter analyze` on a large project can take 10–30 seconds. A 3000ms timeout kills it early.

**Fix:** Set realistic timeouts. `dart format` is fast — 3000ms is fine. `flutter analyze` on a real project — set 30000ms (30 seconds). `flutter test` — 60000ms minimum.

```json
{
  "type": "command",
  "command": "flutter analyze --no-fatal-infos",
  "timeout": 30000
}
```

---

## [Flutter-GetX Specifics]

The GetX setup adds three things to the generic configuration: `build_runner` permissions for code generation, pre-approved MCP tool calls so agent Pre-Steps don't prompt, and a PostToolUse hook that keeps the code-review-graph current after every file change.

### Complete Project settings.json for a GetX Project

This is the annotated production configuration. Adapt paths for your OS (Windows paths shown — swap backslashes for forward slashes on macOS/Linux):

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Write",
      "Edit",
      "Grep",
      "Glob",

      "Bash(flutter analyze:*)",
      "Bash(flutter test:*)",
      "Bash(flutter pub:*)",
      "Bash(flutter clean:*)",
      "Bash(dart format:*)",
      "Bash(dart fix:*)",

      "Bash(dart run build_runner:*)",

      "Bash(git log:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",

      "Bash(gh search:*)",
      "Bash(gh api:*)",

      "WebFetch(domain:pub.dev)",
      "WebFetch(domain:raw.githubusercontent.com)",
      "WebFetch(domain:api.github.com)",

      "mcp__plugin_claude-mem_mcp-search__search",
      "mcp__plugin_claude-mem_mcp-search__get_observations",
      "mcp__plugin_claude-mem_mcp-search__smart_search",
      "mcp__plugin_claude-mem_mcp-search__timeline",

      "mcp__code-review-graph__get_review_context_tool",
      "mcp__code-review-graph__get_impact_radius_tool",
      "mcp__code-review-graph__detect_changes_tool",
      "mcp__code-review-graph__query_graph_tool",
      "mcp__code-review-graph__semantic_search_nodes_tool"
    ],

    "additionalDirectories": [
      "C:\\Users\\[username]\\.claude\\agents",
      "C:\\Users\\[username]\\.claude\\rules\\common",
      "C:\\Users\\[username]\\.claude\\projects\\[project-hash]\\memory"
    ]
  },

  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "code-review-graph update --quiet",
            "timeout": 5000
          }
        ]
      }
    ],

    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "code-review-graph status --json",
            "timeout": 3000
          }
        ]
      }
    ]
  }
}
```

### Why Each GetX-Specific Entry Is Needed

| Entry | Why the GetX setup needs it |
|-------|---------------------------|
| `"Bash(dart run build_runner:*)"` | GetX uses `envied` for env vars and `hive_flutter` for local storage — both require code generation. Developer agent runs this after model changes. |
| `"Bash(dart fix:*)"` | Developer agent runs this after structural refactors to apply Dart's automatic fixes, preventing lint noise on otherwise-correct code. |
| `"mcp__plugin_claude-mem_mcp-search__*"` | Every major agent (developer, planner, fr-analyst, systematic-debugger) runs a claude-mem Pre-Step before starting work. Without these pre-approved, the Pre-Step prompts 4× per agent launch. |
| `"mcp__code-review-graph__*"` | code-reviewer uses `get_review_context_tool` and `get_impact_radius_tool` before every review. Without pre-approval, code-reviewer is interrupted at the start of every review session. |
| Graph hook on `Edit\|Write\|Bash` | The code-review-graph must stay current for impact analysis to be accurate. A graph that's one feature behind shows wrong blast-radius results and causes code-reviewer to miss impacted files. |
| SessionStart graph status | Agents can read this output at session start to know whether the graph is indexed and ready before they call graph tools. |

### Finding Your Project Hash for additionalDirectories

Claude stores per-project memory under a hashed path. To find it:

```bash
# Run this in any terminal
ls ~/.claude/projects/
```

The directory name is a hash of your project path. It looks like: `d--local-diskD-project-myapp`. Add the full path including the memory subdirectory to `additionalDirectories` so agents can read auto-memory files.

### MCP Tool Naming Convention

MCP tool permission strings follow the pattern:
```
mcp__[server-name]__[tool-name]
```

The server name in the permission string must match exactly how the MCP server is registered in your user-level settings.json. If the claude-mem server is registered as `plugin_claude-mem_mcp-search`, that exact string (with underscores) is what goes in the permission entry. When in doubt, attempt a tool call and read the permission prompt — it shows the exact string you need.

---

## Reference

| Item | Value |
|------|-------|
| Project-level file | `.claude/settings.json` at project root |
| User-level file | `~/.claude/settings.json` |
| Merge behavior | Both loaded; project-level wins on conflict |
| Commit to git | Project-level: yes. User-level: no. |
| Model selection | Set in agent file frontmatter, not here |
| MCP plugin installation | Set in user-level settings.json (see Chapter 11) |
| Hook definitions | Under `"hooks"` key in project-level settings |
| Secrets | Never here — use environment variables |
| Key risk | `"Bash"` with no pattern = unrestricted shell access |
| GetX additions | `build_runner`, `dart fix`, claude-mem MCP tools, code-review-graph MCP tools, graph update hook |

---

*Next: [Chapter 6: Hooks]*
