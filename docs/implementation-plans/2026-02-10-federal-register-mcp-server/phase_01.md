# Federal Register MCP Server Implementation Plan

**Goal:** Build a Federal Register MCP server that gives Claude Code the ability to search and retrieve federal regulations, rules, notices, and executive orders for consultants.

**Architecture:** TypeScript MCP server using stdio transport, backed by the free Federal Register API. Four tools: search documents, get document detail, search executive orders, list agencies. Server compiles during Docker image build — zero setup for the end user.

**Tech Stack:** TypeScript, @modelcontextprotocol/sdk v1.x, zod v3.x, Node.js native fetch

**Scope:** 4 phases from original design (all phases)

**Codebase verified:** 2026-02-10

---

## Phase 1: MCP Server Core

Build the Federal Register MCP server with all four tools. This phase creates the server source code, plugin manifest, and verifies the build.

**Done when:** `npx tsc` compiles without errors and `dist/index.js` exists.

---

<!-- START_TASK_1 -->
### Task 1: Create server package.json and tsconfig.json

**Files:**
- Create: `plugin/servers/federal-register/package.json`
- Create: `plugin/servers/federal-register/tsconfig.json`

**Step 1: Create package.json**

Create the file `plugin/servers/federal-register/package.json` with this content:

```json
{
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
```

Key notes:
- `"type": "module"` is required — the MCP SDK uses ESM imports
- Zod MUST be v3.x — the MCP SDK v1.x is incompatible with Zod v4
- `"build": "tsc"` compiles TypeScript to `dist/`

**Step 2: Create tsconfig.json**

Create the file `plugin/servers/federal-register/tsconfig.json` with this content:

```json
{
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
```

**Step 3: Commit**

```bash
git add plugin/servers/federal-register/package.json plugin/servers/federal-register/tsconfig.json
git commit -m "chore: scaffold federal register MCP server project"
```

<!-- END_TASK_1 -->

<!-- START_TASK_2 -->
### Task 2: Create API client (api.ts)

**Files:**
- Create: `plugin/servers/federal-register/src/api.ts`

**Step 1: Create api.ts**

Create the file `plugin/servers/federal-register/src/api.ts` with this content:

