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
