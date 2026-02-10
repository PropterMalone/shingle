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
