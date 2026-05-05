# Claude Code Playbooks

Production-grade Claude Code setup — documented from real project usage.

Not prompts. Not tips. A complete agentic development system: agents, orchestration, memory, gates, rules, and every workflow your team needs — written down so it works the same way every time.

---

## Playbooks

Four standalone playbooks. Each one is completely self-contained — pick the folder that matches your stack and never look at the others.

| Playbook | For |
|----------|-----|
| [**flutter-generic/**](./flutter-generic/) | Any Flutter project — Riverpod, Bloc, Provider, or anything else |
| [**flutter-getx/**](./flutter-getx/) | Flutter + GetX + Clean Architecture |
| [**laravel-generic/**](./laravel-generic/) | Any Laravel project |
| [**laravel-mvc/**](./laravel-mvc/) | Laravel with our validated MVC setup |

> Each playbook has its own README, template, and chapters. Open one folder. Everything you need is inside.

---

## What You Get

**Templates — ready to copy.**
Every playbook ships with a complete template folder. Drop it into your project root and you have a working Claude Code agent setup immediately. No manual configuration from scratch.

**Chapters — publishing progressively.**
Each playbook is backed by a detailed written guide covering why every piece of the setup exists, how to configure it correctly, and what breaks if you skip a step. Open any playbook folder to see what's currently available. Watch or star the repo to follow along as new chapters publish.

---

## What the System Covers

Every playbook documents the same core system — fully adapted for its framework:

- **CLAUDE.md** — the instruction file Claude reads at the start of every session
- **settings.json** — model selection, permissions, and environment configuration
- **Hooks** — automated triggers that fire before and after agent actions
- **Rules system** — layered rules that govern how every agent behaves
- **Specialized agents** — purpose-built agents for every stage of the development lifecycle
- **Orchestra management** — how agents are triggered, routed, and coordinated
- **MCP integration** — cross-session memory so Claude doesn't start from scratch each time
- **Token efficiency** — how to avoid burning unnecessary tokens on repeated context loading
- **Team collaboration** — what to commit, what to gitignore, how shared memory works
- **Mistakes and lessons** — what went wrong in real usage and how it was fixed

---

## How to Start

**1. Choose your playbook** from the table above.

**2. Open the playbook folder** and read its README — it tells you exactly what's covered, who it's for, and what's currently published.

**3. Copy the template into your project.** Instructions are inside each playbook's README.

**4. Follow the chapters** as they publish to understand every decision behind the setup.

---

## Who This Is For

- You use Claude Code on a real project — not a tutorial app
- You've hit the wall: inconsistent output, no memory between sessions, agents that skip steps and improvise
- You want a system that produces the same quality every session — not a collection of clever prompts

This is not plug-and-play. It takes one focused session to configure. After that, it runs itself.

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for how to report issues or suggest improvements.

Questions and discussion go in GitHub Discussions — not Issues.

---

## License

MIT — copy, adapt, and use freely.