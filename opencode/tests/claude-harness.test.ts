import assert from "node:assert/strict";
import { readFileSync, realpathSync } from "node:fs";
import test from "node:test";
import { Schema } from "effect";
import { Config } from "@opencode/schema";
import type { Plugin } from "@opencode/plugin";
import harness, { parseCheckpoint } from "../plugins/claude-harness/index.js";

const checkpoint = {
  objective: "Fix the parser", phase: "verify", completed: ["Updated src/parser.ts"],
  next: ["Run parser tests"], evidence: ["Inspected the failing input"],
};

async function fixture(storage = new Map<string, any>(), options: Record<string, unknown> = {}) {
  const sessionHooks: Record<string, (event: any) => any> = {};
  const toolHooks: Record<string, (event: any) => any> = {};
  const tools: Record<string, any> = {};
  const history = new Map<string, any[]>();
  const messages = (sessionID: string) => {
    if (!history.has(sessionID)) history.set(sessionID, [{ role: "user", content: [{ type: "text", text: "Fix the parser" }] }]);
    return history.get(sessionID)!;
  };
  const ctx = {
    options,
    session: { hook: async (name: string, fn: (event: any) => any) => { sessionHooks[name] = fn; } },
    tool: {
      hook: async (name: string, fn: (event: any) => any) => { toolHooks[name] = fn; },
      transform: async (fn: (editor: any) => any) => fn({
        namespace() {}, add(tool: any) { tools[tool.name] = tool; },
      }),
    },
    storage: {
      get: async (key: string) => structuredClone(storage.get(key)),
      set: async (key: string, value: unknown) => { storage.set(key, structuredClone(value)); },
    },
  } as unknown as Plugin.Context;
  const cleanup = await harness.setup(ctx);
  const event = (sessionID = "one", agent = "builder") => ({
    sessionID, agent, system: [{ type: "text", text: "Existing instructions" }],
    messages: structuredClone(messages(sessionID)),
    tools: { shell: { description: "shell", input: {} }, read: { description: "read", input: {} } },
    options: {},
  });
  const execute = (name: string, input: unknown, sessionID = "one", signal = new AbortController().signal, agent = "builder") =>
    tools[name].execute(input, { sessionID, agent, signal });
  const result = (tool: string, input: unknown, sessionID: string, type: string) => {
    const history = messages(sessionID);
    const id = `call_${history.length}`;
    history.push({ role: "assistant", content: [{ type: "tool-call", id, name: tool, input }] });
    history.push({ role: "tool", content: [{ type: "tool-result", id, name: tool, result: { type, value: "fixture" } }] });
  };
  const failure = (tool = "shell", input: unknown = { command: "pnpm test" }, sessionID = "one") => result(tool, input, sessionID, "error");
  const success = () => result("read", { path: "src/app.ts" }, "one", "text");
  const prompt = () => messages("one").push({ role: "user", content: [{ type: "text", text: "Try again" }] });
  return { storage, sessionHooks, tools, cleanup, event, execute, failure, success, prompt };
}

test("checkpoint survives plugin reload, stays session-local, and enriches real compaction", async () => {
  const first = await fixture();
  await first.execute("checkpoint", checkpoint);
  first.cleanup();
  const f = await fixture(first.storage);
  const request = f.event();
  const messages = structuredClone(request.messages);
  await f.sessionHooks.context(request);
  assert.equal(request.system[0].text, "Existing instructions");
  assert.match(request.system.at(-1)!.text, /Fix the parser/);
  assert.match(request.system.at(-1)!.text, /untrusted model-authored/);
  assert.deepEqual(request.messages, messages);
  const compact = f.event();
  await f.sessionHooks.compaction(compact);
  assert.match(compact.system[1].text, /Child session IDs/);
  assert.match(compact.system.at(-1)!.text, /Run parser tests/);
  assert.equal("result" in compact, false, "must not bypass model summarization");
  assert.deepEqual(compact.messages, messages);
  const other = f.event("two");
  await f.sessionHooks.context(other);
  assert.ok(!JSON.stringify(other).includes("Updated src/parser.ts"));
  assert.deepEqual(JSON.parse((await f.execute("status", {}, "two")).content), { checkpoint: null });
});

test("checkpoint validates completion, bounds, unexpected fields, and cancellation before persistence", async () => {
  const f = await fixture();
  for (const invalid of [null, [], {}, { ...checkpoint, secret: "do not store" },
    { ...checkpoint, phase: "other" }, { ...checkpoint, objective: " " },
    { ...checkpoint, next: Array(21).fill("x") }, { ...checkpoint, evidence: [42] },
    { ...checkpoint, completed: Array(10).fill("x".repeat(2000)) },
    { ...checkpoint, phase: "complete" }, { ...checkpoint, phase: "complete", next: [], evidence: [] }]) {
    assert.throws(() => parseCheckpoint(invalid));
    await assert.rejects(f.execute("checkpoint", invalid));
  }
  const controller = new AbortController();
  controller.abort();
  await assert.rejects(f.execute("checkpoint", checkpoint, "one", controller.signal));
  assert.equal(f.storage.size, 0);
  await f.execute("checkpoint", { ...checkpoint, phase: "complete", next: [] });
  assert.equal(JSON.parse((await f.execute("status", {})).content).checkpoint.phase, "complete");
});

