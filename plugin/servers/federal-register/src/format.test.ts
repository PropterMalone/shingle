import { describe, it, expect } from "vitest";
import {
  truncateAbstract,
  formatSearchResults,
  formatDocumentDetail,
  formatExecutiveOrderResults,
  formatAgencyList,
} from "./format.js";
import type { SearchResponse, DocumentResult, AgencyResponse } from "./api.js";

// --- Fixtures ---

function makeDoc(overrides: Partial<DocumentResult> = {}): DocumentResult {
  return {
    title: "Test Rule",
    abstract: "A test abstract for this document.",
    publication_date: "2026-01-15",
    effective_on: null,
    document_number: "2026-00001",
    type: "Rule",
    citation: "91 FR 1234",
    html_url: "https://www.federalregister.gov/documents/2026/01/15/2026-00001/test-rule",
    pdf_url: null,
    executive_order_number: null,
    signing_date: null,
    docket_ids: [],
    agencies: [{ raw_name: "EPA", name: "Environmental Protection Agency", id: 1, slug: "epa" }],
    cfr_references: [],
    comments_close_on: null,
    ...overrides,
  };
}

function makeSearchResponse(overrides: Partial<SearchResponse> = {}): SearchResponse {
  return {
    count: 1,
    total_pages: 1,
    next_page_url: null,
    results: [makeDoc()],
    ...overrides,
  };
}

// --- truncateAbstract ---

describe("truncateAbstract", () => {
  it("returns placeholder for null", () => {
    expect(truncateAbstract(null)).toBe("No abstract available.");
  });

  it("returns full text when under limit", () => {
    expect(truncateAbstract("Short text.")).toBe("Short text.");
  });

  it("returns full text when exactly at limit", () => {
    const exact = "a".repeat(300);
    expect(truncateAbstract(exact)).toBe(exact);
  });

  it("truncates and adds ellipsis when over limit", () => {
    const long = "a".repeat(350);
    const result = truncateAbstract(long);
    expect(result).toHaveLength(303); // 300 + "..."
    expect(result.endsWith("...")).toBe(true);
  });

  it("respects custom maxLength", () => {
    const text = "Hello world, this is a test.";
    const result = truncateAbstract(text, 10);
    expect(result).toBe("Hello worl...");
  });

  it("trims trailing whitespace before ellipsis", () => {
    // 10 chars: "Hello     " then truncate at 10 should trim trailing space
    const text = "Hello      world and more stuff beyond the limit";
    const result = truncateAbstract(text, 10);
    expect(result).toBe("Hello...");
  });
});

// --- formatSearchResults ---

describe("formatSearchResults", () => {
  it("returns no-results message for zero count", () => {
    const response = makeSearchResponse({ count: 0, results: [] });
    const result = formatSearchResults(response, 1);
    expect(result).toContain("No documents found");
  });

  it("shows singular count for one document", () => {
    const result = formatSearchResults(makeSearchResponse({ count: 1, total_pages: 1 }), 1);
    expect(result).toContain("Found 1 document (");
  });

  it("shows plural count for multiple documents", () => {
    const response = makeSearchResponse({ count: 5, total_pages: 1 });
    const result = formatSearchResults(response, 1);
    expect(result).toContain("Found 5 documents ");
  });

  it("includes pagination prompt when more pages exist", () => {
    const response = makeSearchResponse({ count: 20, total_pages: 3 });
    const result = formatSearchResults(response, 1);
    expect(result).toContain("Page 1 of 3");
    expect(result).toContain("next page");
  });

  it("omits pagination prompt on last page", () => {
    const response = makeSearchResponse({ count: 5, total_pages: 2 });
    const result = formatSearchResults(response, 2);
    expect(result).not.toContain("next page");
  });

  it("includes document fields", () => {
    const result = formatSearchResults(makeSearchResponse(), 1);
    expect(result).toContain("**Test Rule**");
    expect(result).toContain("Environmental Protection Agency");
    expect(result).toContain("2026-01-15");
    expect(result).toContain("91 FR 1234");
    expect(result).toContain("2026-00001");
  });

  it("handles null citation gracefully", () => {
    const response = makeSearchResponse({
      results: [makeDoc({ citation: null })],
    });
    const result = formatSearchResults(response, 1);
    expect(result).not.toContain("Citation:");
  });
});

// --- formatDocumentDetail ---

