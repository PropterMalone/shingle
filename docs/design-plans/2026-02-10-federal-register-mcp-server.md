# Federal Register MCP Server Design

## Summary

Add a Federal Register MCP server to the Shingle plugin, giving Claude Code the ability to search and retrieve federal regulations, proposed rules, notices, and executive orders on behalf of consultants. Four tools (search, get document, list agencies, search executive orders) backed by the free, open Federal Register API. TypeScript implementation compiled during Docker image build — zero setup for the end user.

## Definition of Done

A Federal Register MCP server integrated into the Shingle plugin that gives Claude Code the ability to search and retrieve documents from the Federal Register API. Ship-ready quality — good tool descriptions, error handling, clear output formatted for consultants.

**Success criteria:**
- Consultant can ask Claude natural-language questions about federal regulations and Claude uses the tools to answer
- Works inside the devcontainer with the firewall (federalregister.gov added to allowed hosts)
- Tools surface the right level of detail (title, abstract, dates, links — not raw API dumps)

**Out of scope:** PACER, SAM.gov, other data sources. Those come later.

## Glossary

- **MCP** — Model Context Protocol. The standard for connecting Claude to external tools and data sources. Claude Code launches MCP servers as subprocesses that communicate via JSON-RPC over stdin/stdout.
- **Federal Register** — The daily journal of the U.S. government, publishing rules, proposed rules, notices, and presidential documents from federal agencies. Free API at federalregister.gov/api/v1/.
- **Tool** — An MCP function that Claude can call. Each tool has a name, description (read by Claude to decide when to call it), input schema, and returns formatted text.
- **stdio transport** — Communication method where the MCP server reads JSON-RPC from stdin and writes responses to stdout. Claude Code manages the subprocess lifecycle.

## Architecture

### API Target

Federal Register API v1 — `https://www.federalregister.gov/api/v1/`

- Free, open, no authentication required
- JSON responses with pagination
- Rate limits: none documented (implement courtesy throttling)
- Pagination ceiling: 2,000 results per query (narrow with date ranges if exceeded)

### Tools

#### `search_federal_register`

The primary search tool. Claude calls this when a consultant asks about regulations, rules, or agency actions.

**Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `query` | string | yes | Free-text search terms |
| `agency` | string | no | Agency slug (e.g. "environmental-protection-agency") |
| `document_type` | enum | no | "rule", "proposed_rule", "notice", "presidential_document" |
| `date_from` | string | no | Start date (YYYY-MM-DD) |
| `date_to` | string | no | End date (YYYY-MM-DD) |
| `page` | number | no | Page number (default 1) |

**Maps to:** `GET /documents.json` with `conditions[term]`, `conditions[agencies][]`, `conditions[type][]`, `conditions[publication_date][gte]`, `conditions[publication_date][lte]`

**Returns:** Formatted list of results — title, type, agency, publication date, abstract (truncated), document number, Federal Register URL. Includes total count and pagination info.

#### `get_federal_register_document`

Deep dive on a specific document. Claude calls this after search results surface something relevant, or when the consultant references a specific document number.

**Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `document_number` | string | yes | Federal Register document number (e.g. "2026-01234") |

**Maps to:** `GET /documents/{document_number}`

**Returns:** Full document detail — title, type, abstract, agencies, publication date, effective date, CFR references, docket IDs, comment deadline, PDF URL, Federal Register URL. Formatted as a readable summary.

#### `search_executive_orders`

Convenience tool pre-filtered for executive orders. High-value for all practice areas.

**Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `query` | string | no | Free-text search terms |
| `president` | string | no | President slug (e.g. "donald-trump", "joe-biden") |
| `date_from` | string | no | Start date (YYYY-MM-DD) |
| `date_to` | string | no | End date (YYYY-MM-DD) |
| `page` | number | no | Page number (default 1) |

**Maps to:** `GET /documents.json` with `conditions[type][]=PRESDOCU`, `conditions[presidential_document_type]=executive_order`, plus other conditions.

**Returns:** Same format as search, but with executive order number included.

#### `list_agencies`