```typescript
const BASE_URL = "https://www.federalregister.gov/api/v1";
const DEFAULT_PER_PAGE = 10;
const THROTTLE_MS = 200;

let lastRequestTime = 0;

// --- Response types ---

type DocumentAgency = {
  readonly raw_name: string;
  readonly name: string;
  readonly id: number;
  readonly slug: string;
};

type DocumentResult = {
  readonly title: string;
  readonly abstract: string | null;
  readonly publication_date: string;
  readonly effective_on: string | null;
  readonly document_number: string;
  readonly type: string;
  readonly citation: string | null;
  readonly html_url: string;
  readonly pdf_url: string | null;
  readonly executive_order_number: string | null;
  readonly signing_date: string | null;
  readonly docket_ids: ReadonlyArray<string>;
  readonly agencies: ReadonlyArray<DocumentAgency>;
  readonly cfr_references: ReadonlyArray<{
    readonly title: string;
    readonly part: string;
    readonly chapter?: string;
  }>;
  readonly comments_close_on: string | null;
  readonly president?: { readonly name: string; readonly identifier: string } | null;
};

type SearchResponse = {
  readonly count: number;
  readonly total_pages: number;
  readonly next_page_url: string | null;
  readonly results: ReadonlyArray<DocumentResult>;
};

type AgencyResponse = {
  readonly id: number;
  readonly name: string;
  readonly short_name: string | null;
  readonly slug: string;
  readonly url: string;
  readonly parent_id: number | null;
  readonly description: string | null;
};

// --- Parameter types ---

type SearchParams = {
  readonly query: string;
  readonly agency?: string;
  readonly documentType?: string;
  readonly dateFrom?: string;
  readonly dateTo?: string;
  readonly page?: number;
};

type ExecutiveOrderSearchParams = {
  readonly query?: string;
  readonly president?: string;
  readonly dateFrom?: string;
  readonly dateTo?: string;
  readonly page?: number;
};

// --- Internals ---

const DOCUMENT_TYPE_MAP: Record<string, string> = {
  rule: "RULE",
  proposed_rule: "PRORULE",
  notice: "NOTICE",
  presidential_document: "PRESDOCU",
};

async function throttle(): Promise<void> {
  const now = Date.now();
  const elapsed = now - lastRequestTime;
  if (elapsed < THROTTLE_MS) {
    await new Promise<void>((resolve) => setTimeout(resolve, THROTTLE_MS - elapsed));
  }
  lastRequestTime = Date.now();
}

async function fetchJson<T>(url: string): Promise<T> {
  await throttle();
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(
      `federal register API returned ${response.status} ${response.statusText}`
    );
  }
  return response.json() as Promise<T>;
}

function buildSearchUrl(params: Readonly<SearchParams>): string {
  const url = new URL(`${BASE_URL}/documents.json`);
  url.searchParams.set("per_page", String(DEFAULT_PER_PAGE));
  url.searchParams.set("page", String(params.page ?? 1));
  url.searchParams.set("order", "newest");

  const fields = [
    "title", "abstract", "publication_date", "document_number",
    "type", "citation", "html_url", "agencies", "effective_on",
    "executive_order_number", "docket_ids",
  ];
  for (const field of fields) {
    url.searchParams.append("fields[]", field);
  }

  url.searchParams.set("conditions[term]", params.query);

  if (params.agency) {
    url.searchParams.append("conditions[agencies][]", params.agency);
  }
  if (params.documentType) {
    const apiType = DOCUMENT_TYPE_MAP[params.documentType];
    if (apiType) {
      url.searchParams.append("conditions[type][]", apiType);
    }
  }
  if (params.dateFrom) {
    url.searchParams.set("conditions[publication_date][gte]", params.dateFrom);
  }
  if (params.dateTo) {
    url.searchParams.set("conditions[publication_date][lte]", params.dateTo);
  }

  return url.toString();
}

// --- Public API ---

async function searchDocuments(params: Readonly<SearchParams>): Promise<SearchResponse> {
  const url = buildSearchUrl(params);
  return fetchJson<SearchResponse>(url);
}

async function getDocument(documentNumber: string): Promise<DocumentResult> {
  const encoded = encodeURIComponent(documentNumber);
  const url = `${BASE_URL}/documents/${encoded}.json`;
  return fetchJson<DocumentResult>(url);
}

async function searchExecutiveOrders(
  params: Readonly<ExecutiveOrderSearchParams>,
): Promise<SearchResponse> {
  const url = new URL(`${BASE_URL}/documents.json`);
  url.searchParams.set("per_page", String(DEFAULT_PER_PAGE));
  url.searchParams.set("page", String(params.page ?? 1));
  url.searchParams.set("order", "newest");

  const fields = [
    "title", "abstract", "publication_date", "document_number",
    "type", "citation", "html_url", "agencies", "effective_on",
    "executive_order_number", "signing_date", "president",
  ];
  for (const field of fields) {
    url.searchParams.append("fields[]", field);
  }

  url.searchParams.append("conditions[type][]", "PRESDOCU");
  url.searchParams.set("conditions[presidential_document_type_id][]", "2");

  if (params.query) {
    url.searchParams.set("conditions[term]", params.query);
  }
  if (params.president) {
    url.searchParams.set("conditions[president]", params.president);
  }
  if (params.dateFrom) {
    url.searchParams.set("conditions[publication_date][gte]", params.dateFrom);
  }
  if (params.dateTo) {
    url.searchParams.set("conditions[publication_date][lte]", params.dateTo);
  }

  return fetchJson<SearchResponse>(url.toString());
}

async function listAgencies(): Promise<ReadonlyArray<AgencyResponse>> {
  return fetchJson<ReadonlyArray<AgencyResponse>>(`${BASE_URL}/agencies`);
}

export {
  searchDocuments,
  getDocument,
  searchExecutiveOrders,
  listAgencies,
  type SearchParams,
  type ExecutiveOrderSearchParams,
  type SearchResponse,
  type DocumentResult,
  type AgencyResponse,
  type DocumentAgency,
};
```

