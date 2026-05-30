# Chapter 11: MCP Plugins (Claude Mem)

> **Applies to:** Both
> **Prerequisites:** [Chapter 9: Orchestra Management], [Chapter 10: Core Agents Deep Dive]
> **Estimated read + setup time:** ~25 minutes

---

## TL;DR

MCP (Model Context Protocol) plugins extend Claude Code with tools that don't exist natively — external capabilities agents can call like any other tool. Claude Mem is the most important MCP plugin in this setup: it's a persistent, searchable memory database that stores past decisions, discovered mistakes, and non-obvious patterns across sessions. Without it, every agent starts from zero. With it, agents remember what failed three sessions ago and apply that knowledge automatically before writing a single line.

---

## What This Is

### MCP Plugins

An MCP plugin is an external server that Claude Code can communicate with over a defined protocol. From Claude's perspective, an MCP plugin works like any other tool — the agent calls it by name, passes parameters, and gets a result back. The difference is that the tool runs in a separate process (the MCP server), not inside Claude Code itself.

This makes MCP the extension point for capabilities that go beyond file reading, code editing, and shell commands: persistent databases, external APIs, semantic search engines, web scrapers, and more.

In Claude Code, MCP plugins are installed either via the plugin marketplace system or via manual server configuration in `settings.json`.

### Claude Mem MCP

Claude Mem is a plugin that provides a persistent cross-session observation database. Every agent in the setup can write to it and query it using natural language.

It is NOT the same as the auto-memory system covered in [Chapter 12: Auto-Memory System]. The distinction matters:

| | Auto-Memory | Claude Mem MCP |
|--|------------|----------------|
| **Storage format** | Markdown files in `.claude/projects/*/memory/` | Structured database |
| **Search** | Manual — you read MEMORY.md and open specific files | Semantic search — query with keywords, get ranked results |
| **Written by** | Main Claude, manually triggered | Any agent, as part of its workflow |
| **Best for** | User preferences, feedback, project state | Past decisions, discovered patterns, package gotchas, non-obvious mistakes |
| **Access** | File Read tool | Dedicated MCP tools (smart_search, get_observations, timeline) |
| **Editable** | Yes — plain text | Not directly — append-only database |

Both are used. They serve different purposes. Use Claude Mem for information that needs to be searchable by keyword. Use auto-memory for information that needs to be curated and edited over time.

---

## Why It Exists (The Problem It Solves)

**Without Claude Mem:**

Every agent starts with zero knowledge of past sessions. The developer agent encounters a package with a non-obvious initialization requirement, writes a workaround, and the session ends. Three sessions later, a different developer agent hits the same package issue and spends 40 minutes re-discovering the same workaround. The FR analyst proposes a design that was already rejected in a previous session because it conflicted with a business rule the product owner stated. The systematic debugger misclassifies a recurring bug pattern as a new issue and investigates from scratch.

**With Claude Mem:**

Every major agent runs a Pre-Step before doing any work. It queries Claude Mem for relevant past decisions, known package issues, and rejected approaches. The developer agent finds the workaround note before hitting the bug. The FR analyst surfaces the business rule exception before proposing designs. The systematic debugger checks for known patterns before running a full investigation. The second implementation is always better-informed than the first.

The compound effect: over 10-15 sessions, Claude Mem accumulates a project-specific knowledge base of non-obvious findings. An agent joining mid-project — or a developer joining a team — inherits this knowledge automatically.

### What This Does NOT Do

- Claude Mem is not a code documentation tool. It stores decisions and learnings, not architecture documentation. Architecture docs belong in `docs/instructions/ARCHITECTURE.md`.
- It does not replace `docs/memory/error_learnings.md`. Error learnings is a manually curated file with human-readable format. Claude Mem is a database that agents write to automatically. Both exist because they serve different access patterns.
- It does not search your codebase. It searches past observations that agents have written to the database. For codebase search, use the code-review-graph MCP or Grep.

---

## How It Works

When an agent's Pre-Step runs, it queries Claude Mem before reading any files or doing any task work:

