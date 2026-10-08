import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { Ajv2020 } from "ajv/dist/2020.js";
import { Schema } from "effect";
import { parse, type ParseError } from "jsonc-parser";
import { Config } from "@opencode/schema";

test("shared config and provider allowlists validate against the OpenCode 2.0.20 schema", () => {
  const document = Schema.toJsonSchemaDocument(Config.Info);
  const ajv = new Ajv2020({ strict: false, allErrors: true, validateFormats: false });
  const template = readFileSync(new URL("../opencode.jsonc", import.meta.url), "utf8");
  for (const [profile, providers] of [
    ["work", ["github-copilot", "github-copilot"]],
    ["personal", ["openai", "opencode"]],
  ] as const) {
    const errors: ParseError[] = [];
    const config = parse(template
      .replaceAll("@primary-provider@", providers[0])
      .replaceAll("@secondary-provider@", providers[1]), errors, {
      allowTrailingComma: true,
    });
    assert.deepEqual(errors, []);
    assert.equal(config.$schema, "./opencode.schema.json");
    assert.deepEqual(config.experimental.policies, [
      { action: "provider.use", resource: "*", effect: "deny" },
      ...providers.map(resource => ({ action: "provider.use", resource, effect: "allow" })),
    ]);
    const editorSchema = JSON.parse(
      readFileSync(new URL("../opencode.schema.json", import.meta.url), "utf8"),
    );
    assert.deepEqual(editorSchema.$defs, document.definitions);
    assert.equal(editorSchema.$ref, document.schema.$ref);
    const validate = ajv.compile(editorSchema);
    assert.ok(validate(config), `${profile}: ${JSON.stringify(validate.errors, null, 2)}`);
    assert.doesNotThrow(
      () => Schema.decodeUnknownSync(Config.Info)(config),
      `${profile} does not match @opencode/schema@2.0.20`,
    );
  }
});