Discovery tool so Claude can look up agency slugs for filtered searches.

**Parameters:** None.

**Maps to:** `GET /agencies`

**Returns:** Formatted list of agency names and their slugs.

### File Structure

```
plugin/
  .mcp.json                              # MCP server declaration (NEW)
  servers/
    federal-register/
      src/
        index.ts                         # Entry point, server setup
        tools.ts                         # Tool definitions and handlers
        api.ts                           # Federal Register API client
        format.ts                        # Output formatting for consultants
      package.json                       # Dependencies (@modelcontextprotocol/sdk, zod)
      tsconfig.json                      # TypeScript config
      dist/
        index.js                         # Compiled output (built in Docker)
```

### Plugin Configuration

`.mcp.json` at plugin root:
```json
{
  "federal-register": {
    "command": "node",
    "args": ["${CLAUDE_PLUGIN_ROOT}/servers/federal-register/dist/index.js"]
  }
}
```

### Firewall Changes

Add `www.federalregister.gov` to the allowed hosts in `.devcontainer/init-firewall.sh`:

```bash
for host in api.anthropic.com registry.npmjs.org statsig.anthropic.com www.federalregister.gov; do
```

### Docker Build Changes

Add to `.devcontainer/Dockerfile` — install dependencies and compile TypeScript during image build:

```dockerfile
COPY plugin/servers/federal-register/package*.json /tmp/fr-server/
RUN cd /tmp/fr-server && npm install --production
COPY plugin/servers/federal-register/ /tmp/fr-server/
RUN cd /tmp/fr-server && npm run build
```

The compiled output gets copied into the plugin directory alongside the existing skills.

### CLI Template Changes

Update `src/cli/templates.ts` to include the `.mcp.json` file and server source in the scaffolded project.

## Existing Patterns Followed

- **Plugin structure:** Extends existing `plugin/` directory — skills in `skills/`, server in `servers/`
- **Firewall allowlist:** Same pattern as existing hosts in `init-firewall.sh`
- **Docker build:** Dependencies installed during image build, not at runtime
- **Zero-config for user:** Everything works out of the box after `npx shingle init` + container start
- **Plain language output:** Tool output uses the same consultant-friendly tone as the skills

## Implementation Phases

### Phase 1: MCP Server Core

Build the Federal Register MCP server with all four tools.

- Create `plugin/servers/federal-register/` with package.json, tsconfig.json
- Implement API client (`api.ts`) — HTTP calls to Federal Register API
- Implement output formatter (`format.ts`) — convert API responses to readable text
- Implement tool definitions and handlers (`tools.ts`) — Zod schemas, tool descriptions
- Implement server entry point (`index.ts`) — McpServer setup, stdio transport
- Add `.mcp.json` at plugin root

### Phase 2: Devcontainer Integration

Wire the server into the Docker build and firewall.

- Update `init-firewall.sh` — add `www.federalregister.gov` to allowed hosts
- Update `Dockerfile` — install server dependencies and compile TypeScript
- Update `welcome.sh` if needed — ensure server files land in the right place

### Phase 3: CLI Template Updates

Update `npx shingle init` to scaffold the new files.

- Add `.mcp.json` template to `src/cli/templates.ts`
- Add server source files to templates
- Rebuild CLI (`npm run build`)

### Phase 4: Testing and Polish

Verify end-to-end in the devcontainer.

- Test each tool with realistic consultant queries
- Verify firewall allows Federal Register API
- Verify formatted output is readable and useful
- Check error handling (bad document numbers, empty searches, network failures)

## Additional Considerations

- **Courtesy throttling:** The API has no documented rate limits, but implement a small delay between requests to be a good citizen.
- **Result limits:** Default to 10 results per search to keep output manageable for Claude's context. Allow pagination for "show me more."
- **Error messages:** Format errors for Claude to relay helpfully — e.g. "No documents found matching that search. Try broadening your date range or using different keywords."
- **Future extensibility:** The `servers/` directory pattern makes it easy to add PACER, SAM.gov, etc. as separate servers later. Each gets its own subdirectory and `.mcp.json` entry.
