# Shingle — Development Guide (for contributors)

**Purpose:** Claude Code starter kit for non-technical ex-federal consultants starting solo practices.

Last verified: 2026-02-11

## What This Is

Four-part toolkit:
1. **Bootstrap scripts** — PowerShell/Bash scripts that install Claude Code, which then walks the user through installing Docker, VS Code, API key setup, and practice area selection conversationally (Phase 1)
2. **Devcontainer** — isolated environment with Claude Code, Python, pandoc, and chart.js pre-installed, network-firewalled, client documents mounted from host (Phase 2)
3. **Claude Code plugin** — practice-area skills (`/review`, `/summarize`, `/draft`) and CLAUDE.md templates that make Claude talk to consultants, not developers
4. **MCP servers** — tool servers that give Claude live data access (e.g., Federal Register search)

## Two-Phase Architecture

**Phase 1 (host):** User runs `bootstrap/setup.ps1` (Windows) or `bootstrap/setup.sh` (Mac). The script installs Claude Code, then Claude reads the root `CLAUDE.md` (setup instructions) and walks the user through prerequisite installation. Practice area choice is saved to `~/.shingle/config`.

**Phase 2 (container):** User opens VS Code → "Reopen in Container". `welcome.sh` reads `~/.shingle/config`, assembles the Phase 2 CLAUDE.md from base + practice-area overlay, installs the plugin. User types `claude` and gets the sandboxed consulting experience.

**Phase transition:** Root `CLAUDE.md` is Phase 1 setup instructions. Phase 2 CLAUDE.md is assembled by `welcome.sh` into `/workspace/documents/CLAUDE.md`. Since the container's WORKDIR is `/workspace/documents/`, Claude finds Phase 2 first.

## Tech Stack

- **Container:** Docker (devcontainer spec), node:20-bookworm
- **Container tools:** Python 3 (pandas, matplotlib, openpyxl, xlsxwriter), pandoc, chart.js, vite
- **Plugin format:** Claude Code plugin spec (plugin.json + SKILL.md files)
- **MCP servers:** TypeScript, `@modelcontextprotocol/sdk`, compiled at container build time
- **Templates:** Markdown (CLAUDE.md files per practice area)
- **Testing:** Vitest (MCP server tests only)
- **Docs:** Markdown, written for non-technical audience

## Directory Structure

```
CLAUDE.md               # Phase 1 setup instructions (read by host-mode Claude)
DEVELOPMENT.md          # This file (dev guide for contributors)
bootstrap/              # One-command setup scripts
  setup.ps1             #   Windows bootstrap
  setup.sh              #   Mac bootstrap
.devcontainer/          # VS Code devcontainer (Dockerfile, scripts)
  Dockerfile            #   Container image (Node, Python, pandoc, chart.js)
  devcontainer.json     #   Container config (mounts, extensions, commands)
  init-firewall.sh      #   Network firewall (iptables allowlist)
  welcome.sh            #   First-run setup (CLAUDE.md assembly, plugin install)
plugin/                 # Claude Code plugin
  skills/               #   Slash-command skills (SKILL.md files)
  hooks/                #   Hook definitions (executable file blocking)
  servers/              #   MCP tool servers (TypeScript, built at container build)
  .mcp.json             #   MCP server manifest (server name -> command)
templates/              # CLAUDE.md templates per practice area
  CLAUDE.md.base        #   Shared foundation (all practice areas)
  CLAUDE.md.{area}      #   Practice-area overlays (legal, audit, policy, govcon)
docs/                   # User-facing documentation
  QUICKSTART.md         #   10-min setup guide
  FIRST-SESSION.md      #   15-min first-use walkthrough
```

## Target User

- **Has used** ChatGPT or similar through a web chat interface
- **Has not used** a CLI, terminal, or anything like Claude Code
- **Don't explain** what AI is, how prompting works, or that AI can write — they already know
- **Do explain** the terminal, why they're typing instead of clicking, and what files/folders are in this context

**Value proposition:** Not "AI can help with documents" — ChatGPT does that. The new thing is what Claude Code specifically does:
- **Files appear on your machine.** `/review` creates a real file in your folder. No copy-paste from a chat window.
- **It builds tools for itself.** Describe a workflow once, CC writes a skill that repeats it.
- **It calls functions.** It reads directories, moves files, runs commands — it *operates*, not just talks.

## Conventions

- **Audience:** All user-facing text assumes zero terminal experience. No jargon.
- **Skills:** Each skill is a SKILL.md in `plugin/skills/{name}/`
- **MCP servers:** Each server is a TypeScript project in `plugin/servers/{name}/`, registered in `plugin/.mcp.json`
- **Templates:** `CLAUDE.md.base` is the shared foundation; practice-area overlays appended by `welcome.sh`
- **Safety first:** Firewall blocks all outbound except Anthropic API, npm, and allowlisted data sources. Hooks block executable file types in documents directory.
- **File paths:** All document work happens in `/workspace/documents/` inside the container
- **Config location:** `~/.shingle/` on host — contains `env` (API key) and `config` (practice area)

## Commands

```bash
npm run test              # Run MCP server tests (vitest)
npm run test:watch        # Watch mode
```

No build step — the CLI was removed in v0.2.0. The root project is config and templates only. MCP servers have their own TypeScript build in the Dockerfile.

## Key Design Decisions

- **Two-phase bootstrap:** Phase 1 is conversational (Claude on the host), Phase 2 is sandboxed (Claude in the container). No programmatic CLI.
- **No auth / no accounts:** API key is the only credential, stored on host at `~/.shingle/env`
- **Read-only config mount:** `~/.shingle/` mounted read-only into container — API key and config can't be modified from inside
- **Named volume for .claude:** Session data survives container rebuild
- **Plugin copied at build:** Baked into the image, not bind-mounted — survives if host path moves
- **Practice area selected once in Phase 1:** Saved to `~/.shingle/config`, read by `welcome.sh` — no interactive prompt in container
- **Executable file hook:** Blocks `.bat`, `.ps1`, `.exe`, `.cmd`, `.vbs` creation in `/workspace/documents/`
- **Pre-installed tool stack:** Python packages, pandoc, chart.js, vite all installed at image build time. No PyPI access at runtime (firewall blocks it).
- **MCP servers built in Dockerfile:** `npm install && tsc && npm prune --production` at image build time, not runtime
- **Firewall allowlist per server:** Each MCP server's external host must be added to `init-firewall.sh`
