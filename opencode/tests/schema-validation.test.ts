import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { Ajv2020 } from "ajv/dist/2020.js";
import { Schema } from "effect";
import { parse, type ParseError } from "jsonc-parser";
import { Config } from "@opencode/schema";

test("global config and work migration overlay validate against the OpenCode 2.0.20 schema", () => {
  const document = Schema.toJsonSchemaDocument(Config.Info);
  const ajv = new Ajv2020({ strict: false, allErrors: true, validateFormats: false });
  for (const directory of ["", "work-migration/"]) {
    const errors: ParseError[] = [];
    const config = parse(
      readFileSync(new URL(`../${directory}opencode.jsonc`, import.meta.url), "utf8"),
      errors,
      { allowTrailingComma: true },
    ) as {
      $schema: string;
      agents?: Record<string, { system?: string }>;
      commands?: Record<string, { template?: string }>;
    };
    assert.deepEqual(errors, []);
    assert.equal(config.$schema, "./opencode.schema.json");
    const editorSchema = JSON.parse(
      readFileSync(new URL(`../${directory}opencode.schema.json`, import.meta.url), "utf8"),
    );
    assert.deepEqual(editorSchema.$defs, document.definitions);
    assert.equal(editorSchema.$ref, document.schema.$ref);
    const validate = ajv.compile(editorSchema);
    assert.ok(validate(config), `${directory || "global"}: ${JSON.stringify(validate.errors, null, 2)}`);
    assert.doesNotThrow(
      () => Schema.decodeUnknownSync(Config.Info)(config),
      `${directory || "global"} does not match @opencode/schema@2.0.20`,
    );
    for (const reference of [
      ...Object.values(config.agents ?? {}).map((agent) => agent.system),
      ...Object.values(config.commands ?? {}).map((command) => command.template),
    ]) {
      const path = /^\{file:(\.\/[^}]+)\}$/.exec(reference ?? "")?.[1];
      if (path) {
        assert.doesNotThrow(
          () => readFileSync(new URL(`../${directory}${path.slice(2)}`, import.meta.url)),
          `${directory || "global"} is missing ${path}`,
        );
      }
    }
  }
});
