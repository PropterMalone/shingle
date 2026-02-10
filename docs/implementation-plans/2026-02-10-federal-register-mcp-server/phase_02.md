# Federal Register MCP Server Implementation Plan

**Goal:** Build a Federal Register MCP server that gives Claude Code the ability to search and retrieve federal regulations, rules, notices, and executive orders for consultants.

**Architecture:** TypeScript MCP server using stdio transport, backed by the free Federal Register API. Four tools: search documents, get document detail, search executive orders, list agencies. Server compiles during Docker image build — zero setup for the end user.

**Tech Stack:** TypeScript, @modelcontextprotocol/sdk v1.x, zod v3.x, Node.js native fetch

**Scope:** 4 phases from original design (all phases)

**Codebase verified:** 2026-02-10

---

## Phase 2: Devcontainer Integration

Wire the MCP server into the Docker build and firewall so it works out of the box inside the devcontainer.

**Done when:** Docker image builds successfully with the MCP server compiled and `www.federalregister.gov` in the firewall allowlist.

---

<!-- START_TASK_1 -->
### Task 1: Add www.federalregister.gov to firewall allowlist

**Files:**
- Modify: `.devcontainer/init-firewall.sh:25`

**Step 1: Update the allowed hosts list**

In `.devcontainer/init-firewall.sh`, find line 25:

```bash
for host in api.anthropic.com registry.npmjs.org statsig.anthropic.com; do
```

Replace with:

```bash
for host in api.anthropic.com registry.npmjs.org statsig.anthropic.com www.federalregister.gov; do
```

**Step 2: Update the success message**

Find line 34:

```bash
echo "[firewall] Network locked down — only Anthropic API, npm, and DNS allowed"
```

Replace with:

```bash
echo "[firewall] Network locked down — only Anthropic API, npm, Federal Register, and DNS allowed"
```

**Step 3: Commit**

```bash
git add .devcontainer/init-firewall.sh
git commit -m "feat: add federal register to firewall allowlist"
```

<!-- END_TASK_1 -->

<!-- START_TASK_2 -->
### Task 2: Add MCP server build step to Dockerfile

**Files:**
- Modify: `.devcontainer/Dockerfile:36-38`

**Step 1: Add the build step**

In `.devcontainer/Dockerfile`, find lines 35-38:

```dockerfile
# Copy plugin and templates into the image
COPY plugin /home/node/.shingle-plugin
COPY templates /home/node/.shingle-templates
RUN chown -R node:node /home/node/.shingle-plugin /home/node/.shingle-templates
```

Replace with:

```dockerfile
# Copy plugin and templates into the image
COPY plugin /home/node/.shingle-plugin
COPY templates /home/node/.shingle-templates

# Build Federal Register MCP server (install deps, compile, prune dev deps)
RUN cd /home/node/.shingle-plugin/servers/federal-register \
    && npm install \
    && npx tsc \
    && npm prune --production

RUN chown -R node:node /home/node/.shingle-plugin /home/node/.shingle-templates
```

How this works:
1. `COPY plugin` copies the entire plugin directory (including server source files) into the image
2. `npm install` installs all dependencies including typescript (needed for build)
3. `npx tsc` compiles TypeScript source to `dist/` (the MCP manifest points to `dist/index.js`)
4. `npm prune --production` removes devDependencies (typescript, @types/node) — only runtime deps remain
5. `chown` gives the `node` user ownership of everything (including the new node_modules and dist)

Note: The `welcome.sh` script already uses `cp -r` to copy the entire plugin directory into Claude Code's plugin location. No changes to `welcome.sh` are needed — the MCP server files (including `.mcp.json`, compiled JS, and `node_modules`) are automatically included.

**Step 2: Verify (optional, requires Docker)**

If Docker is available, verify the image builds:

```bash
docker build -t shingle-test -f .devcontainer/Dockerfile .
```

Expected: Image builds successfully with no errors from the npm install or tsc steps.

**Step 3: Commit**

```bash
git add .devcontainer/Dockerfile
git commit -m "feat: build federal register MCP server in Docker image"
```

<!-- END_TASK_2 -->
