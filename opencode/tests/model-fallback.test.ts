import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { Model, Plugin } from "@opencode/plugin";
import type { SessionHooks } from "@opencode/plugin/promise/session";
import { loadConfig, parseConfig, type FallbackConfig } from "../plugins/model-fallback/config.js";
import { fallbackError, setupFallback } from "../plugins/model-fallback/index.js";

const config = parseConfig(await readFile(new URL("../opencode-fallback.jsonc", import.meta.url), "utf8"));
const chain = [config.primary_model, ...config.fallback_models];
type Ref = { providerID: string; id: string; variant?: string };
const key = (model: Ref) => `${model.providerID}/${model.id}`;
async function fixture(overrides: Partial<FallbackConfig> = {}, inventory = chain) {
  let time = 1_000;
  const hooks: Partial<Record<keyof SessionHooks, (event: any) => Promise<void> | void>> = {};
  const selections = new Map<string, Ref>();
  const switches: string[] = [];
  let defaultModel = Model.Ref.parse(inventory[0]);
  const models = inventory.map(id => ({ ...Model.Ref.parse(id), enabled: true, capabilities: { tools: true } }));
  const ctx = {
    model: {
      list: async () => ({ data: models }),
      default: async () => ({ data: defaultModel }),
      transform: async (fn: any) => fn({
        get: (providerID: string, id: string) => models.find(m => m.providerID === providerID && m.id === id),
        default: { set: (providerID: string, id: string) => { defaultModel = Model.Ref.parse(`${providerID}/${id}`); } },
      }),
    },
    session: {
      hook: async (name: keyof SessionHooks, fn: any) => { hooks[name] = fn; },
      get: async ({ sessionID }: { sessionID: string }) => ({ model: selections.get(sessionID) }),
      switchModel: async ({ sessionID, model }: { sessionID: string; model: Ref }) => {
        selections.set(sessionID, { ...model, variant: model.variant ?? "default" });
        switches.push(`${sessionID}:${key(model)}`);
      },
    },
  } as unknown as Plugin.Context;
  await setupFallback(ctx, { ...config, notify_on_fallback: false, ...overrides }, () => time);
  const selected = (sessionID = "a") => selections.get(sessionID) ?? defaultModel;
  return {
    hooks, switches, selections, models, selected,
    tick: (ms: number) => { time += ms; },
    prompt: async (sessionID = "a") => {
      await hooks.prompt?.({ sessionID });
      await hooks.context?.({ sessionID, model: selected(sessionID) });
    },
    fail: async (status = 429, sessionID = "a") => {
      const event = { sessionID, model: selected(sessionID), error: { type: "provider.rate-limit", message: "quota exceeded", status }, decision: { retry: true, delay: 1000 } };
      await hooks.retry?.(event);
      // Native retries rebuild context before dispatching the selected model.
      if (event.decision.retry) await hooks.context?.({ sessionID, model: selected(sessionID) });
      return event.decision;
    },
  };
}

test("ordered chain retries exactly four models then stops, even without cooldown", async () => {
  const f = await fixture({ cooldown_seconds: 0 });
  await f.prompt();
  for (const expected of chain.slice(1)) {
    assert.deepEqual(await f.fail(), { retry: true, delay: 0 });
    assert.equal(key(f.selected()), expected);
  }
  assert.deepEqual(await f.fail(), { retry: false });
  assert.equal(f.switches.length, 4);
});

test("cooldown persists across prompts and restores the original variant only on a later prompt", async () => {
  const f = await fixture();
  f.selections.set("a", { ...Model.Ref.parse(chain[0]), variant: "high" });
  await f.prompt();
  await f.fail();
  await f.prompt();
  assert.equal(key(f.selected()), chain[1]);
  f.tick(300_000);
  assert.equal(key(f.selected()), chain[1]);
  await f.prompt();
  assert.equal(key(f.selected()), chain[0]);
  assert.equal(f.selected().variant, "high");
});

test("cooldowns are shared but sessions and manual selections remain independent", async () => {
  const f = await fixture();
  await f.prompt("a");
  await f.fail(429, "a");
  await f.prompt("b");
  assert.equal(key(f.selected("b")), chain[1]);
  f.selections.set("a", Model.Ref.parse(chain[3]));
  f.tick(300_000);
  await f.prompt("a");
  assert.equal(key(f.selected("a")), chain[3]);
  await f.fail(503, "a");
  assert.equal(key(f.selected("a")), chain[4]);
  assert.equal(key(f.selected("b")), chain[1]);
});

