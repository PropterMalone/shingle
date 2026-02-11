#!/usr/bin/env bash
# Shingle Bootstrap - Mac/Linux
# Installs Claude Code and launches the setup assistant.
set -euo pipefail

echo ""
echo "  Shingle Setup"
echo "  Preparing your workspace..."
echo ""

# --- Install Claude Code ---
if command -v claude &>/dev/null; then
    echo "  Claude Code is already installed."
else
    echo "  Installing Claude Code..."
    if command -v curl &>/dev/null; then
        curl -fsSL https://claude.ai/install.sh | sh
    else
        echo ""
        echo "  Could not install automatically (curl not available)."
        echo "  Please install Claude Code manually:"
        echo "  https://docs.anthropic.com/en/docs/claude-code/getting-started"
        echo ""
        exit 1
    fi

    # Add common install locations to PATH
    export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"

    if ! command -v claude &>/dev/null; then
        echo ""
        echo "  Installation completed but 'claude' command not found."
        echo "  Please close this terminal, open a new one, and run this script again."
        echo ""
        exit 1
    fi
    echo "  Claude Code installed."
fi

# --- Launch Claude in the project directory ---
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo ""
echo "  Starting Claude Code..."
echo "  Claude will walk you through the rest of the setup."
echo ""

claude
