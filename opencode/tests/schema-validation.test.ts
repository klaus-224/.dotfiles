import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import { Schema } from "effect";
import { parse, type ParseError } from "jsonc-parser";
import { Config } from "@opencode/schema";

test("profiles validate against the OpenCode 2.0.20 schema", () => {
  for (const profile of ["work", "personal"]) {
    const errors: ParseError[] = [];
    const config = parse(readFileSync(new URL(`../${profile}/opencode.jsonc`, import.meta.url), "utf8"), errors, {
      allowTrailingComma: true,
    });
    assert.deepEqual(errors, []);
    assert.doesNotThrow(
      () => Schema.decodeUnknownSync(Config.Info)(config),
      `${profile} does not match @opencode/schema@2.0.20`,
    );
  }
});
