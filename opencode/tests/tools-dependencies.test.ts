import assert from "node:assert/strict";
import test from "node:test";
import { mkdtempSync, rmdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { query } from "../tools/memory.js";
import { list } from "../tools/session_reader.js";

// No helper can be resolved, including on a developer machine where it exists.
// Exercise spawn ENOENT only: never execute a database helper or open user data.
test("optional database helpers fail clearly when absent", async () => {
  const previous = process.env.PATH;
  // A real empty directory produces ENOENT consistently; /dev/null can cause
  // synchronous ENOTDIR on macOS before the child error handler is registered.
  const emptyPath = mkdtempSync(join(tmpdir(), "audit-empty-path-"));
  process.env.PATH = emptyPath;
  try {
    await assert.rejects(
      () => query.execute({}, {} as Parameters<typeof query.execute>[1]),
      /Optional dependency agent_memory is not on PATH/,
    );
    await assert.rejects(
      () => list.execute({}, {} as Parameters<typeof list.execute>[1]),
      /Optional dependency session_reader is not on PATH/,
    );
  } finally {
    if (previous === undefined) delete process.env.PATH;
    else process.env.PATH = previous;
    rmdirSync(emptyPath);
  }
});