test("three equivalent failed calls remove only that tool for one request, not the transcript", async () => {
  const f = await fixture();
  await f.failure("shell", { command: "pnpm test", cwd: "." });
  await f.failure("shell", { cwd: ".", command: "pnpm test" });
  const before = f.event();
  await f.sessionHooks.context(before);
  assert.ok(before.tools.shell);
  await f.failure("shell", { command: "pnpm test", cwd: "." });
  const request = f.event();
  const messages = structuredClone(request.messages);
  await f.sessionHooks.context(request);
  assert.equal(request.tools.shell, undefined);
  assert.ok(request.tools.read);
  assert.deepEqual(request.messages, messages);
  assert.match(request.system.at(-1)!.text, /Do not bypass denied permissions/);
  const next = f.event();
  await f.sessionHooks.context(next);
  assert.ok(next.tools.shell);
  assert.equal(f.storage.size, 0, "raw tool input/output must not be persisted");
});

test("changed arguments, success, new input, and different sessions break the failure streak", async () => {
  const f = await fixture();
  await f.failure(); await f.failure(); await f.failure("shell", { command: "pnpm lint" });
  let request = f.event();
  await f.sessionHooks.context(request);
  assert.ok(request.tools.shell);
  await f.failure(); await f.failure(); await f.failure();
  request = f.event("two");
  await f.sessionHooks.context(request);
  assert.ok(request.tools.shell);
  f.success();
  request = f.event();
  await f.sessionHooks.context(request);
  assert.ok(request.tools.shell);
  await f.failure(); await f.failure(); await f.failure();
  f.prompt();
  request = f.event();
  await f.sessionHooks.context(request);
  assert.ok(request.tools.shell);
});

test("retry ceiling uses upcoming attempt numbering and preserves native denial and Retry-After", async () => {
  const f = await fixture();
  for (const attempt of [2, 3]) {
    const event = { agent: "builder", attempt, decision: { retry: true, delay: 60000 } };
    await f.sessionHooks.retry(event);
    assert.deepEqual(event.decision, { retry: true, delay: 60000 });
  }
  const limit = { agent: "builder", attempt: 4, decision: { retry: true, delay: 1 } };
  await f.sessionHooks.retry(limit);
  assert.deepEqual(limit.decision, { retry: false });
  const denied = { agent: "builder", attempt: 2, decision: { retry: false } };
  await f.sessionHooks.retry(denied);
  assert.deepEqual(denied.decision, { retry: false });
  const noRetry = await fixture(new Map(), { maxAttempts: 1 });
  const event = { agent: "worker", attempt: 2, decision: { retry: true, delay: 1 } };
  await noRetry.sessionHooks.retry(event);
  assert.deepEqual(event.decision, { retry: false });
  for (const maxAttempts of [0, 11, 1.5, "3"]) await assert.rejects(fixture(new Map(), { maxAttempts }));
});

test("custom agents and auxiliary requests are not silently given builder behavior", async () => {
  const f = await fixture();
  const event = f.event("one", "custom");
  const original = structuredClone(event);
  await f.sessionHooks.context(event);
  await f.sessionHooks.compaction(event);
  assert.deepEqual(event, original);
  assert.equal(f.sessionHooks.title, undefined);
  assert.equal(f.sessionHooks.generate, undefined);
  await assert.rejects(f.execute("checkpoint", checkpoint, "one", new AbortController().signal, "custom"));
});

test("configuration uses the pinned schema, preserves profile policy, and exposes the shared plugin", () => {
  const root = new URL("../", import.meta.url);
  const config = JSON.parse(readFileSync(new URL("opencode.json", root), "utf8"));
  assert.doesNotThrow(() => Schema.decodeUnknownSync(Config.Info)(config));
  assert.ok(config.plugins.includes("./plugins/claude-harness"));
  assert.equal(realpathSync(new URL("shared-plugins/claude-harness", root)), realpathSync(new URL("plugins/claude-harness", root)));
  assert.equal(config.compaction.auto, true);
  assert.equal(config.agents.builder.steps, 80);
  assert.equal(config.agents.worker.steps, 40);
  assert.equal(config.agents.worker.mode, "subagent");
  assert.equal(config.agents.worker.model, undefined, "worker inherits the parent's selected provider/model");
  assert.ok(config.agents.builder.permissions.some((r: any) => r.action === "subagent" && r.resource === "worker" && r.effect === "allow"));
  assert.ok(config.agents.worker.permissions.some((r: any) => r.action === "subagent" && r.resource === "*" && r.effect === "deny"));
  assert.equal(config.permissions.some((r: any) => r.action === "*" && r.resource === "*.env" && r.effect === "deny"), true);
  for (const profile of ["work.jsonc", "personal.jsonc"]) {
    const value = JSON.parse(readFileSync(new URL(profile, root), "utf8"));
    assert.doesNotThrow(() => Schema.decodeUnknownSync(Config.Info)(value));
    assert.ok(value.experimental.policies.some((r: any) => r.action === "provider.use" && r.resource === "*" && r.effect === "deny"));
  }
});
