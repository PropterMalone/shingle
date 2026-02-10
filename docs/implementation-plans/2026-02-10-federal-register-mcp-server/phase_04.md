# Federal Register MCP Server Implementation Plan

**Goal:** Build a Federal Register MCP server that gives Claude Code the ability to search and retrieve federal regulations, rules, notices, and executive orders for consultants.

**Architecture:** TypeScript MCP server using stdio transport, backed by the free Federal Register API. Four tools: search documents, get document detail, search executive orders, list agencies. Server compiles during Docker image build — zero setup for the end user.

**Tech Stack:** TypeScript, @modelcontextprotocol/sdk v1.x, zod v3.x, Node.js native fetch

**Scope:** 4 phases from original design (all phases)

**Codebase verified:** 2026-02-10

---

## Phase 4: Testing and Polish

Verify the full integration works end-to-end in the devcontainer. This phase is manual verification — build the container, open Claude Code, and test each tool with realistic consultant queries.

**Done when:** All four tools return well-formatted results for realistic queries inside the devcontainer.

---

<!-- START_TASK_1 -->
### Task 1: Build and start the devcontainer

**Step 1: Build the Docker image**

From the repo root:

```bash
docker build -t shingle-test -f .devcontainer/Dockerfile .
```

Expected: Image builds successfully. Key lines to verify in build output:
- `npm install` in the federal-register server directory succeeds
- `npx tsc` compiles without errors

**Step 2: Start the devcontainer**

Open the project in VS Code and use "Reopen in Container" (or use the Docker CLI). Verify:
- Container starts without errors
- `welcome.sh` runs and installs the plugin (look for `[shingle] Plugin installed.`)
- Firewall initializes (look for `[firewall] Network locked down — only Anthropic API, npm, Federal Register, and DNS allowed`)

**Step 3: Verify MCP server files are in place**

Inside the container:

```bash
ls /home/node/.claude/plugins/local/shingle/.mcp.json
ls /home/node/.claude/plugins/local/shingle/servers/federal-register/dist/index.js
```

Both files should exist.

<!-- END_TASK_1 -->

<!-- START_TASK_2 -->
### Task 2: Test each tool with realistic queries

Open Claude Code inside the devcontainer and test each tool with natural language. Claude should automatically discover and use the MCP tools.

**Test: search_federal_register**

Ask: "What new cybersecurity rules has the federal government published in the last 6 months?"

Expected: Claude calls `search_federal_register` with appropriate query and date range. Results show titles, agencies, dates, and links.

**Test: get_federal_register_document**

From the search results above, pick a document number and ask: "Tell me more about document [number]"

Expected: Claude calls `get_federal_register_document` with the document number. Returns full detail including abstract, effective date, docket IDs, and links.

**Test: search_executive_orders**

Ask: "What executive orders has the current president signed about artificial intelligence?"

Expected: Claude calls `search_executive_orders` with appropriate query. Results show EO numbers, signing dates, and links.

**Test: list_agencies**

Ask: "Which federal agencies can I search for in the Federal Register?"

Expected: Claude calls `list_agencies`. Returns a formatted list of agency names with slugs.

**Test: Filtered search using agency slug**

Ask: "Show me recent proposed rules from the EPA"

Expected: Claude first calls `list_agencies` (or uses a known slug), then calls `search_federal_register` with `agency: "environmental-protection-agency"` and `document_type: "proposed_rule"`.

<!-- END_TASK_2 -->

<!-- START_TASK_3 -->
### Task 3: Verify error handling

Test error cases to ensure Claude gets helpful error messages.

**Test: Invalid document number**

Ask: "Get me the details on Federal Register document 0000-00000"

Expected: Returns a clear error message like "failed to retrieve document 0000-00000: federal register API returned 404 Not Found"

**Test: Empty search results**

Ask: "Search for 'xyzzy12345' in the Federal Register"

Expected: Returns "No documents found matching that search. Try broadening your date range or using different keywords."

**Test: Network connectivity**

Verify the firewall allows Federal Register API access:

```bash
curl -s -o /dev/null -w "%{http_code}" https://www.federalregister.gov/api/v1/agencies
```

Expected: Returns `200`. If it returns nothing or an error, the firewall is blocking access — check that `www.federalregister.gov` was added to `init-firewall.sh`.

<!-- END_TASK_3 -->

<!-- START_TASK_4 -->
### Task 4: Final commit

After all verification passes, check for any uncommitted changes:

```bash
git status
```

If there are uncommitted changes from earlier phases, review them carefully, then stage only the relevant files:

```bash
git add <specific-files>
git commit -m "feat: federal register MCP server — complete integration"
```

If all earlier phases committed properly, there should be nothing to commit here.

<!-- END_TASK_4 -->
