import { describe, it, expect } from "vitest";
import { buildSearchUrl, DOCUMENT_TYPE_MAP } from "./api.js";

describe("DOCUMENT_TYPE_MAP", () => {
  it("maps rule to RULE", () => {
    expect(DOCUMENT_TYPE_MAP["rule"]).toBe("RULE");
  });

  it("maps proposed_rule to PRORULE", () => {
    expect(DOCUMENT_TYPE_MAP["proposed_rule"]).toBe("PRORULE");
  });

  it("maps notice to NOTICE", () => {
    expect(DOCUMENT_TYPE_MAP["notice"]).toBe("NOTICE");
  });

  it("maps presidential_document to PRESDOCU", () => {
    expect(DOCUMENT_TYPE_MAP["presidential_document"]).toBe("PRESDOCU");
  });

  it("has exactly 4 mappings", () => {
    expect(Object.keys(DOCUMENT_TYPE_MAP)).toHaveLength(4);
  });
});

describe("buildSearchUrl", () => {
  function parse(url: string): URL {
    return new URL(url);
  }

  it("sets defaults for a basic query", () => {
    const url = parse(buildSearchUrl({ query: "clean water" }));
    expect(url.origin).toBe("https://www.federalregister.gov");
    expect(url.pathname).toBe("/api/v1/documents.json");
    expect(url.searchParams.get("per_page")).toBe("10");
    expect(url.searchParams.get("page")).toBe("1");
    expect(url.searchParams.get("order")).toBe("newest");
    expect(url.searchParams.get("conditions[term]")).toBe("clean water");
  });

  it("includes expected field list", () => {
    const url = parse(buildSearchUrl({ query: "test" }));
    const fields = url.searchParams.getAll("fields[]");
    expect(fields).toContain("title");
    expect(fields).toContain("abstract");
    expect(fields).toContain("agencies");
    expect(fields).toContain("html_url");
  });

  it("adds agency filter", () => {
    const url = parse(buildSearchUrl({ query: "test", agency: "epa" }));
    expect(url.searchParams.getAll("conditions[agencies][]")).toContain("epa");
  });

  it("maps document type through DOCUMENT_TYPE_MAP", () => {
    const url = parse(buildSearchUrl({ query: "test", documentType: "rule" }));
    expect(url.searchParams.getAll("conditions[type][]")).toContain("RULE");
  });

  it("ignores unknown document type", () => {
    const url = parse(buildSearchUrl({ query: "test", documentType: "fake" }));
    expect(url.searchParams.getAll("conditions[type][]")).toHaveLength(0);
  });

  it("adds date range filters", () => {
    const url = parse(
      buildSearchUrl({ query: "test", dateFrom: "2026-01-01", dateTo: "2026-06-30" }),
    );
    expect(url.searchParams.get("conditions[publication_date][gte]")).toBe("2026-01-01");
    expect(url.searchParams.get("conditions[publication_date][lte]")).toBe("2026-06-30");
  });

  it("uses explicit page number", () => {
    const url = parse(buildSearchUrl({ query: "test", page: 5 }));
    expect(url.searchParams.get("page")).toBe("5");
  });

  it("combines all params", () => {
    const url = parse(
      buildSearchUrl({
        query: "cybersecurity",
        agency: "dod",
        documentType: "notice",
        dateFrom: "2025-01-01",
        dateTo: "2025-12-31",
        page: 3,
      }),
    );
    expect(url.searchParams.get("conditions[term]")).toBe("cybersecurity");
    expect(url.searchParams.getAll("conditions[agencies][]")).toContain("dod");
    expect(url.searchParams.getAll("conditions[type][]")).toContain("NOTICE");
    expect(url.searchParams.get("conditions[publication_date][gte]")).toBe("2025-01-01");
    expect(url.searchParams.get("conditions[publication_date][lte]")).toBe("2025-12-31");
    expect(url.searchParams.get("page")).toBe("3");
  });
});