```
Agent launches (e.g., developer agent)
      ↓
Pre-Step: Query Claude Mem
      ├─ Query 1: smart_search "[module name] pattern"
      ├─ Query 2: smart_search "[package name] gotcha"
      └─ Query 3: smart_search "[task type] decision"
      ↓
Results: 0-N observations returned (ranked by relevance)
      ↓
Agent reads relevant observations
      ↓
  ┌─ Relevant finding → Apply knowledge (avoid known pitfall, follow known pattern)
  └─ No relevant finding → Proceed with task, store finding if something non-obvious is discovered
      ↓
After task complete: Store non-obvious findings back to Claude Mem
      ↓
Future agents query and find this observation
```

Claude Mem operates as an append-only knowledge base. Agents write to it; no one edits entries. If a finding becomes outdated, agents note this in a new entry rather than editing the old one.

---

## Setup

### Prerequisites Check

- [ ] Claude Code CLI is installed (`claude --version` runs without error)
- [ ] You are in a project with a `.claude/settings.json` file (or a `~/.claude/settings.json` user-level settings file)

### Step-by-Step

#### Option A — Marketplace Plugin Install (Recommended)

The Claude Code plugin marketplace handles installation automatically. This is the approach used in this setup.

**1. Add the Claude Mem plugin source and enable it.**

Open `~/.claude/settings.json` (user-level settings, not project-level). Add the `enabledPlugins` and `extraKnownMarketplaces` blocks:

```json
{
  "enabledPlugins": {
    "claude-mem@thedotmack": true
  },
  "extraKnownMarketplaces": {
    "thedotmack": {
      "source": {
        "source": "github",
        "repo": "thedotmack/claude-mem"
      }
    }
  }
}
```

If `~/.claude/settings.json` already has content, add these keys without removing existing ones.

**2. Restart Claude Code.**

The plugin loads on session start. No additional commands are needed.

**3. Verify the tools are available.**

In a new conversation, type:
```
What claude-mem tools do you have access to?
```

Claude should list the available tools: `search`, `smart_search`, `get_observations`, `timeline`, `smart_outline`, `smart_unfold`.

---

#### Option B — Manual MCP Server Config

If you prefer explicit server configuration, or if the marketplace approach is unavailable:

**1. Clone or install the claude-mem server.**

```bash
git clone https://github.com/thedotmack/claude-mem
cd claude-mem
npm install
```

**2. Add the server to your settings.json.**

