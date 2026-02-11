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
