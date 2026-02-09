# Shingle — Development Guide

**Purpose:** Claude Code starter kit for non-technical ex-federal consultants starting solo practices.

Last verified: 2026-02-09

## What This Is

Two-part toolkit:
1. **Devcontainer** — isolated environment with Claude Code pre-installed, network-firewalled, client documents mounted from host
2. **Claude Code plugin** — practice-area skills (`/review`, `/summarize`, `/draft`) and CLAUDE.md templates that make Claude talk to consultants, not developers

## Tech Stack

- **Container:** Docker (devcontainer spec)
- **Base image:** node:20-bookworm
- **Plugin format:** Claude Code plugin spec (plugin.json + SKILL.md files)
- **Templates:** Markdown (CLAUDE.md files per practice area)
- **Docs:** Markdown, written for non-technical audience

## Directory Structure

```
.devcontainer/      # VS Code devcontainer (Dockerfile, scripts)
plugin/             # Claude Code plugin (skills, hooks)
templates/          # CLAUDE.md templates per practice area
docs/               # User-facing documentation
```

## Conventions

- **Audience:** All user-facing text assumes zero terminal experience. No jargon.
- **Skills:** Each skill is a SKILL.md in `plugin/skills/{name}/`
- **Templates:** `CLAUDE.md.base` is the shared foundation; practice-area files overlay it
- **Safety first:** Firewall blocks all outbound except Anthropic API + npm. Hooks confirm destructive ops.
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
