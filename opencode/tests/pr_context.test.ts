import assert from "node:assert/strict";
import test from "node:test";

import { parseSource, parseTestTypes } from "../tools/pr_context.js";

test("parseTestTypes accepts, normalizes, and deduplicates allowed types", () => {
  assert.deepEqual(parseTestTypes("unit, playwright,unit"), [
    "unit",
    "playwright",
  ]);
  assert.deepEqual(parseTestTypes("MANUAL"), ["manual"]);
});

test("parseTestTypes rejects empty and unknown categories", () => {
  assert.throws(() => parseTestTypes(""), /manual, unit, or playwright/);
  assert.throws(
    () => parseTestTypes("unit,integration"),
    /manual, unit, or playwright/,
  );
});

test("parseSource accepts a PR number or canonical GitHub PR URL", () => {
  assert.deepEqual(parseSource("123"), { number: 123 });
  assert.deepEqual(
    parseSource("https://github.com/example/widgets/pull/456"),
    { number: 456, repository: "example/widgets" },
  );
});

test("parseSource rejects ambiguous and malformed inputs", () => {
  for (const source of [
    "0",
    "999999999999999999999999999999999999",
    "owner/repo#123",
    "http://github.com/owner/repo/pull/123",
    "https://example.com/owner/repo/pull/123",
    "https://github.com/owner/repo/issues/123",
    "https://github.com/owner/repo/pull/123/files",
    "https://github.com/owner/repo/pull/123?diff=split",
    "https://user@github.com/owner/repo/pull/123",
    "https://github.com/owner/repo/pull/999999999999999999999999999999999999",
  ]) {
    assert.throws(() => parseSource(source));
  }
});
