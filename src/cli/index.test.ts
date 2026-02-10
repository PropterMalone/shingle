import { describe, it, expect } from "vitest";
import { parseArgs } from "./index.js";

describe("parseArgs", () => {
  // argv[0] = node, argv[1] = script — parseArgs slices from index 2

  it("parses bare init command", () => {
    const result = parseArgs(["node", "shingle", "init"]);
    expect(result).toEqual({ command: "init", directory: ".", practice: null });
  });

  it("parses init with directory", () => {
    const result = parseArgs(["node", "shingle", "init", "my-project"]);
    expect(result).toEqual({ command: "init", directory: "my-project", practice: null });
  });

  it("parses init with --practice flag", () => {
    const result = parseArgs(["node", "shingle", "init", "--practice", "legal"]);
    expect(result).toEqual({ command: "init", directory: ".", practice: "legal" });
  });

  it("parses init with directory and --practice", () => {
    const result = parseArgs(["node", "shingle", "init", "my-project", "--practice", "audit"]);
    expect(result).toEqual({ command: "init", directory: "my-project", practice: "audit" });
  });

  it("returns empty command when no args", () => {
    const result = parseArgs(["node", "shingle"]);
    expect(result).toEqual({ command: "", directory: ".", practice: null });
  });

  it("captures unknown command", () => {
    const result = parseArgs(["node", "shingle", "deploy"]);
    expect(result).toEqual({ command: "deploy", directory: ".", practice: null });
  });
});
