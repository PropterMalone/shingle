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

# --- Plugin installation (via claude plugin CLI from baked-in repo) ---
CLAUDE_DIR="/home/node/.claude"
ED3D_SRC="/home/node/.ed3d-plugins"
ED3D_MP="ed3d-plugins"
ED3D_PLUGINS=("ed3d-plan-and-execute" "ed3d-house-style" "ed3d-basic-agents" "ed3d-research-agents")

# Check if marketplace is already registered (idempotent)
if [[ -d "$ED3D_SRC" ]] && ! claude plugin marketplace list 2>/dev/null | grep -q "$ED3D_MP"; then
  claude plugin marketplace add "$ED3D_SRC" 2>/dev/null \
    && echo "[shingle] Plugin marketplace registered." \
    || echo "[shingle] Warning: could not register plugin marketplace."
fi

# Install each plugin if not already installed (idempotent)
for name in "${ED3D_PLUGINS[@]}"; do
  if ! claude plugin list 2>/dev/null | grep -q "$name"; then
    claude plugin install "${name}@${ED3D_MP}" 2>/dev/null \
      && echo "[shingle] Installed $name." \
      || echo "[shingle] Warning: could not install $name."
  fi
done

# --- Safety hooks (always ensure they're present) ---
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
HOOKS_SRC="/home/node/.shingle-templates/hooks.json"

if [[ -f "$HOOKS_SRC" ]]; then
  # Check if hooks have already been injected (marker key in settings)
  HAS_HOOKS=""
  if [[ -f "$SETTINGS_FILE" ]]; then
    HAS_HOOKS=$(jq -r '."shingle-safety-hooks" // empty' "$SETTINGS_FILE" 2>/dev/null)
  fi

  if [[ -z "$HAS_HOOKS" ]]; then
    HOOKS_JSON=$(cat "$HOOKS_SRC")
    if [[ -f "$SETTINGS_FILE" ]]; then
      # Merge hooks into existing settings
      jq --argjson hooks "$HOOKS_JSON" '. + {hooks: $hooks.hooks, "shingle-safety-hooks": true}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" \
        && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    else
      # Create settings with hooks
      echo "$HOOKS_JSON" | jq '{hooks: .hooks, "shingle-safety-hooks": true}' > "$SETTINGS_FILE"
    fi
    echo "[shingle] Safety hooks installed."
  fi
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
  ║  Your files are in: /workspace/documents/                    ║
  ║                                                              ║
  ║  To start, type: claude                                      ║
  ║  Choose option 1 (Claude account) when asked.                ║
  ║  Copy the login URL into your browser to sign in.            ║
  ║                                                              ║
  ║  Try asking Claude to review a document, draft a memo,       ║
  ║  or build a tool for your practice.                          ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝

WELCOME
