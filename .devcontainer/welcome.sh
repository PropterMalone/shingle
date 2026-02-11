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

# --- Plugin installation (direct file copy — no CLI needed) ---
# Replicate what `claude plugin marketplace add` + `claude plugin install` do:
# 1. Copy marketplace to ~/.claude/plugins/marketplaces/{name}/
# 2. Copy plugin to ~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/
# 3. Register in settings.json enabledPlugins
MARKETPLACE_SRC="/home/node/.shingle-marketplace"
MARKETPLACE_NAME="shingle-marketplace"
PLUGIN_NAME="shingle"
PLUGIN_VERSION="0.2.0"
CLAUDE_DIR="/home/node/.claude"

if [[ -d "$MARKETPLACE_SRC" ]]; then
  # Marketplace registration
  MP_DST="$CLAUDE_DIR/plugins/marketplaces/$MARKETPLACE_NAME"
  mkdir -p "$MP_DST/.claude-plugin"
  cp "$MARKETPLACE_SRC/.claude-plugin/marketplace.json" "$MP_DST/.claude-plugin/"
  cp -r "$MARKETPLACE_SRC/plugins" "$MP_DST/"

  # Plugin cache
  CACHE_DST="$CLAUDE_DIR/plugins/cache/$MARKETPLACE_NAME/$PLUGIN_NAME/$PLUGIN_VERSION"
  mkdir -p "$CACHE_DST/.claude-plugin"
  cp -r "$MARKETPLACE_SRC/plugins/$PLUGIN_NAME/skills" "$CACHE_DST/"
  cp -r "$MARKETPLACE_SRC/plugins/$PLUGIN_NAME/hooks" "$CACHE_DST/"
  cp "$MARKETPLACE_SRC/plugins/$PLUGIN_NAME/.mcp.json" "$CACHE_DST/"
  cp "$MARKETPLACE_SRC/plugins/$PLUGIN_NAME/.claude-plugin/plugin.json" "$CACHE_DST/.claude-plugin/"

  # Register plugin in settings (merge if settings.json already exists)
  SETTINGS_FILE="$CLAUDE_DIR/settings.json"
  ENABLED_KEY="$PLUGIN_NAME@$MARKETPLACE_NAME"
  if [[ -f "$SETTINGS_FILE" ]]; then
    jq --arg key "$ENABLED_KEY" '.enabledPlugins[$key] = true' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" \
      && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  else
    printf '{"enabledPlugins":{"%s":true}}\n' "$ENABLED_KEY" > "$SETTINGS_FILE"
  fi

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
