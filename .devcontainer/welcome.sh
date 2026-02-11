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

# --- Plugin installation (direct file copy from baked-in repos) ---
CLAUDE_DIR="/home/node/.claude"
ED3D_SRC="/home/node/.ed3d-plugins"
ED3D_MP="ed3d-plugins"
ED3D_PLUGINS=("ed3d-plan-and-execute:1.5.0" "ed3d-house-style:1.0.0" "ed3d-basic-agents:1.0.0" "ed3d-research-agents:1.0.0")

if [[ -d "$ED3D_SRC" ]] && [[ ! -d "$CLAUDE_DIR/plugins/marketplaces/$ED3D_MP" ]]; then
  # Copy marketplace
  mkdir -p "$CLAUDE_DIR/plugins/marketplaces"
  cp -r "$ED3D_SRC" "$CLAUDE_DIR/plugins/marketplaces/$ED3D_MP"

  # Copy each plugin to cache and register in settings
  ENABLED="{}"
  for entry in "${ED3D_PLUGINS[@]}"; do
    name="${entry%%:*}"
    version="${entry##*:}"
    cache_dst="$CLAUDE_DIR/plugins/cache/$ED3D_MP/$name/$version"
    mkdir -p "$cache_dst"
    cp -r "$ED3D_SRC/plugins/$name/." "$cache_dst/"
    ENABLED=$(echo "$ENABLED" | jq --arg k "$name@$ED3D_MP" '.[$k] = true')
  done

  # Write or merge settings.json
  SETTINGS_FILE="$CLAUDE_DIR/settings.json"
  if [[ -f "$SETTINGS_FILE" ]]; then
    jq --argjson ep "$ENABLED" '.enabledPlugins = (.enabledPlugins // {} | . + $ep)' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" \
      && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
  else
    echo "$ENABLED" | jq '{enabledPlugins: .}' > "$SETTINGS_FILE"
  fi

  echo "[shingle] Development plugins installed."
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
