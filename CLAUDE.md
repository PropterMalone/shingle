# Shingle — Project CLAUDE.md

**Purpose:** Claude Code starter kit that lets non-technical professionals build tools for their work through vibecoding.

Last verified: 2026-02-11

## Vision

Shingle's value over ChatGPT isn't "AI can help with documents." The new thing is what Claude Code specifically does:

1. **Files appear on your machine.** Ask for a review and a real file appears in your folder. No copy-paste from a chat window.
2. **It builds tools for you.** Describe what you need — a tracker, a dashboard, a comparison tool — and it creates it.
3. **It operates, not just talks.** It reads directories, organizes files, processes data, creates deliverables — it *does work*, not just suggests it.

Users are non-technical professionals who vibecode through Claude. They don't write code — Claude does. The tech stack is pre-installed so Claude can use it immediately.

## Three-Phase Architecture

**Phase 1 (host):** User pastes a one-liner from their onboarding email. `bootstrap/setup.ps1` (Windows) or `bootstrap/setup.sh` (Mac) installs Git, Docker Desktop, VS Code, Dev Containers extension, and Claude Code. Sets practice area, creates ClientWork folder, opens VS Code at the project. No conversational setup — the script handles everything mechanically.

**Phase 2 (container):** User clicks "Reopen in Container" in VS Code. `welcome.sh` reads `~/.shingle/config`, assembles the Phase 2 CLAUDE.md from base + practice-area overlay, installs ed3d plugins, injects safety hooks. User types `claude` and gets the sandboxed tool-building experience.

**Phase transition:** `bootstrap/CLAUDE.md` is a troubleshooter (only relevant if someone manually runs `claude` from bootstrap/). Phase 2 CLAUDE.md is assembled by `welcome.sh` into `/workspace/documents/CLAUDE.md`. Since the container's WORKDIR is `/workspace/documents/`, Claude finds Phase 2 first.

**Authentication:** Claude Pro/Max subscription via browser-based OAuth. Claude Code shows a URL, user opens it in their host browser, authorizes, and the CLI continues. No API keys needed for the standard flow. Optional API key support for power users (`~/.shingle/env`).

## Client Tech Stack (in container)

Pre-installed at build time — clients never install anything:

- **Node.js 20** (base image)
- **TypeScript** — Claude sets up tsconfig per-project as needed
- **Vite** — globally installed, for web apps and dev server
- **npm** — package management when Claude builds bigger tools
- **Python 3** + pandas, matplotlib, openpyxl, xlsxwriter — data analysis
- **pandoc** — document conversion (md -> pdf/docx)
- **chart.js** — pre-installed at `/home/node/.shingle-lib/` for embedding in HTML tools
- **ed3d plugins** — plan-and-execute, house-style, basic-agents, research-agents

### Tool-building tiers (defined in templates/CLAUDE.md.base)

1. **Documents:** Markdown + pandoc -> pdf/docx
2. **Web tools:** Single-file HTML with inline JS + chart.js (open in browser)
3. **Data analysis:** Python scripts with pandas/matplotlib
4. **Bigger tools:** TypeScript + Vite + npm (with per-project CLAUDE.md)

## Directory Structure

```
CLAUDE.md               # This file (project dev context)
README.md               # GitHub-facing project description
bootstrap/              # One-command setup scripts
  CLAUDE.md             #   Troubleshooter (if someone runs claude here manually)
  setup.ps1             #   Windows bootstrap
  setup.sh              #   Mac bootstrap
  onboard.ps1           #   Client onboarding (opens Gmail compose)
.devcontainer/          # VS Code devcontainer (Dockerfile, scripts)
  Dockerfile            #   Container image (Node, Python, pandoc, chart.js, ed3d plugins)
  devcontainer.json     #   Container config (mounts, extensions, commands)
  init-firewall.sh      #   Network firewall (iptables allowlist)
  welcome.sh            #   First-run setup (CLAUDE.md assembly, plugin install, hooks)
templates/              # CLAUDE.md templates per practice area
  CLAUDE.md.base        #   Shared foundation (all practice areas) — includes tool-building tiers
  CLAUDE.md.{area}      #   Practice-area overlays (legal, audit, policy, govcon, educator)
  hooks.json            #   Safety hooks template
plugin/                 # Dormant — future custom plugin (skills, hooks, MCP servers)
  plugins/shingle/      #   Federal Register MCP server source, hook definitions
docs/                   # User-facing documentation
  QUICKSTART.md         #   10-min setup guide
  FIRST-SESSION.md      #   15-min first-use walkthrough
```