describe("formatDocumentDetail", () => {
  it("includes all required fields", () => {
    const result = formatDocumentDetail(makeDoc());
    expect(result).toContain("**Test Rule**");
    expect(result).toContain("Type: Rule");
    expect(result).toContain("Environmental Protection Agency");
    expect(result).toContain("Published: 2026-01-15");
    expect(result).toContain("Document #: 2026-00001");
  });

  it("shows optional fields when present", () => {
    const doc = makeDoc({
      effective_on: "2026-03-01",
      executive_order_number: "14100",
      signing_date: "2026-01-14",
      docket_ids: ["EPA-HQ-2026-001"],
      comments_close_on: "2026-04-15",
      abstract: "Full abstract text here.",
      pdf_url: "https://example.com/doc.pdf",
    });
    const result = formatDocumentDetail(doc);
    expect(result).toContain("Effective: 2026-03-01");
    expect(result).toContain("Executive Order #: 14100");
    expect(result).toContain("Signed: 2026-01-14");
    expect(result).toContain("Docket IDs: EPA-HQ-2026-001");
    expect(result).toContain("Comment Deadline: 2026-04-15");
    expect(result).toContain("**Abstract:**\nFull abstract text here.");
    expect(result).toContain("PDF: https://example.com/doc.pdf");
  });

  it("omits optional fields when null/empty", () => {
    const result = formatDocumentDetail(makeDoc());
    expect(result).not.toContain("Effective:");
    expect(result).not.toContain("Executive Order #:");
    expect(result).not.toContain("Signed:");
    expect(result).not.toContain("Docket IDs:");
    expect(result).not.toContain("Comment Deadline:");
    expect(result).not.toContain("PDF:");
  });

  it("formats CFR references", () => {
    const doc = makeDoc({
      cfr_references: [
        { title: "40", part: "122" },
        { title: "40", part: "123" },
      ],
    });
    const result = formatDocumentDetail(doc);
    expect(result).toContain("CFR References: 40 CFR Part 122, 40 CFR Part 123");
  });
});

// --- formatExecutiveOrderResults ---

describe("formatExecutiveOrderResults", () => {
  it("returns no-results message for zero count", () => {
    const response = makeSearchResponse({ count: 0, results: [] });
    const result = formatExecutiveOrderResults(response, 1);
    expect(result).toContain("No executive orders found");
  });

  it("prefixes EO number when present", () => {
    const response = makeSearchResponse({
      results: [makeDoc({ executive_order_number: "14100", title: "Test EO" })],
    });
    const result = formatExecutiveOrderResults(response, 1);
    expect(result).toContain("**EO 14100: Test EO**");
  });

  it("omits EO prefix when null", () => {
    const response = makeSearchResponse({
      results: [makeDoc({ executive_order_number: null, title: "Test EO" })],
    });
    const result = formatExecutiveOrderResults(response, 1);
    expect(result).toContain("**Test EO**");
    expect(result).not.toContain("EO ");
  });

  it("includes signing date when present", () => {
    const response = makeSearchResponse({
      results: [makeDoc({ signing_date: "2026-01-14" })],
    });
    const result = formatExecutiveOrderResults(response, 1);
    expect(result).toContain("Signed: 2026-01-14");
  });

  it("shows singular for one executive order", () => {
    const response = makeSearchResponse({ count: 1, total_pages: 1 });
    const result = formatExecutiveOrderResults(response, 1);
    expect(result).toContain("1 executive order ");
    expect(result).not.toContain("orders ");
  });
});

// --- formatAgencyList ---

describe("formatAgencyList", () => {
  const agencies: AgencyResponse[] = [
    { id: 1, name: "Environmental Protection Agency", short_name: "EPA", slug: "epa", url: "https://epa.gov", parent_id: null, description: null },
    { id: 2, name: "Department of Defense", short_name: "DOD", slug: "dod", url: "https://dod.gov", parent_id: null, description: null },
    { id: 3, name: "Army Corps of Engineers", short_name: null, slug: "army-corps", url: "https://usace.army.mil", parent_id: 2, description: null },
  ];

  it("shows total agency count", () => {
    const result = formatAgencyList(agencies);
    expect(result).toContain("3 federal agencies:");
  });

  it("lists only top-level agencies with details", () => {
    const result = formatAgencyList(agencies);
    expect(result).toContain("**Environmental Protection Agency** (EPA)");
    expect(result).toContain("**Department of Defense** (DOD)");
    expect(result).not.toContain("Army Corps of Engineers");
  });

  it("shows sub-agency count", () => {
    const result = formatAgencyList(agencies);
    expect(result).toContain("Plus 1 sub-agencies");
  });

  it("omits sub-agency note when none exist", () => {
    const topOnly = agencies.filter((a) => a.parent_id === null);
    const result = formatAgencyList(topOnly);
    expect(result).not.toContain("sub-agencies");
  });

  it("omits short name parenthetical when null", () => {
    const noShort: AgencyResponse[] = [
      { id: 1, name: "Test Agency", short_name: null, slug: "test", url: "https://test.gov", parent_id: null, description: null },
    ];
    const result = formatAgencyList(noShort);
    expect(result).toContain("**Test Agency** —");
    expect(result).not.toContain("()");
  });
});
