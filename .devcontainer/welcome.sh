#!/usr/bin/env bash
# Shingle welcome script — runs on every container attach
set -euo pipefail

# --- Source API key ---
# The ~/.shingle/ directory is bind-mounted from the host (read-only)
# Contains env (API key) and config (practice area selection)
SHINGLE_DIR="/home/node/.shingle"
if [[ -f "$SHINGLE_DIR/env" ]]; then
  set -a
  source "$SHINGLE_DIR/env"
  set +a
  export ANTHROPIC_API_KEY
fi

# --- Check API key ---
if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  cat <<'SETUP'

  ╔══════════════════════════════════════════════════════════════╗
  ║                    API Key Not Found                        ║
  ╠══════════════════════════════════════════════════════════════╣
  ║                                                              ║
  ║  To use Claude, you need an Anthropic API key.               ║
  ║                                                              ║
  ║  1. Go to https://console.anthropic.com/                     ║
  ║  2. Sign up or log in                                        ║
  ║  3. Go to API Keys and create a new key                      ║
  ║  4. On your computer, create this file:                      ║
  ║                                                              ║
  ║     Windows: %USERPROFILE%\.shingle\env                      ║
  ║     Mac:     ~/.shingle/env                                  ║
  ║                                                              ║
  ║  5. Put this line in the file:                               ║
  ║                                                              ║
  ║     ANTHROPIC_API_KEY=sk-ant-your-key-here                   ║
  ║                                                              ║
  ║  6. Rebuild the container (Ctrl+Shift+P → "Rebuild")         ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝

SETUP
  exit 0
fi

# --- Plugin installation ---
PLUGIN_SRC="/home/node/.shingle-plugin"
PLUGIN_DST="/home/node/.claude/plugins/local/shingle"

if [[ -d "$PLUGIN_SRC" ]]; then
  mkdir -p "$(dirname "$PLUGIN_DST")"
  rm -rf "$PLUGIN_DST"
  cp -r "$PLUGIN_SRC" "$PLUGIN_DST"
  echo "[shingle] Plugin installed."
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
  ║  Useful commands once Claude is running:                     ║
  ║    /review     — Analyze a document                          ║
  ║    /summarize  — Create an executive summary                 ║
  ║    /draft      — Write a report, memo, or letter             ║
  ║    /help-me    — Get diagnostic info for support             ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝

WELCOME