test("policy-unavailable, disabled and tool-incapable models are skipped", async () => {
  const f = await fixture({}, [chain[0], chain[2], chain[3], chain[4]]);
  f.models[1].enabled = false;
  f.models[2].capabilities.tools = false;
  await f.prompt();
  await f.fail();
  assert.equal(key(f.selected()), chain[4]);
});

test("Copilot-only inventory does not change defaults or retry decisions", async () => {
  const f = await fixture({}, ["github-copilot/example"]);
  await f.prompt();
  assert.deepEqual(await f.fail(), { retry: true, delay: 1000 });
  assert.equal(f.switches.length, 0);
  assert.equal(key(f.selected()), "github-copilot/example");
});

test("attempt limit and disabled switch are honored", async () => {
  const f = await fixture({ max_fallback_attempts: 1 });
  await f.prompt();
  await f.fail();
  assert.deepEqual(await f.fail(), { retry: false });
  const disabled = await fixture({ enabled: false });
  assert.deepEqual(disabled.hooks, {});
});

test("compaction and stale retries cannot switch the session", async () => {
  const f = await fixture();
  await f.prompt();
  await f.hooks.compaction?.({ sessionID: "a" });
  await f.fail();
  assert.equal(f.switches.length, 0);
  await f.prompt();
  f.selections.set("a", Model.Ref.parse("another/manual"));
  await f.hooks.retry?.({ sessionID: "a", model: Model.Ref.parse(chain[0]), error: { status: 429, type: "provider.rate-limit" }, decision: { retry: true, delay: 1000 } });
  assert.equal(f.switches.length, 0);
});

test("only eligible provider errors trigger fallback", () => {
  for (const status of [429, 500, 502, 503, 504])
    assert.equal(fallbackError({ type: "provider.failure", message: "failed", status }), true);
  assert.equal(fallbackError({ type: "provider.invalid-request", message: "usage_limit_reached" }), true);
  assert.equal(fallbackError({ type: "provider.invalid-request", status: 404, message: "model was not found" }), true);
  for (const error of [
    { type: "provider.auth", status: 401, message: "quota exceeded" },
    { type: "provider.permission", status: 403, message: "quota exceeded" },
    { type: "provider.context-overflow", status: 429, message: "too many tokens" },
    { type: "aborted", status: 503, message: "cancelled" },
    { type: "provider.invalid-request", status: 400, message: "invalid tool schema" },
    { type: "provider.invalid-request", status: 404, message: "endpoint not found" },
  ]) assert.equal(fallbackError(error), false);
});

test("JSONC config rejects malformed or unsupported routing settings", () => {
  assert.equal(parseConfig(`// comment\n${JSON.stringify(config)}`).enabled, true);
  for (const patch of [{ cooldown_seconds: -1 }, { max_fallback_attempts: 5 },
    { timeout_seconds: 30 }, { fallback_models: [chain[0]] }, { primary_model: "broken" },
    { enabled: "true" }, { unexpected: true }, { fallback_models: ["openai/a#high"] }])
    assert.throws(() => parseConfig(JSON.stringify({ ...config, ...patch })));
  assert.throws(() => parseConfig('{"enabled": true, broken}'));
});

test("project JSONC wins over JSON/global; missing disables; invalid config fails closed", async () => {
  const root = await mkdtemp(join(tmpdir(), "fallback-config-"));
  try {
    const global = join(root, "global"), project = join(root, "project");
    await mkdir(global); await mkdir(join(project, ".opencode"), { recursive: true });
    const env = { OPENCODE_CONFIG_DIR: global };
    assert.equal(await loadConfig(project, env), undefined);
    await writeFile(join(global, "opencode-fallback.jsonc"), JSON.stringify(config));
    assert.deepEqual(await loadConfig(project, env), config);
    await writeFile(join(project, ".opencode/opencode-fallback.json"), JSON.stringify(config));
    await writeFile(join(project, ".opencode/opencode-fallback.jsonc"), JSON.stringify({ ...config, enabled: false }));
    assert.equal((await loadConfig(project, env))?.enabled, false);
    await writeFile(join(project, ".opencode/opencode-fallback.jsonc"), "invalid");
    await assert.rejects(loadConfig(project, env));
  } finally { await rm(root, { recursive: true, force: true }); }
});