Key design decisions:
- Courtesy throttling (200ms minimum between requests) — the API has no documented rate limits but we're a good citizen
- `DEFAULT_PER_PAGE = 10` — keeps output manageable for Claude's context
- Document type mapping converts friendly names (`rule`) to API codes (`RULE`)
- `fields[]` parameters request only the fields we need — reduces response size
- All types use `readonly` properties and `ReadonlyArray<T>`
- Never use `console.log` — this code runs in a stdio MCP server where stdout is the JSON-RPC channel

**Step 2: Commit**

```bash
git add plugin/servers/federal-register/src/api.ts
git commit -m "feat: add federal register API client"
```

<!-- END_TASK_2 -->

<!-- START_TASK_3 -->
### Task 3: Create output formatter (format.ts)

**Files:**
- Create: `plugin/servers/federal-register/src/format.ts`

**Step 1: Create format.ts**

Create the file `plugin/servers/federal-register/src/format.ts` with this content:

```typescript
import type {
  SearchResponse,
  DocumentResult,
  AgencyResponse,
} from "./api.js";

function formatAgencyNames(
  agencies: ReadonlyArray<{ readonly name: string }>,
): string {
  return agencies.map((a) => a.name).join(", ");
}

function truncateAbstract(
  abstract: string | null,
  maxLength: number = 300,
): string {
  if (abstract === null) return "No abstract available.";
  if (abstract.length <= maxLength) return abstract;
  return abstract.slice(0, maxLength).trimEnd() + "...";
}

function formatSearchResults(
  response: Readonly<SearchResponse>,
  currentPage: number,
): string {
  if (response.count === 0) {
    return (
      "No documents found matching that search. " +
      "Try broadening your date range or using different keywords."
    );
  }

  const lines: Array<string> = [];
  lines.push(
    `Found ${response.count} document${response.count === 1 ? "" : "s"} ` +
    `(showing page ${currentPage} of ${response.total_pages}):\n`,
  );

  for (const doc of response.results) {
    lines.push(`**${doc.title}**`);
    lines.push(`  Type: ${doc.type}`);
    lines.push(`  Agency: ${formatAgencyNames(doc.agencies)}`);
    lines.push(`  Published: ${doc.publication_date}`);
    if (doc.citation) lines.push(`  Citation: ${doc.citation}`);
    lines.push(`  Document #: ${doc.document_number}`);
    lines.push(`  ${truncateAbstract(doc.abstract)}`);
    lines.push(`  Link: ${doc.html_url}`);
    lines.push("");
  }

  if (response.total_pages > currentPage) {
    lines.push(
      `Page ${currentPage} of ${response.total_pages}. ` +
      `Ask for the next page to see more results.`,
    );
  }

  return lines.join("\n");
}

function formatDocumentDetail(doc: Readonly<DocumentResult>): string {
  const lines: Array<string> = [];

  lines.push(`**${doc.title}**\n`);
  lines.push(`Type: ${doc.type}`);
  lines.push(`Agency: ${formatAgencyNames(doc.agencies)}`);
  lines.push(`Published: ${doc.publication_date}`);
  if (doc.effective_on) lines.push(`Effective: ${doc.effective_on}`);
  if (doc.citation) lines.push(`Citation: ${doc.citation}`);
  lines.push(`Document #: ${doc.document_number}`);

  if (doc.executive_order_number) {
    lines.push(`Executive Order #: ${doc.executive_order_number}`);
  }
  if (doc.signing_date) {
    lines.push(`Signed: ${doc.signing_date}`);
  }
  if (doc.docket_ids.length > 0) {
    lines.push(`Docket IDs: ${doc.docket_ids.join(", ")}`);
  }
  if (doc.comments_close_on) {
    lines.push(`Comment Deadline: ${doc.comments_close_on}`);
  }
  if (doc.cfr_references.length > 0) {
    const refs = doc.cfr_references
      .map((r) => `${r.title} CFR Part ${r.part}`)
      .join(", ");
    lines.push(`CFR References: ${refs}`);
  }

  lines.push("");
  if (doc.abstract) {
    lines.push(`**Abstract:**\n${doc.abstract}`);
    lines.push("");
  }

  lines.push(`Federal Register: ${doc.html_url}`);
  if (doc.pdf_url) lines.push(`PDF: ${doc.pdf_url}`);

  return lines.join("\n");
}