## Target User

- **Has used** ChatGPT or similar through a web chat interface
- **Has not used** a CLI, terminal, or anything like Claude Code
- **Don't explain** what AI is, how prompting works, or that AI can write — they already know
- **Do explain** the terminal, why they're typing instead of clicking, and what files/folders are in this context
- **Expect them to ask Claude to build things** — trackers, dashboards, calculators, comparison tools, data pipelines

## Conventions

- **Audience:** All user-facing text assumes zero terminal experience. No jargon.
- **Templates:** `CLAUDE.md.base` is the shared foundation; practice-area overlays appended by `welcome.sh`
- **Auth model:** OAuth via Claude Pro/Max subscription (browser-based). Optional API key via `~/.shingle/env`.
- **Plugin installation:** ed3d-plugins are cloned during Docker build (`/home/node/.ed3d-plugins`), registered as local marketplace at runtime, installed via `claude plugin install` in `welcome.sh`.
- **Safety hooks:** Injected into `~/.claude/settings.json` by `welcome.sh` — block writes outside `/workspace/documents/`, block executable file types, warn on delete commands.
- **Firewall:** Blocks all outbound except Anthropic API, OAuth domains, npm, Federal Register, GitHub, and DNS.
- **File paths:** All document and tool work happens in `/workspace/documents/` inside the container.
- **Config location:** `~/.shingle/` on host — contains `config` (practice area) and optionally `env` (API key for power users).
- **Named volume:** `claude-config` persists `~/.claude` across container rebuilds. Plugins and hooks must be installed at runtime, not bake time.
- **Updates:** `git pull --ff-only` in postStartCommand. Push to GitHub -> client gets updates on next container start.

## Key Design Decisions

- **Two-phase bootstrap:** Phase 1 is a deterministic install script (no conversational Claude), Phase 2 is sandboxed (Claude in the container). The script handles all mechanical installs; Claude only runs inside the container.
- **Tool-building is first-class:** The container ships with a full dev stack (TS, Vite, npm, Python, pandoc, chart.js) so Claude can build tools immediately. The CLAUDE.md.base defines a tiered approach from simple HTML to full TypeScript projects.
- **OAuth-first auth:** Clients use Claude Pro/Max subscriptions. No API key required. Optional `~/.shingle/env` for power users.
- **ed3d plugins via local marketplace:** Clone at build time, `claude plugin marketplace add` with local path at runtime. Bypass network dependency (GitHub CDN defeats DNS-based firewall).
- **Named volume for .claude:** Session data survives container rebuild. Plugin/hook installation must happen at runtime (postAttachCommand).
- **Pre-installed everything:** All tools installed at image build time. No PyPI/npm registry access needed at runtime for the base stack. Claude can install additional npm packages per-project as needed.

## Future Work

- **Federal Register MCP server:** Source lives in `plugin/plugins/shingle/servers/federal-register/`. Not currently built or deployed.
- **Custom slash commands:** Could convert common workflows into commands for discoverability. Requires working plugin installation.
- **Additional MCP servers:** Domain-specific data sources (PACER for legal, SAM.gov for govcon, etc.).
- **Cloudflare deployment:** Let clients deploy tools to the web for their own clients. Requires Cloudflare account setup — future Phase 3 feature.
- **Mac bootstrap:** `setup.sh` needs same git clone approach as `setup.ps1`.
- **Biome/Vitest evaluation:** Currently not pre-installed. Evaluate whether linting and testing help or add noise for vibecoding clients.
