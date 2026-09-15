import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { Ajv2020 } from "ajv/dist/2020.js";
import { parse, type ParseError } from "jsonc-parser";

// Opt-in network check: fetch schema data only, never load OpenCode/plugins/MCP.
async function loadSchema(uri: string) {
  const url = new URL(uri);
  assert.equal(url.protocol, "https:");
  assert.ok(["opencode.ai", "models.dev"].includes(url.hostname));
  const response = await fetch(url, {
    signal: AbortSignal.timeout(30000), redirect: "error",
  });
  assert.ok(response.ok, `schema fetch failed: ${url} (${response.status})`);
  return response.json();
}

test("profiles validate against the current official OpenCode schema", async () => {
  const ajv = new Ajv2020({ strict: false, allErrors: true, validateFormats: false, loadSchema });
  const validate = await ajv.compileAsync(await loadSchema("https://opencode.ai/config.json"));
  for (const profile of ["work", "personal"]) {
    const errors: ParseError[] = [];
    const config = parse(readFileSync(new URL(`../opencode.${profile}.jsonc`, import.meta.url), "utf8"), errors, {
      allowTrailingComma: true,
    });
    assert.deepEqual(errors, []);
    assert.ok(validate(config), `${profile}: ${JSON.stringify(validate.errors, null, 2)}`);
  }
});