function formatExecutiveOrderResults(
  response: Readonly<SearchResponse>,
  currentPage: number,
): string {
  if (response.count === 0) {
    return (
      "No executive orders found matching that search. " +
      "Try different keywords or a broader date range."
    );
  }

  const lines: Array<string> = [];
  lines.push(
    `Found ${response.count} executive order${response.count === 1 ? "" : "s"} ` +
    `(showing page ${currentPage} of ${response.total_pages}):\n`,
  );

  for (const doc of response.results) {
    const eoNum = doc.executive_order_number
      ? `EO ${doc.executive_order_number}: `
      : "";
    lines.push(`**${eoNum}${doc.title}**`);
    if (doc.signing_date) lines.push(`  Signed: ${doc.signing_date}`);
    lines.push(`  Published: ${doc.publication_date}`);
    if (doc.citation) lines.push(`  Citation: ${doc.citation}`);
    lines.push(`  Document #: ${doc.document_number}`);
    lines.push(`  ${truncateAbstract(doc.abstract)}`);
    lines.push(`  Link: ${doc.html_url}`);
    lines.push("");
  }

  if (response.total_pages > currentPage) {
    lines.push(
      `Page ${currentPage} of ${response.total_pages}. ` +
      `Ask for the next page to see more results.`,
    );
  }

  return lines.join("\n");
}

function formatAgencyList(
  agencies: ReadonlyArray<Readonly<AgencyResponse>>,
): string {
  const lines: Array<string> = [];
  lines.push(`${agencies.length} federal agencies:\n`);

  const topLevel = agencies.filter((a) => a.parent_id === null);
  const subAgencyCount = agencies.length - topLevel.length;

  for (const agency of topLevel) {
    const shortName = agency.short_name ? ` (${agency.short_name})` : "";
    lines.push(
      `- **${agency.name}**${shortName} — slug: \`${agency.slug}\``,
    );
  }

  if (subAgencyCount > 0) {
    lines.push(
      `\nPlus ${subAgencyCount} sub-agencies. ` +
      `Use a top-level agency slug with search_federal_register to filter results.`,
    );
  }

  return lines.join("\n");
}

export {
  formatSearchResults,
  formatDocumentDetail,
  formatExecutiveOrderResults,
  formatAgencyList,
};
```

Key design decisions:
- All format functions are pure (Functional Core) — no I/O, just string assembly
- Abstracts truncated to 300 chars to keep search results scannable
- Agency list splits top-level vs sub-agencies to avoid overwhelming output
- Markdown bold (`**title**`) used for readability in Claude's responses
- Empty search results return helpful guidance, not just "no results"
- Import path uses `.js` extension — required for Node16 ESM module resolution

**Step 2: Commit**

```bash
git add plugin/servers/federal-register/src/format.ts
git commit -m "feat: add federal register output formatter"
```

<!-- END_TASK_3 -->

<!-- START_TASK_4 -->
### Task 4: Create tool definitions (tools.ts)

**Files:**
- Create: `plugin/servers/federal-register/src/tools.ts`

**Step 1: Create tools.ts**

Create the file `plugin/servers/federal-register/src/tools.ts` with this content:

```typescript
import { z } from "zod";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import {
  searchDocuments,
  getDocument,
  searchExecutiveOrders,
  listAgencies,
} from "./api.js";
import {
  formatSearchResults,
  formatDocumentDetail,
  formatExecutiveOrderResults,
  formatAgencyList,
} from "./format.js";

