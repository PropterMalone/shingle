# Federal Register MCP Server Implementation Plan

**Goal:** Build a Federal Register MCP server that gives Claude Code the ability to search and retrieve federal regulations, rules, notices, and executive orders for consultants.

**Architecture:** TypeScript MCP server using stdio transport, backed by the free Federal Register API. Four tools: search documents, get document detail, search executive orders, list agencies. Server compiles during Docker image build — zero setup for the end user.

**Tech Stack:** TypeScript, @modelcontextprotocol/sdk v1.x, zod v3.x, Node.js native fetch

**Scope:** 4 phases from original design (all phases)

**Codebase verified:** 2026-02-10

---

## Phase 3: CLI Template Updates

Update `npx shingle init` to scaffold the MCP server files, updated Dockerfile, and updated firewall script so new projects get the Federal Register integration out of the box.

**Done when:** `npm run build` succeeds and the CLI output includes all new files.

---

<!-- START_TASK_1 -->
### Task 1: Update init-firewall.sh template in templates.ts

**Files:**
- Modify: `src/cli/templates.ts:329`

**Step 1: Update the firewall template**

In `src/cli/templates.ts`, find the firewall host line inside the `".devcontainer/init-firewall.sh"` template (around line 329):

```
for host in api.anthropic.com registry.npmjs.org statsig.anthropic.com; do
```

Replace with:

```
for host in api.anthropic.com registry.npmjs.org statsig.anthropic.com www.federalregister.gov; do
```

**Step 2: Update the firewall success message**

In the same template, find (around line 338):

```
echo "[firewall] Network locked down — only Anthropic API, npm, and DNS allowed"
```

Replace with:

```
echo "[firewall] Network locked down — only Anthropic API, npm, Federal Register, and DNS allowed"
```

**Step 3: Commit**

```bash
git add src/cli/templates.ts
git commit -m "feat: update firewall template with federal register host"
```

<!-- END_TASK_1 -->

<!-- START_TASK_2 -->
### Task 2: Update Dockerfile template in templates.ts

**Files:**
- Modify: `src/cli/templates.ts:121-124`

**Step 1: Add the MCP server build step to the Dockerfile template**

In `src/cli/templates.ts`, find the Dockerfile template section (around lines 121-124):

```
# Copy plugin and templates into the image
COPY plugin /home/node/.shingle-plugin
COPY templates /home/node/.shingle-templates
RUN chown -R node:node /home/node/.shingle-plugin /home/node/.shingle-templates
```

Replace with:

```
# Copy plugin and templates into the image
COPY plugin /home/node/.shingle-plugin
COPY templates /home/node/.shingle-templates

# Build Federal Register MCP server (install deps, compile, prune dev deps)
RUN cd /home/node/.shingle-plugin/servers/federal-register \\
    && npm install \\
    && npx tsc \\
    && npm prune --production

RUN chown -R node:node /home/node/.shingle-plugin /home/node/.shingle-templates
```

**Step 2: Commit**

```bash
git add src/cli/templates.ts
git commit -m "feat: update Dockerfile template with MCP server build step"
```

<!-- END_TASK_2 -->

<!-- START_TASK_3 -->
### Task 3: Add MCP server file templates

**Files:**
- Modify: `src/cli/templates.ts` (add new entries before closing `};` at line 1978)

**Step 1: Add all new template entries**

In `src/cli/templates.ts`, before the closing `};` of the `TEMPLATES` object (line 1978), add the following new entries. Note: the backtick-delimited strings contain the full file contents. Escape any backticks or `${...}` expressions that appear in the content.

Add these entries:

```typescript
  "plugin/.mcp.json": `{
  "federal-register": {
    "command": "node",
    "args": ["\${CLAUDE_PLUGIN_ROOT}/servers/federal-register/dist/index.js"]
  }
}
`,

  "plugin/servers/federal-register/.gitignore": `node_modules/
dist/
`,

  "plugin/servers/federal-register/package.json": `{
  "name": "shingle-federal-register",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.26.0",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.4.0"
  }
}
`,

  "plugin/servers/federal-register/tsconfig.json": `{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": false
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
`,
```

**IMPORTANT:** The next four entries contain TypeScript source code as template literal strings. The source code contains import paths with `.js` extensions (required for ESM). It also contains template literals within the source — these must be escaped as `\`\`` inside the outer template literal, and `${...}` expressions in the source must be escaped as `\${...}`.

The four TypeScript source file templates (`api.ts`, `format.ts`, `tools.ts`, `index.ts`) should contain the exact same code as written in Phase 1, Tasks 2-5. Copy the complete file contents from those tasks.

For each TypeScript source file, create a template entry:

For each TypeScript source file, read the file from disk (as created in Phase 1) and embed it as a template entry:

```typescript
  "plugin/servers/federal-register/src/api.ts": `...`,
  "plugin/servers/federal-register/src/format.ts": `...`,
  "plugin/servers/federal-register/src/tools.ts": `...`,
  "plugin/servers/federal-register/src/index.ts": `...`,
```

**How to create each template entry:**
1. Read the source file from `plugin/servers/federal-register/src/<name>.ts`
2. Scan the content for backticks (`` ` ``) and `${` expressions — if found, escape them
3. Wrap the content in backticks as a template literal value in the TEMPLATES object

**Escaping rules for template strings in templates.ts:**
- Replace every `` ` `` in the source with `` \` ``
- Replace every `${` in the source with `\${`
- The TypeScript source files from Phase 1 do NOT contain backticks or `${}` template expressions — they use only regular strings, so no escaping should be needed
- The `.mcp.json` template DOES contain `${CLAUDE_PLUGIN_ROOT}` which MUST be escaped as `\${CLAUDE_PLUGIN_ROOT}`
- **Verify after writing:** Run `npm run build` — the TypeScript compiler will catch any unescaped template expressions as syntax errors

**Step 2: Commit**

```bash
git add src/cli/templates.ts
git commit -m "feat: add federal register MCP server templates to CLI"
```

<!-- END_TASK_3 -->

<!-- START_TASK_4 -->
### Task 4: Rebuild CLI and verify

**Step 1: Build the CLI**

```bash
npm run build
```

Expected: tsup builds successfully, output at `dist/index.js`.

**Step 2: Verify the CLI output includes new files**

Run a dry-run or inspect the built output to verify all new template keys are included:

```bash
node -e "const t = require('./dist/index.js'); /* templates accessible */"
```

Or simply verify the build succeeded — the TypeScript compiler will catch any syntax errors in the template strings.

**Step 3: Commit build output if needed**

If `dist/index.js` is tracked (check `package.json` `"files"` field — it is):

```bash
git add dist/index.js
git commit -m "chore: rebuild CLI with federal register templates"
```

<!-- END_TASK_4 -->
