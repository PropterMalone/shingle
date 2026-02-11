# Shingle devcontainer — Claude Code environment for consultants
FROM node:20-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    nano \
    less \
    jq \
    fzf \
    zsh \
    poppler-utils \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    sudo \
    python3 \
    python3-pip \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Install Python data analysis packages
RUN pip3 install --break-system-packages --no-cache-dir pandas matplotlib openpyxl xlsxwriter

# Install vite globally for rare multi-page app cases
RUN npm install -g vite

# Pre-install chart.js in a shared location for Claude to copy into static HTML
RUN npm install --prefix /home/node/.shingle-lib chart.js --silent

# Configure sudo for node user (passwordless for firewall commands only)
RUN echo 'node ALL=(ALL) NOPASSWD: /usr/sbin/iptables, /usr/sbin/ipset, /usr/sbin/ip, /usr/local/bin/init-firewall.sh, /usr/bin/bash /usr/local/bin/init-firewall.sh, /usr/bin/chown' > /etc/sudoers.d/shingle-firewall \
    && chmod 0440 /etc/sudoers.d/shingle-firewall

# Set zsh as default shell for node user
RUN chsh -s /usr/bin/zsh node

# Copy initialization scripts (context is repo root, Dockerfile is in .devcontainer/)
COPY .devcontainer/init-firewall.sh /usr/local/bin/init-firewall.sh
COPY .devcontainer/welcome.sh /usr/local/bin/welcome.sh
RUN chmod +x /usr/local/bin/init-firewall.sh /usr/local/bin/welcome.sh

# Copy templates into the image
COPY templates /home/node/.shingle-templates

RUN chown -R node:node /home/node/.shingle-templates /home/node/.shingle-lib

# Switch to node user
USER node
WORKDIR /workspace/documents

# Set up basic zsh configuration
RUN echo 'export PATH="/usr/local/bin:$PATH"' > /home/node/.zshrc \
    && echo '[ -f /home/node/.shingle/env ] && set -a && source /home/node/.shingle/env && set +a' >> /home/node/.zshrc \
    && echo 'autoload -Uz compinit && compinit' >> /home/node/.zshrc
