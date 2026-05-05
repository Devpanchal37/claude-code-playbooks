# Flutter Generic Playbook

Claude Code agentic setup for any Flutter project — Riverpod, Bloc, Provider, or anything else.

> Using GetX with Clean Architecture? The [flutter-getx playbook](../flutter-getx/) covers everything here plus two additional chapters on GetX architecture.

---

## Who This Is For

- You build Flutter apps on a real project, not a tutorial
- You use Claude Code but get inconsistent results across sessions
- You want agents that follow a defined process — not ones that improvise
- You're willing to invest one focused session to configure the setup correctly

---

## What's in the Template

Copy the `template/` folder into your Flutter project root and you have a working agent setup immediately.

| What | What it does |
|------|-------------|
| **CLAUDE.md** | The instruction file Claude reads at the start of every session |
| **settings.json** | Model selection, permissions, and hook registration |
| **16 specialized agents** | One for each stage of the development lifecycle |
| **Rules system** | Layered coding standards, git workflow, security, and testing rules |
| **Hooks** | Automated triggers that fire before and after agent actions |
| **Skills** | Reusable instruction sets for recurring tasks |
| **Docs folder** | Pre-built documentation layout maintained by agents |

**The 16 agents:**

| Agent | Responsibility |
|-------|---------------|
| FR Analyst | Converts feature descriptions into structured requirement files |
| Planner | Creates implementation plans before any code is written |
| Developer | Executes full implementation across all architecture layers |
| Systematic Debugger | Investigates root cause before touching any code |
| UI Design Enforcer | Commits to design direction before any screen is built |
| Code Reviewer | Reviews changed files and their impact radius |
| Security Reviewer | Checks for security issues before any commit |
| UI Reviewer | Validates UI against your design system |
| Doc Updater | Keeps component and API registries current after every feature |
| Project Map | Tracks which modules are affected when shared files change |
| TDD Guide | Enforces test-first order — tests before implementation |
| Build Error Resolver | Handles flutter analyze failures without manual investigation |
| Refactor Cleaner | Removes dead code safely with coverage checks |
| E2E Runner | Plans and runs end-to-end test suites |
| Loop Operator | Monitors autonomous loops and intervenes when they stall |
| Architect | Handles architectural decisions and cross-module planning |

---

## Chapters

Each chapter explains why every piece of the setup exists, how to configure it correctly, and what breaks if you skip a step.

Chapters publish progressively — watch or star the repo to follow along as they drop.

| Topic |
|-------|
| Purpose, philosophy, and the mental model shift required |
| How the full system works — components, session lifecycle, routing |
| Quick start checklist — minimum viable setup in one session |
| CLAUDE.md — what to put in it, what belongs elsewhere, common mistakes |
| settings.json — permissions, model selection, hook registration |
| Hooks — what they are, when they fire, and what to automate |
| Rules system — layered standards every agent follows |
| Agent creation — gates, validation, testing, fixing misbehavior |
| Orchestra management — routing, foreground vs. background, data passing |
| Core agents deep dive — every agent explained gate by gate |
| MCP integration — cross-session memory with Claude Mem |
| Auto-memory system — file-based memory for project state |
| Project map — blast radius tracking before touching shared files |
| Docs folder — structure, ownership, and what each file is for |
| Skills — when to use them instead of agents |
| Token efficiency — how to avoid burning unnecessary tokens |
| Predefined prompt patterns — how to trigger every workflow correctly |
| Team collaboration — what to commit, what to gitignore |
| Mistakes and lessons — what went wrong in real usage and how it was fixed |
| Keeping the setup current — maintenance as the project grows |

---

## How to Start

**1. Copy the template into your Flutter project root:**

```bash
cp -r template/. your-flutter-project/
```

**2. Follow the chapters** as they publish — start with Chapter 1 and work through in order. The Quick Start chapter gets you to a working agent in one session.