function registerTools(server: McpServer): void {
  server.registerTool(
    "search_federal_register",
    {
      description:
        "Search the Federal Register for rules, proposed rules, notices, and presidential documents. " +
        "Use this when a consultant asks about federal regulations, agency actions, or rulemaking.",
      inputSchema: {
        query: z
          .string()
          .describe("Search terms (e.g. 'clean water' or 'cybersecurity')"),
        agency: z
          .string()
          .optional()
          .describe(
            "Agency slug (e.g. 'environmental-protection-agency'). " +
            "Use list_agencies to find slugs.",
          ),
        document_type: z
          .enum(["rule", "proposed_rule", "notice", "presidential_document"])
          .optional()
          .describe("Filter by document type"),
        date_from: z
          .string()
          .optional()
          .describe("Start date (YYYY-MM-DD)"),
        date_to: z
          .string()
          .optional()
          .describe("End date (YYYY-MM-DD)"),
        page: z
          .number()
          .optional()
          .default(1)
          .describe("Page number for pagination (default 1)"),
      },
    },
    async ({ query, agency, document_type, date_from, date_to, page }) => {
      try {
        const response = await searchDocuments({
          query,
          agency,
          documentType: document_type,
          dateFrom: date_from,
          dateTo: date_to,
          page,
        });
        return {
          content: [
            {
              type: "text" as const,
              text: formatSearchResults(response, page ?? 1),
            },
          ],
        };
      } catch (error) {
        const message =
          error instanceof Error ? error.message : "unknown error";
        return {
          content: [
            {
              type: "text" as const,
              text: `failed to search Federal Register: ${message}`,
            },
          ],
        };
      }
    },
  );

  server.registerTool(
    "get_federal_register_document",
    {
      description:
        "Get full details for a specific Federal Register document by its document number. " +
        "Use this after search results surface something relevant, or when a consultant " +
        "references a specific document.",
      inputSchema: {
        document_number: z
          .string()
          .describe(
            "Federal Register document number (e.g. '2026-01234')",
          ),
      },
    },
    async ({ document_number }) => {
      try {
        const doc = await getDocument(document_number);
        return {
          content: [
            { type: "text" as const, text: formatDocumentDetail(doc) },
          ],
        };
      } catch (error) {
        const message =
          error instanceof Error ? error.message : "unknown error";
        return {
          content: [
            {
              type: "text" as const,
              text: `failed to retrieve document ${document_number}: ${message}`,
            },
          ],
        };
      }
    },
  );

  server.registerTool(
    "search_executive_orders",
    {
      description:
        "Search for executive orders from the Federal Register. " +
        "Use this when a consultant asks about executive orders, presidential actions, " +
        "or executive policy.",
      inputSchema: {
        query: z
          .string()
          .optional()
          .describe(
            "Search terms (leave empty to list recent executive orders)",
          ),
        president: z
          .string()
          .optional()
          .describe(
            "President slug (e.g. 'donald-trump', 'joe-biden')",
          ),
        date_from: z
          .string()
          .optional()
          .describe("Start date (YYYY-MM-DD)"),
        date_to: z
          .string()
          .optional()
          .describe("End date (YYYY-MM-DD)"),
        page: z
          .number()
          .optional()
          .default(1)
          .describe("Page number for pagination (default 1)"),
      },
    },
    async ({ query, president, date_from, date_to, page }) => {
      try {
        const response = await searchExecutiveOrders({
          query,
          president,
          dateFrom: date_from,
          dateTo: date_to,
          page,
        });
        return {
          content: [
            {
              type: "text" as const,
              text: formatExecutiveOrderResults(response, page ?? 1),
            },
          ],
        };
      } catch (error) {
        const message =
          error instanceof Error ? error.message : "unknown error";
        return {
          content: [
            {
              type: "text" as const,
              text: `failed to search executive orders: ${message}`,
            },
          ],
        };
      }
    },
  );

  server.registerTool(
    "list_agencies",
    {
      description:
        "List all federal agencies in the Federal Register with their slugs. " +
        "Use this to look up the correct agency slug for filtered searches " +
        "with search_federal_register.",
      inputSchema: {},
    },
    async () => {
      try {
        const agencies = await listAgencies();
        return {
          content: [
            { type: "text" as const, text: formatAgencyList(agencies) },
          ],
        };
      } catch (error) {
        const message =
          error instanceof Error ? error.message : "unknown error";
        return {
          content: [
            {
              type: "text" as const,
              text: `failed to list agencies: ${message}`,
            },
          ],
        };
      }
    },
  );
}

