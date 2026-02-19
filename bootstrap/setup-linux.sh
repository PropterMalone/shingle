#!/usr/bin/env bash
# Shingle Bootstrap - Linux
# One-command setup: installs everything, opens VS Code at the project.
# Usage: curl ... | bash -s -- [practice-area]
set -euo pipefail

SHINGLE_REPO="https://github.com/PropterMalone/shingle.git"
SHINGLE_DIR="$HOME/Documents/shingle"
PRACTICE_AREA="${1:-}"

echo ""
echo "  Shingle Setup (Linux)"
echo "  Preparing your workspace..."
echo ""

# --- Detect package manager ---
if command -v apt-get &>/dev/null; then
    PKG_MGR="apt"
elif command -v dnf &>/dev/null; then
    PKG_MGR="dnf"
elif command -v pacman &>/dev/null; then
    PKG_MGR="pacman"
else
    echo "  Could not detect a supported package manager (apt, dnf, or pacman)."
    echo "  Please install Git, Docker, and VS Code manually, then run this script again."
    exit 1
fi
echo "  Detected package manager: $PKG_MGR"

# --- Helper: install a package ---
pkg_install() {
    case "$PKG_MGR" in
        apt)    sudo apt-get update -qq && sudo apt-get install -y -qq "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        pacman) sudo pacman -S --noconfirm "$@" ;;
    esac
}

# --- Install Git ---
if command -v git &>/dev/null; then
    echo "  Git is already installed."
else
    echo "  Installing Git..."
    pkg_install git
    if ! command -v git &>/dev/null; then
        echo ""
        echo "  Could not install Git automatically."
        echo "  Please install Git from https://git-scm.com/downloads and run this script again."
        exit 1
    fi
    echo "  Git installed."
fi

# --- Clone or update the Shingle repo ---
if [[ -d "$SHINGLE_DIR/.git" ]]; then
    echo "  Shingle folder found. Checking for updates..."
    git -C "$SHINGLE_DIR" pull --ff-only 2>/dev/null || true
    echo "  Shingle is up to date."
elif [[ -d "$SHINGLE_DIR" ]]; then
    echo "  Shingle folder exists but is not a Git repo."
    echo "  To get automatic updates, delete $SHINGLE_DIR and run this script again."
else
    echo "  Downloading Shingle... (this may take a moment)"
    mkdir -p "$HOME/Documents"
    git clone --progress "$SHINGLE_REPO" "$SHINGLE_DIR"
    if [[ ! -d "$SHINGLE_DIR" ]]; then
        echo ""
        echo "  Failed to download Shingle."
        echo "  Check your internet connection and try again."
        exit 1
    fi
    echo "  Shingle downloaded."
fi

# --- Install Docker Engine ---
if command -v docker &>/dev/null; then
    echo "  Docker is already installed."
else
    echo "  Installing Docker Engine... (this may take a few minutes)"
    if [[ "$PKG_MGR" == "pacman" ]]; then
        pkg_install docker
        sudo systemctl enable --now docker.service
    else
        # Docker's convenience script handles Debian/Ubuntu/Fedora/RHEL
        curl -fsSL https://get.docker.com | sudo sh
    fi

    if ! command -v docker &>/dev/null; then
        echo ""
        echo "  Could not install Docker automatically."
        echo "  Please install from https://docs.docker.com/engine/install/ and run this script again."
        exit 1
    fi
    echo "  Docker installed."
fi

# --- Add user to docker group (avoids needing sudo for docker) ---
if ! groups "$USER" 2>/dev/null | grep -qw docker; then
    echo "  Adding you to the docker group..."
    sudo usermod -aG docker "$USER"
    echo ""
    echo "  !! NOTE !!"
    echo "  -------------------------------------------------------"
    echo "  You were added to the 'docker' group."
    echo "  You need to log out and log back in for this to work."
    echo "  After logging back in, run the setup command again."
    echo "  -------------------------------------------------------"
    echo ""
    exit 0
fi

# --- Start Docker if not running ---
if ! docker info &>/dev/null 2>&1; then
    echo "  Starting Docker..."
    sudo systemctl start docker
    sleep 2
    if ! docker info &>/dev/null 2>&1; then
        echo ""
        echo "  Docker is installed but won't start."
        echo "  Try: sudo systemctl start docker"
        echo "  Then run this script again."
        exit 1
    fi
fi
echo "  Docker is running."

# --- Install VS Code ---
if command -v code &>/dev/null; then
    echo "  VS Code is already installed."
else
    echo "  Installing VS Code..."
    case "$PKG_MGR" in
        apt)
            # Install via Microsoft's apt repo
            sudo apt-get install -y -qq wget gpg apt-transport-https
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/packages.microsoft.gpg >/dev/null
            echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
            sudo apt-get update -qq
            sudo apt-get install -y -qq code
            ;;
        dnf)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
            sudo dnf install -y code
            ;;
        pacman)
            # Try snap first, fall back to manual instructions
            if command -v snap &>/dev/null; then
                sudo snap install code --classic
            else
                echo ""
                echo "  Could not install VS Code automatically on Arch."
                echo "  Install it from the AUR (e.g., yay -S visual-studio-code-bin)"
                echo "  or from https://code.visualstudio.com/"
                echo "  Then run this script again."
                exit 1
            fi
            ;;
    esac

    if ! command -v code &>/dev/null; then
        echo ""
        echo "  VS Code installed but 'code' command not found."
        echo "  Please close this terminal, open a new one, and run the setup command again."
        exit 1
    fi
    echo "  VS Code installed."
fi

# --- Install Dev Containers extension ---
echo "  Checking Dev Containers extension..."
code --install-extension ms-vscode-remote.remote-containers 2>/dev/null || true

# --- Install Claude Code ---
if command -v claude &>/dev/null; then
    echo "  Claude Code is already installed."
else
    echo "  Installing Claude Code... (this may take a minute)"
    curl -fsSL https://claude.ai/install.sh | sh

    export PATH="$HOME/.local/bin:$HOME/.claude/bin:/usr/local/bin:$PATH"

    if ! command -v claude &>/dev/null; then
        echo ""
        echo "  Installation completed but 'claude' command not found."
        echo "  Please close this terminal, open a new one, and run the setup command again."
        exit 1
    fi
    echo "  Claude Code installed."
fi

# --- Practice area ---
if [[ -n "$PRACTICE_AREA" ]]; then
    mkdir -p ~/.shingle
    echo "$PRACTICE_AREA" > ~/.shingle/config
    echo "  Practice area set to: $PRACTICE_AREA"
fi

# --- Create ClientWork folder ---
mkdir -p ~/Documents/ClientWork

# --- Open VS Code at the project ---
echo ""
echo "  ======================================================="
echo "  Setup complete! VS Code is opening now."
echo ""
echo "  1. Click 'Reopen in Container' when VS Code prompts you"
echo "  2. Wait about 2 minutes for the container to build"
echo "  3. Type 'claude' in the terminal that appears"
echo "  ======================================================="
echo ""
code "$SHINGLE_DIR"
