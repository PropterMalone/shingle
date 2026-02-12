# Shingle — Development Guide (for contributors)

**Purpose:** Claude Code starter kit for non-technical solo consultants starting independent practices.

Last verified: 2026-02-11

## What This Is

Three-part toolkit:
1. **Bootstrap scripts** — PowerShell/Bash scripts that install Claude Code, which then walks the user through installing Docker, VS Code, and practice area selection conversationally (Phase 1)
2. **Devcontainer** — isolated environment with Claude Code, Python, pandoc, chart.js, and ed3d plugins pre-installed, network-firewalled, client documents mounted from host (Phase 2)
3. **CLAUDE.md templates** — practice-area configurations that make Claude talk to consultants, not developers, plus guidance for building tools with TypeScript/Vite

## Two-Phase Architecture

**Phase 1 (host):** User runs `bootstrap/setup.ps1` (Windows) or `bootstrap/setup.sh` (Mac). The script installs Claude Code, then Claude reads the root `CLAUDE.md` (setup instructions) and walks the user through prerequisite installation. Practice area choice is saved to `~/.shingle/config`.

**Phase 2 (container):** User opens VS Code -> "Reopen in Container". `welcome.sh` reads `~/.shingle/config`, assembles the Phase 2 CLAUDE.md from base + practice-area overlay, installs ed3d plugins, injects safety hooks. User types `claude` and gets the sandboxed consulting experience.

**Phase transition:** Root `CLAUDE.md` is Phase 1 setup instructions. Phase 2 CLAUDE.md is assembled by `welcome.sh` into `/workspace/documents/CLAUDE.md`. Since the container's WORKDIR is `/workspace/documents/`, Claude finds Phase 2 first.

**Authentication:** Claude Pro/Max subscription via browser-based OAuth. Claude Code shows a URL, user opens it in their host browser, authorizes, and the CLI continues. No API keys needed for the standard flow. Optional API key support exists for power users (`~/.shingle/env`).

## Tech Stack

- **Container:** Docker (devcontainer spec), node:20-bookworm
- **Container tools:** Python 3 (pandas, matplotlib, openpyxl, xlsxwriter), pandoc, chart.js, vite
- **Plugins:** ed3d-plugins (plan-and-execute, house-style, basic-agents, research-agents) — installed via direct file copy at runtime
- **Templates:** Markdown (CLAUDE.md files per practice area)
- **Docs:** Markdown, written for non-technical audience
- **Tool-building defaults (for clients):** TypeScript, Vite, npm

## Directory Structure

```
CLAUDE.md               # Phase 1 setup instructions (read by host-mode Claude)
DEVELOPMENT.md          # This file (dev guide for contributors)
bootstrap/              # One-command setup scripts
  setup.ps1             #   Windows bootstrap
  setup.sh              #   Mac bootstrap
.devcontainer/          # VS Code devcontainer (Dockerfile, scripts)
  Dockerfile            #   Container image (Node, Python, pandoc, chart.js, ed3d plugins)
  devcontainer.json     #   Container config (mounts, extensions, commands)
  init-firewall.sh      #   Network firewall (iptables allowlist)
  welcome.sh            #   First-run setup (CLAUDE.md assembly, plugin install, hooks)
templates/              # CLAUDE.md templates per practice area
  CLAUDE.md.base        #   Shared foundation (all practice areas)
  CLAUDE.md.{area}      #   Practice-area overlays (legal, audit, policy, govcon)
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

**Value proposition:** Not "AI can help with documents" — ChatGPT does that. The new thing is what Claude Code specifically does:
- **Files appear on your machine.** Ask for a review and a real file appears in your folder. No copy-paste from a chat window.
- **It builds tools for you.** Describe what you need — a tracker, a dashboard, a comparison tool — and it creates it.
- **It operates, not just talks.** It reads directories, organizes files, processes data, creates deliverables — it *does work*, not just suggests it.

## Conventions

- **Audience:** All user-facing text assumes zero terminal experience. No jargon.
- **Templates:** `CLAUDE.md.base` is the shared foundation; practice-area overlays appended by `welcome.sh`
- **Auth model:** OAuth via Claude Pro/Max subscription (browser-based). Optional API key support via `~/.shingle/env`.
- **Plugin installation:** ed3d-plugins are cloned during Docker build (`/home/node/.ed3d-plugins`), then copied to Claude Code plugin directories at runtime by `welcome.sh` (because the named volume hides baked-in image content).
- **Safety hooks:** Injected into `~/.claude/settings.json` by `welcome.sh` — block writes outside `/workspace/documents/`, block executable file types, warn on delete commands.
- **Firewall:** Blocks all outbound except Anthropic API, OAuth domains, npm, Federal Register, GitHub, and DNS.
- **File paths:** All document work happens in `/workspace/documents/` inside the container.
- **Config location:** `~/.shingle/` on host — contains `config` (practice area) and optionally `env` (API key for power users).
- **Named volume:** `claude-config` persists `~/.claude` across container rebuilds. This is why plugins and hooks must be installed at runtime, not bake time.

## Key Design Decisions

- **Two-phase bootstrap:** Phase 1 is conversational (Claude on the host), Phase 2 is sandboxed (Claude in the container). No programmatic CLI.
- **OAuth-first auth:** Clients use Claude Pro/Max subscriptions. No API key required. Optional `~/.shingle/env` for power users who want API access.
- **Read-only config mount:** `~/.shingle/` mounted read-only into container — config can't be modified from inside.
- **Named volume for .claude:** Session data survives container rebuild. But this means plugin/hook installation must happen at runtime (postAttachCommand), not at image build time.
- **ed3d plugins via direct file copy:** Bypass `claude plugin` CLI (which requires marketplace registration). Clone the marketplace repo at build time, copy files to `~/.claude/plugins/` at runtime.
- **Practice area selected once in Phase 1:** Saved to `~/.shingle/config`, read by `welcome.sh` — no interactive prompt in container.
- **Safety hooks without plugin system:** Hooks are merged into `settings.json` directly. No custom plugin installation needed.
- **Pre-installed tool stack:** Python packages, pandoc, chart.js, vite all installed at image build time. No PyPI access at runtime (firewall blocks it).
- **Natural language over slash commands:** CLAUDE.md instructs Claude on how to respond to requests like "review this contract" or "draft a memo". No custom slash commands — just good instructions.

## Future Work

- **Federal Register MCP server:** Source lives in `plugin/plugins/shingle/servers/federal-register/`. Not currently built or deployed. Would give Claude live access to Federal Register search for legal/policy practice areas.
- **Custom slash commands:** Claude Code plugin `commands/` directory format creates user-invocable slash commands. Could convert common workflows (review, draft, summarize) into commands for discoverability. Requires working plugin installation.
- **Additional MCP servers:** Each practice area could benefit from domain-specific data sources (PACER for legal, SAM.gov for govcon, etc.).
