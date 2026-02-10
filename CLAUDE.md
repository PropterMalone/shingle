# Shingle — Development Guide

**Purpose:** Claude Code starter kit for non-technical ex-federal consultants starting solo practices.

Last verified: 2026-02-10

## What This Is

Three-part toolkit:
1. **Devcontainer** — isolated environment with Claude Code pre-installed, network-firewalled, client documents mounted from host
2. **Claude Code plugin** — practice-area skills (`/review`, `/summarize`, `/draft`) and CLAUDE.md templates that make Claude talk to consultants, not developers
3. **MCP servers** — tool servers that give Claude live data access (e.g., Federal Register search)

## Tech Stack

- **Container:** Docker (devcontainer spec)
- **Base image:** node:20-bookworm
- **Plugin format:** Claude Code plugin spec (plugin.json + SKILL.md files)
- **MCP servers:** TypeScript, `@modelcontextprotocol/sdk`, compiled at container build time
- **Templates:** Markdown (CLAUDE.md files per practice area)
- **Docs:** Markdown, written for non-technical audience

## Directory Structure

```
.devcontainer/      # VS Code devcontainer (Dockerfile, scripts)
plugin/             # Claude Code plugin (skills, hooks, MCP servers)
  skills/           #   Slash-command skills (SKILL.md files)
  servers/          #   MCP tool servers (TypeScript, built at container build)
  .mcp.json         #   MCP server manifest (server name -> command)
templates/          # CLAUDE.md templates per practice area
docs/               # User-facing documentation
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

The audience already knows AI can write. What's new is AI that acts on their machine.

## Conventions

- **Audience:** All user-facing text assumes zero terminal experience. No jargon.
- **Skills:** Each skill is a SKILL.md in `plugin/skills/{name}/`
- **MCP servers:** Each server is a TypeScript project in `plugin/servers/{name}/`, registered in `plugin/.mcp.json`
- **Templates:** `CLAUDE.md.base` is the shared foundation; practice-area files overlay it
- **Safety first:** Firewall blocks all outbound except Anthropic API, npm, and allowlisted data sources (e.g., `www.federalregister.gov`). Hooks confirm destructive ops.
- **File paths:** All document work happens in `/workspace/documents/` inside the container

## Commands

```bash
docker build -t shingle .devcontainer/     # Build container image
# Open in VS Code → "Reopen in Container"   # Run devcontainer
```

## Key Design Decisions

- **No auth / no accounts:** API key is the only credential, stored on host
- **Named volume for .claude:** Session data survives container rebuild
- **Read-only env mount:** API key can't be overwritten from inside container
- **Plugin copied at startup:** Not bind-mounted — survives if host path moves
- **Practice-area selection at first run:** welcome.sh handles it interactively
- **MCP servers built in Dockerfile:** `npm install && tsc && npm prune --production` at image build time, not runtime
- **Firewall allowlist per server:** Each MCP server's external host must be added to `init-firewall.sh`
