import { describe, it, expect } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";
import { TEMPLATES } from "./templates.js";

// Map of template keys to their source files on disk (relative to project root).
// Only entries that have a real source file are listed — the rest are generated-only templates.
const TEMPLATE_SOURCE_MAP: Record<string, string> = {
  "plugin/servers/federal-register/src/api.ts": "plugin/servers/federal-register/src/api.ts",
  "plugin/servers/federal-register/src/format.ts": "plugin/servers/federal-register/src/format.ts",
  "plugin/servers/federal-register/src/tools.ts": "plugin/servers/federal-register/src/tools.ts",
  "plugin/servers/federal-register/src/index.ts": "plugin/servers/federal-register/src/index.ts",
  "plugin/servers/federal-register/package.json": "plugin/servers/federal-register/package.json",
  "plugin/servers/federal-register/tsconfig.json": "plugin/servers/federal-register/tsconfig.json",
  "plugin/servers/federal-register/.gitignore": "plugin/servers/federal-register/.gitignore",
  "plugin/.mcp.json": "plugin/.mcp.json",
};

const projectRoot = path.resolve(__dirname, "../..");

describe("template-source consistency", () => {
  for (const [templateKey, sourceRelPath] of Object.entries(TEMPLATE_SOURCE_MAP)) {
    it(`TEMPLATES["${templateKey}"] matches ${sourceRelPath}`, () => {
      const templateContent = TEMPLATES[templateKey];
      expect(templateContent, `template key "${templateKey}" not found in TEMPLATES`).toBeDefined();

      const sourceFilePath = path.join(projectRoot, sourceRelPath);
      expect(
        fs.existsSync(sourceFilePath),
        `source file not found: ${sourceFilePath}`,
      ).toBe(true);

      const sourceContent = fs.readFileSync(sourceFilePath, "utf-8");
      // Normalize line endings — git on Windows may check out CRLF
      const normalize = (s: string) => s.replace(/\r\n/g, "\n");
      expect(normalize(templateContent!)).toBe(normalize(sourceContent));
    });
  }
});

describe("TEMPLATES structure", () => {
  it("has expected template keys", () => {
    const keys = Object.keys(TEMPLATES);
    expect(keys).toContain("CLAUDE.md");
    expect(keys).toContain("README.md");
    expect(keys).toContain(".devcontainer/Dockerfile");
    expect(keys).toContain(".devcontainer/devcontainer.json");
    expect(keys).toContain("templates/CLAUDE.md.base");
    expect(keys).toContain("plugin/skills/review/SKILL.md");
    expect(keys).toContain("plugin/servers/federal-register/src/api.ts");
    expect(keys).toContain("docs/QUICKSTART.md");
  });

  it("no template value is empty", () => {
    for (const [key, value] of Object.entries(TEMPLATES)) {
      expect(value.length, `template "${key}" is empty`).toBeGreaterThan(0);
    }
  });

  it("all practice area templates are present", () => {
    expect(TEMPLATES["templates/CLAUDE.md.base"]).toBeDefined();
    expect(TEMPLATES["templates/CLAUDE.md.legal"]).toBeDefined();
    expect(TEMPLATES["templates/CLAUDE.md.audit"]).toBeDefined();
    expect(TEMPLATES["templates/CLAUDE.md.policy"]).toBeDefined();
    expect(TEMPLATES["templates/CLAUDE.md.govcon"]).toBeDefined();
  });
});