Add an `mcpServers` block to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "claude-mem": {
      "command": "node",
      "args": ["/path/to/claude-mem/index.js"],
      "env": {}
    }
  }
}
```

Replace `/path/to/claude-mem/` with the actual path where you cloned the repo.

**3. Restart Claude Code** and verify tools are available as in Option A Step 3.

---

#### Allowlisting the Tools in Project Settings

Once the plugin is installed, add the tool calls to your project's allowed permissions so agents don't trigger permission prompts mid-execution. In `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "mcp__plugin_claude-mem_mcp-search__search",
      "mcp__plugin_claude-mem_mcp-search__get_observations",
      "mcp__plugin_claude-mem_mcp-search__smart_search",
      "mcp__plugin_claude-mem_mcp-search__smart_outline",
      "mcp__plugin_claude-mem_mcp-search__smart_unfold",
      "mcp__plugin_claude-mem_mcp-search__timeline"
    ]
  }
}
```

> **NOTE:** The exact tool name prefix depends on the MCP plugin's registered name. If you use the marketplace install, the prefix will be `mcp__plugin_claude-mem_mcp-search__`. If you use a custom server name in Option B, it will be `mcp__[your-server-name]__`.

---

### Tool Reference

These are the six tools Claude Mem provides. Agents use different tools at different points in their workflow:

| Tool | What it does | When agents use it |
|------|--------------|--------------------|
| `smart_search` | Semantic search — finds relevant observations by meaning, not just exact keywords | Pre-Step: finding past decisions, patterns, gotchas |
| `search` | Keyword search — exact string matching across observations | Pre-Step: finding specific named items (package name, function name) |
| `get_observations` | Retrieve one or more specific observations by their ID | After timeline or search returns an ID for something that needs more detail |
| `timeline` | List recent observations in chronological order | Session start: orient to recent project history |
| `smart_outline` | High-level summary of what's stored across all observations | New project onboarding: understand what knowledge has been accumulated |
| `smart_unfold` | Expand a compressed observation to full detail | When smart_outline returns an entry you want to read in full |

---

## How Agents Use Claude Mem

### The Pre-Step Pattern

Every major agent in this setup runs a Pre-Step before doing task work. The Pre-Step follows this sequence:

```
1. Check error_learnings.md (file-based, grep by module/feature name)
2. Query Claude Mem (semantic search by task context)
3. Apply relevant findings
4. Proceed with task
```

Claude Mem is queried second because it stores a different type of knowledge than error_learnings.md. Error learnings stores process mistakes (wrong patterns, format violations). Claude Mem stores technical discoveries (package behaviors, architecture decisions, rejected alternatives).

### Which Agents Query and When

| Agent | Pre-Step Query | What It's Looking For |
|-------|---------------|-----------------------|
| **FR Analyst** | `smart_search "[feature topic] decision"` and `smart_search "product owner [preference type]"` | Past business rule exceptions, rejected design approaches, product owner UX preferences stated in previous FR sessions |
| **Planner** | `smart_search "[module] architecture"` and `smart_search "[tech area] pattern"` | Past architecture decisions, rejected alternatives and why, patterns already validated for this codebase |
| **Developer** | `smart_search "[package name] gotcha"` and `smart_search "[feature area] pattern"` | Package initialization quirks, non-obvious implementation patterns, known pitfalls for this feature area |
| **Systematic Debugger** | `smart_search "[bug type] pattern"` after checking error_learnings.md | Similar bugs from past sessions, root cause patterns for this class of issue |

### What Agents Store and When

Agents write to Claude Mem at the end of their workflow, when they have discovered something non-obvious. The trigger is: "would a future agent working on this area benefit from knowing this?"

| Agent | When it stores | What it stores |
|-------|----------------|----------------|
| **FR Analyst** | After pipeline update | Product owner UX preferences, business rule exceptions, approved design direction for recurring patterns |
| **Planner** | After plan is confirmed | Architectural decisions, rejected alternatives with reasoning, implementation order rationale |
| **Developer** | After feature complete | Package gotchas, non-obvious initialization requirements, patterns that required multiple attempts, workarounds and why they were needed |
| **Systematic Debugger** | After Case B confirmation (backend bug) | Bug pattern fingerprint, what the API log looked like, how the Flutter vs. backend distinction was determined |

**What NOT to store:**

- Code snippets (those belong in the codebase, not in memory)
- Git history (that's what git is for)
- Debug session transcripts (useful only in the moment, noise afterwards)
- Anything already in `docs/memory/error_learnings.md` (duplicate entries create confusion)

---

### Storage Format

Every observation stored to Claude Mem must include four fields. Vague observations are useless in search:

```
Module: [module or feature area]
Type: [decision | gotcha | pattern | preference | rejection]
Detail: [the actual finding — specific enough to be useful without additional context]
Source: [which agent stored this, and in which task context]
```

**Good observation (searchable, specific, actionable):**

```
Module: ProfileModule
Type: gotcha
Detail: cached_network_image requires a placeholder widget to avoid layout shift on first load. 
        Using fit: BoxFit.cover without an explicit width/height causes the shimmer placeholder 
        to render at zero height. Always provide an explicit height constraint.
