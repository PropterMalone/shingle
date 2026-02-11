# Federal Register MCP Server

Last verified: 2026-02-10

## Purpose

Gives Claude live access to the Federal Register API so consultants can search regulations, executive orders, and agency actions without leaving their workflow.

## Contracts

- **Exposes**: 4 MCP tools: `search_federal_register`, `get_federal_register_document`, `search_executive_orders`, `list_agencies`
- **Guarantees**: 200ms throttle between API calls. Errors return text content (never throws to MCP client). All responses formatted as human-readable text.
- **Expects**: Network access to `www.federalregister.gov` (must be in firewall allowlist)

## Dependencies

- **Uses**: Federal Register API v1 (`https://www.federalregister.gov/api/v1`), `@modelcontextprotocol/sdk`, `zod`
- **Used by**: Claude Code via `.mcp.json` manifest (stdio transport)
- **Boundary**: No access to local filesystem or other plugin components

## Key Decisions

- **Stdio transport**: MCP SDK standard for local tool servers; Claude Code manages the process lifecycle
- **No API key needed**: Federal Register API is public, unauthenticated
- **Built at container build time**: Compiled TypeScript in Dockerfile, not at runtime, to keep startup fast
- **Throttle in-process**: Simple elapsed-time gate rather than external rate limiter

## Invariants

- Tool names are stable (changing them breaks existing conversations/prompts)
- API base URL is `https://www.federalregister.gov/api/v1` (no config override)
- Server entry point is `dist/index.js` (referenced by `.mcp.json`)

## Key Files

- `src/index.ts` - Server bootstrap (McpServer + StdioServerTransport)
- `src/tools.ts` - Tool registration and input schemas
- `src/api.ts` - Federal Register API client with types and throttle
- `src/format.ts` - Response formatters (API JSON -> readable text)

## Gotchas

- `www.federalregister.gov` must be in `init-firewall.sh` or all API calls fail silently inside the container
- The `dist/` directory is gitignored; `tsc` runs during Docker build
- Agency slugs (e.g., `environmental-protection-agency`) are required for filtered search -- `list_agencies` provides them
