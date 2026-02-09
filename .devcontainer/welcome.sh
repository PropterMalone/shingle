#!/usr/bin/env bash
# Shingle welcome script — runs on every container attach
set -euo pipefail

# --- Source API key ---
# The env file is bind-mounted from the host (~/.shingle/env)
# If the host file doesn't exist, Docker may mount it as an empty directory — handle both cases
if [[ -f /home/node/.env.shingle ]]; then
  set -a
  source /home/node/.env.shingle
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

if [[ -d "$PLUGIN_SRC" ]] && [[ ! -d "$PLUGIN_DST" ]]; then
  mkdir -p "$(dirname "$PLUGIN_DST")"
  cp -r "$PLUGIN_SRC" "$PLUGIN_DST"
  echo "[shingle] Plugin installed."
fi

# --- First-run: practice area selection and CLAUDE.md ---
WORKSPACE_CLAUDE="/workspace/documents/CLAUDE.md"
CONFIG_FILE="/home/node/.shingle-config"
TEMPLATES_DIR="/home/node/.shingle-templates"

if [[ ! -f "$WORKSPACE_CLAUDE" ]] && [[ -d "$TEMPLATES_DIR" ]]; then
  # Check if practice area already configured
  if [[ -f "$CONFIG_FILE" ]]; then
    PRACTICE_AREA=$(cat "$CONFIG_FILE")
  else
    echo ""
    echo "  Welcome to Shingle! Let's set up your practice area."
    echo ""
    echo "  What kind of consulting do you do?"
    echo ""
    echo "    1) Legal (attorney, regulatory counsel)"
    echo "    2) Audit (auditor, investigator, IG)"
    echo "    3) Policy (policy analyst, legislative affairs)"
    echo "    4) GovCon (procurement, contracts, proposals)"
    echo "    5) General (skip practice-specific setup)"
    echo ""
    read -rp "  Enter 1-5: " choice

    case "$choice" in
      1) PRACTICE_AREA="legal" ;;
      2) PRACTICE_AREA="audit" ;;
      3) PRACTICE_AREA="policy" ;;
      4) PRACTICE_AREA="govcon" ;;
      *) PRACTICE_AREA="base" ;;
    esac

    echo "$PRACTICE_AREA" > "$CONFIG_FILE"
  fi

  # Assemble CLAUDE.md: base + overlay
  if [[ -f "$TEMPLATES_DIR/CLAUDE.md.base" ]]; then
    cp "$TEMPLATES_DIR/CLAUDE.md.base" "$WORKSPACE_CLAUDE"

    OVERLAY="$TEMPLATES_DIR/CLAUDE.md.$PRACTICE_AREA"
    if [[ -f "$OVERLAY" ]] && [[ "$PRACTICE_AREA" != "base" ]]; then
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
