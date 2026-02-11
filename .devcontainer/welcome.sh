#!/usr/bin/env bash
# Shingle welcome script — runs on every container attach
set -euo pipefail

# The ~/.shingle/ directory is bind-mounted from the host (read-only)
# Contains config (practice area selection) and optionally env (API key)
SHINGLE_DIR="/home/node/.shingle"

# --- Source API key (if present) ---
# Optional: clients using Claude Pro/Max authenticate via OAuth instead
if [[ -f "$SHINGLE_DIR/env" ]]; then
  set -a
  source "$SHINGLE_DIR/env"
  set +a
  export ANTHROPIC_API_KEY
fi

# --- First-run: CLAUDE.md assembly ---
WORKSPACE_CLAUDE="/workspace/documents/CLAUDE.md"
CONFIG_FILE="$SHINGLE_DIR/config"
TEMPLATES_DIR="/home/node/.shingle-templates"

if [[ ! -f "$WORKSPACE_CLAUDE" ]] && [[ -d "$TEMPLATES_DIR" ]]; then
  # Read practice area from config (written during Phase 1 host setup)
  if [[ -f "$CONFIG_FILE" ]]; then
    PRACTICE_AREA=$(cat "$CONFIG_FILE")
  else
    # "general" intentionally has no overlay — base template is sufficient
    PRACTICE_AREA="general"
    echo "[shingle] No practice area configured. Using general."
  fi

  # Assemble CLAUDE.md: base + overlay
  if [[ -f "$TEMPLATES_DIR/CLAUDE.md.base" ]]; then
    cp "$TEMPLATES_DIR/CLAUDE.md.base" "$WORKSPACE_CLAUDE"

    OVERLAY="$TEMPLATES_DIR/CLAUDE.md.$PRACTICE_AREA"
    if [[ -f "$OVERLAY" ]] && [[ "$PRACTICE_AREA" != "general" ]]; then
      echo "" >> "$WORKSPACE_CLAUDE"
      cat "$OVERLAY" >> "$WORKSPACE_CLAUDE"
    fi

    echo "[shingle] CLAUDE.md created for $PRACTICE_AREA practice."
  fi
fi

# --- Welcome message ---
cat <<'WELCOME'

  ╔══════════════════════════════════════════════════════════════╗
  ║                    Welcome to Shingle                        ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  Your documents are in: /workspace/documents/                ║
  ║                                                              ║
  ║  To start, type: claude                                      ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝

WELCOME