Source: developer agent, profile card implementation
```

**Bad observation (not searchable, not actionable):**

```
Module: general
Type: note
Detail: be careful with images
Source: developer
```

The good observation can be found by searching "cached_network_image", "layout shift", "shimmer", or "placeholder". The bad one matches nothing useful.

---

## Validation

### Validation Test 1: Plugin Is Installed and Tools Are Accessible

**Purpose:** Confirm Claude Mem tools are available and Claude can call them.

**Trigger:**
In a new Claude Code conversation, type:
```
What claude-mem tools are available? List each tool name and one sentence description.
```

**Expected result:**
Claude lists 5-6 tools including `smart_search`, `get_observations`, `timeline`. It does not say "I don't have access to any claude-mem tools" or "I can't find the MCP server."

**If you see "no tools available" or an MCP connection error:**
→ The plugin did not install. Re-check `~/.claude/settings.json` — confirm `enabledPlugins` block is present and the key is exactly `claude-mem@thedotmack`. Restart Claude Code after saving.

---

### Validation Test 2: An Agent's Pre-Step Actually Queries Claude Mem

**Purpose:** Confirm that your agent files have a Pre-Step that calls Claude Mem, and that the call succeeds.

**Setup:**
Your developer agent file at `.claude/agents/developer.md` must have a Pre-Step section that includes a `smart_search` call.

**Trigger:**
Trigger your developer agent (e.g., type `develop SomeFeature`). Watch the tool calls that appear during the agent's Pre-Step.

**Expected result:**
You see a `mcp__plugin_claude-mem_mcp-search__smart_search` tool call (or similar) before the agent begins any file reading or code writing.

**If you don't see any claude-mem tool call in the Pre-Step:**
→ The agent's Pre-Step instructions don't include a Claude Mem query. Open `.claude/agents/developer.md` and add it. See the Pre-Step pattern in Section "How Agents Use Claude Mem" above.

---

### Validation Test 3: An Observation Can Be Stored and Retrieved

**Purpose:** Confirm the full read-write cycle works end to end.

**Setup:**
None required — you need a working plugin from Test 1.

**Trigger:**
Tell Claude:
```
Store this observation to claude-mem: 
Module: TestModule
Type: pattern
Detail: This is a test observation to verify the claude-mem write cycle works.
Source: manual validation test
```

Then in the same session, ask:
```
Search claude-mem for "TestModule pattern" using smart_search and show me the result.
```

**Expected result:**
The test observation you stored is returned in the search results.

**If the search returns nothing:**
→ The store call may have failed silently. Ask Claude to call the store tool explicitly and watch for any error response. If the MCP server is not running, the tool call will fail with a connection error — that means the server config is wrong (Option B) or the plugin didn't load (Option A).

---

## Common Mistakes

### Mistake 1: Not Adding Pre-Step Queries to Agent Files

**Symptom:** Agents produce work without surfacing relevant past decisions. Known mistakes get repeated across sessions.

**Cause:** Claude Mem is installed but agents don't call it. The plugin being installed doesn't automatically inject memory into every agent — each agent must explicitly query it in its Pre-Step instructions.

**Fix:** Open each major agent file (developer, planner, fr-analyst, systematic-debugger) and add a Pre-Step block that calls `smart_search` with relevant query keywords before any task work begins. See the Pre-Step pattern above.

---

### Mistake 2: Storing Vague or Duplicate Observations

**Symptom:** `smart_search` returns many results but none are useful. Search for a package name returns 8 entries, none with actionable detail.

**Cause:** Agents are storing observations that are too general ("be careful with images") or duplicating entries already in error_learnings.md.

**Fix:** Add storage format requirements to agent instructions. Require Module, Type, Detail, Source fields. Require that Detail must be specific enough to be useful without additional context. Require agents to check error_learnings.md before storing to Claude Mem — if the finding belongs there (a process mistake, a violation pattern), put it there, not in Claude Mem.

---

### Mistake 3: Treating Claude Mem as a Code Repository

**Symptom:** Observations contain large code blocks, full file contents, or long implementation details.

**Cause:** Developer agents store "what I implemented" rather than "what I discovered."

**Fix:** Claude Mem stores discoveries, not implementations. The rule: if a future agent could derive the same information by reading the current code, it doesn't belong in Claude Mem. Only store information that is non-obvious, that took effort to discover, and that would save time for a future agent facing the same situation.

---

### Mistake 4: Missing Tool Permissions in Project Settings

**Symptom:** Agent's Pre-Step triggers a permission dialog mid-execution. Or the Pre-Step fails silently when running in a non-interactive mode.

**Cause:** The claude-mem tool calls are not in the `permissions.allow` list in `.claude/settings.json`.

**Fix:** Add each claude-mem tool to the allow list in your project settings. See the "Allowlisting the Tools in Project Settings" step above. Use the exact tool names — copy them from the permission dialog that appeared, not from memory.

---

### Mistake 5: Querying Claude Mem for Information That Should Come From Files

**Symptom:** Agents query Claude Mem for the current API endpoint list, the current color system, or the current component registry. Results are outdated or empty.

**Cause:** Using Claude Mem for information that belongs in docs/memory/ files or the codebase itself.

**Fix:** Claude Mem is for non-obvious past discoveries. For current project state — available API endpoints, registered components, current error learnings — read the relevant docs/memory/ files directly (api_registry.md, component_registry.md, error_learnings.md). These files are kept current by agents after every feature. Claude Mem accumulates across sessions but doesn't replace living documentation.

---

## [Flutter-GetX Specifics]

### GetX-Specific Query Keywords

When querying Claude Mem in a GetX project, the following keywords consistently surface relevant findings:

| What you're building | Recommended Pre-Step query |
|---------------------|---------------------------|
| New controller | `smart_search "GetX controller lifecycle"` |
| IndexedStack tab | `smart_search "permanent controller"` |
| Observable list update | `smart_search "RxList assignAll"` |
| Cross-screen event | `smart_search "GetX event cross-screen"` |
| Hive storage | `smart_search "Hive box initialize"` |
| Socket.IO event | `smart_search "socket event handler pattern"` |
| New binding | `smart_search "GetX binding dependency"` |

### GetX-Specific Storage Patterns

Developer agents working in a GetX project should store to Claude Mem when they discover:

- Controller lifecycle edge cases (when permanent vs. non-permanent matters beyond the IndexedStack rule)
- `Obx` reactivity failures (cases where the expected widget didn't rebuild)
- `RxList` and `RxMap` mutation patterns that caused UI not to update
- GetX dependency injection edge cases (controller not found, wrong scope)
- Hive type adapter registration order issues
- Socket.IO event handler cleanup patterns

Format these with `Module: [module]`, `Type: gotcha`, and enough specificity that a future agent searching for the same symptom will find them.

### Storing Architecture Decisions

The planner agent should store every rejected architectural alternative to Claude Mem with `Type: rejection`. In a GetX project, this prevents a future planner from re-proposing the same approaches the team has already considered and dismissed.

Example storage format for a rejection:

```
Module: AuthModule
Type: rejection
Detail: Proposed using Get.lazyPut for AuthController. Rejected because lazyPut creates the 
        controller on first access, which means the Obx in AuthScreen finds no controller 
        on first render, causing a "controller not found" error. Use Get.put in the binding 
        instead. GetX issue — not a code bug.
