import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, readdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { test } from "node:test";

import {
  fileFor,
  statusDirectory,
  statusFor,
  writeStatus,
} from "../plugins/agent-status/index.js";

test("maps OpenCode events to agent statuses", () => {
  const data = (extra: object = {}) => ({ sessionID: "ses_1", ...extra });
  assert.deepEqual(statusFor({ type: "session.status", data: data({ status: { type: "busy" } }) }), {
    sessionID: "ses_1",
    status: "busy",
  });
  assert.equal(statusFor({ type: "session.status", data: data({ status: { type: "retry" } }) })?.status, "busy");
  assert.equal(statusFor({ type: "session.status", data: data({ status: { type: "idle" } }) })?.status, "idle");
  assert.equal(statusFor({ type: "session.idle", data: data() })?.status, "idle");
  assert.equal(statusFor({ type: "permission.asked", data: data() })?.status, "waiting");
  assert.equal(statusFor({ type: "permission.replied", data: data() })?.status, "busy");
  assert.equal(statusFor({ type: "session.deleted", data: data() })?.status, null);
  assert.equal(statusFor({ type: "session.status", data: data({ status: { type: "odd" } }) }), undefined);
  assert.equal(statusFor({ type: "session.created", data: data() }), undefined);
  assert.equal(statusFor({ type: "session.idle", data: {} }), undefined);
});

test("writes the generic status record atomically", () => {
  const root = mkdtempSync(path.join(tmpdir(), "agent-status-"));
  try {
    assert.equal(statusDirectory({ XDG_STATE_HOME: root }), path.join(root, "agents"));
    const directory = path.join(root, "agents");
    const file = writeStatus(directory, "ses/../1", "waiting", "repo", 42);
    assert.equal(file, fileFor(directory, "ses/../1"));
    assert.equal(path.dirname(file), directory);
    const record = JSON.parse(readFileSync(file, "utf8"));
    assert.deepEqual(
      { ...record, updated: 0 },
      { agent: "opencode", id: "ses/../1", pid: 42, name: "repo", status: "waiting", updated: 0 },
    );
    assert.deepEqual(readdirSync(directory), [path.basename(file)]);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