export { registerTools };
```

Key design decisions:
- `inputSchema` passes plain Zod schema objects (NOT wrapped in `z.object()`) — the MCP SDK wraps them internally
- `.describe()` on every parameter — Claude reads these to understand when/how to call each tool
- Tool descriptions are written for Claude: they explain when to use each tool, not just what it does
- Error handling catches all errors and returns them as text content — never throws from a tool handler
- Error messages use lowercase fragments per house style: `"failed to search Federal Register: ..."`
- `type: "text" as const` satisfies TypeScript's literal type requirement for the MCP content type

**Step 2: Commit**

```bash
git add plugin/servers/federal-register/src/tools.ts
git commit -m "feat: add federal register tool definitions"
```

<!-- END_TASK_4 -->

<!-- START_TASK_5 -->
### Task 5: Create server entry point (index.ts)

**Files:**
- Create: `plugin/servers/federal-register/src/index.ts`

**Step 1: Create index.ts**

Create the file `plugin/servers/federal-register/src/index.ts` with this content:

```typescript
#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { registerTools } from "./tools.js";

const server = new McpServer({
  name: "federal-register",
  version: "1.0.0",
});

registerTools(server);

async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Federal Register MCP server running on stdio");
}

main().catch((error: unknown) => {
  console.error("fatal error starting Federal Register server:", error);
  process.exit(1);
});
```

**CRITICAL:** Never use `console.log()` in a stdio MCP server. The stdout channel is the JSON-RPC communication channel between Claude Code and the server. Any non-JSON-RPC output on stdout corrupts the protocol. Use `console.error()` for all diagnostic output — it goes to stderr.

**Step 2: Commit**

```bash
git add plugin/servers/federal-register/src/index.ts
git commit -m "feat: add federal register MCP server entry point"
```

<!-- END_TASK_5 -->

<!-- START_TASK_6 -->
### Task 6: Create plugin MCP manifest (.mcp.json)

**Files:**
- Create: `plugin/.mcp.json`

**Step 1: Create .mcp.json**

Create the file `plugin/.mcp.json` with this content:

```json
{
  "federal-register": {
    "command": "node",
    "args": ["${CLAUDE_PLUGIN_ROOT}/servers/federal-register/dist/index.js"]
  }
}
```

This tells Claude Code to launch the compiled MCP server as a subprocess using Node.js. The `${CLAUDE_PLUGIN_ROOT}` variable is resolved by Claude Code at runtime to the plugin's installed location.

**Step 2: Commit**

```bash
git add plugin/.mcp.json
git commit -m "feat: add MCP server manifest for federal register"
```

<!-- END_TASK_6 -->

<!-- START_TASK_7 -->
### Task 7: Install dependencies and verify build

**Step 1: Install dependencies**

```bash
cd plugin/servers/federal-register
npm install
```

Expected: Installs @modelcontextprotocol/sdk, zod, @types/node, and typescript without errors. Creates `node_modules/` and `package-lock.json`.

**Step 2: Build**

```bash
npx tsc
```

Expected: Compiles without errors. Creates `dist/` directory with `index.js`, `tools.js`, `api.js`, `format.js`.

**Step 3: Verify output exists**

```bash
ls dist/
```

Expected output includes: `index.js`, `tools.js`, `api.js`, `format.js`

**Step 4: Commit lock file**

```bash
cd ../../..
git add plugin/servers/federal-register/package-lock.json
git commit -m "chore: add federal register server lock file"
```

Note: Do NOT commit `node_modules/` or `dist/` — they're built during the Docker image build. If there's no `.gitignore` in the server directory, create one:

Create `plugin/servers/federal-register/.gitignore`:
```
node_modules/
dist/
```

```bash
git add plugin/servers/federal-register/.gitignore
git commit -m "chore: add federal register server .gitignore"
```

<!-- END_TASK_7 -->
