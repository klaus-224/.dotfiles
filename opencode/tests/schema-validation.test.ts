import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { Ajv } from "ajv";
import { parse } from "jsonc-parser";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const targetCommit = "b072d279110bdda2c6ac2525d0d24dc54d16148a";

function readJsonc(name: string): unknown {
  return parse(readFileSync(join(root, name), "utf8"), [], {
    allowTrailingComma: true,
    disallowComments: false,
  });
}

async function fetchSchema(name: string): Promise<Record<string, unknown>> {
  const url = `https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/${targetCommit}/assets/${name}`;
  const response = await fetch(url);
  assert.equal(response.ok, true, `failed to fetch pinned schema: ${url}`);
  const schema = (await response.json()) as Record<string, unknown>;
  // Generated harness schemas embed repeated copies of the plugin schema with
  // one dev-branch $id. Validate the fetched commit content without registering
  // those non-versioned identifiers.
  const stripIds = (value: unknown): void => {
    if (value === null || typeof value !== "object") return;
    if (Array.isArray(value)) {
      for (const entry of value) stripIds(entry);
      return;
    }
    const record = value as Record<string, unknown>;
    delete record.$id;
    for (const entry of Object.values(record)) stripIds(entry);
  };
  stripIds(schema);
  return schema;
}

test("OMO config validates against the pinned target schemas", async () => {
  const [omoSchema, pluginSchema] = await Promise.all([
    fetchSchema("omo.schema.json"),
    fetchSchema("oh-my-opencode.schema.json"),
  ]);
  const config = readJsonc("omo.jsonc") as Record<string, unknown>;

  const validateOmo = new Ajv({
    allErrors: true,
    strict: false,
    validateFormats: false,
  }).compile(omoSchema);
  assert.equal(validateOmo(config), true, JSON.stringify(validateOmo.errors, null, 2));

  const validatePlugin = new Ajv({
    allErrors: true,
    strict: false,
    validateFormats: false,
  }).compile(pluginSchema);
  assert.equal(
    validatePlugin(config["[opencode]"]),
    true,
    JSON.stringify(validatePlugin.errors, null, 2),
  );
});