Source: planner agent, auth feature planning session
```

### Team Memory in a Multi-Developer GetX Project

When multiple developers work on the same GetX project, Claude Mem operates as shared team memory only if the database is shared. By default, each Claude Code installation maintains its own database. To share:

- **File-based sharing:** Configure the claude-mem server to write to a shared path (e.g., a network drive or mounted project path). All developers point their config to the same path.
- **Server-based sharing:** Run a single claude-mem server instance and configure all developer machines to connect to it.

Without shared configuration, each developer's agents accumulate their own knowledge base. This is acceptable for solo projects but misses the team benefit: GetX-specific gotchas discovered by developer A's agent are invisible to developer B's agent until shared memory is configured.

---

## Reference

| Item | Value |
|------|-------|
| Plugin source | `thedotmack/claude-mem` (GitHub) |
| Enable in | `~/.claude/settings.json` → `enabledPlugins` |
| Tool prefix | `mcp__plugin_claude-mem_mcp-search__` |
| Primary tool | `smart_search` — used in every Pre-Step |
| What agents write | Observations: Module, Type, Detail, Source |
| What agents do NOT write | Code, architecture docs, current state, error_learnings duplicates |
| Distinguished from | Auto-memory (Chapter 12) — file-based, editable, per-developer |

---

*Next: [Chapter 12: Auto-Memory System]*
