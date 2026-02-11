import { defineWorkspace } from "vitest/config";

export default defineWorkspace([
  {
    test: {
      name: "federal-register",
      root: "plugin/servers/federal-register",
      include: ["src/**/*.test.ts"],
    },
  },
]);
