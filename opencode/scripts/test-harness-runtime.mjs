// No accounts or external model requests: a real OpenCode process talks only to
// a scripted loopback model. Run explicitly; macOS needs FSEvents access.
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { cp, mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { setTimeout as delay } from "node:timers/promises";

const source = fileURLToPath(new URL("../", import.meta.url));
const root = await mkdtemp(join(tmpdir(), "opencode-harness-runtime-"));
const requests = [];
const checkpoint = { objective: "Runtime fixture", phase: "verify", completed: ["Fixture checkpoint"], next: ["Finish fixture"], evidence: ["Synthetic test evidence"] };
let failure;
const model = createServer(async (req, res) => {
  try {
    let raw = "";
    for await (const chunk of req) raw += chunk;
    const body = JSON.parse(raw);
    requests.push(body);
    const system = body.messages.filter(m => m.role === "system").map(m => m.content).join("\n");
    const names = (body.tools ?? []).map(t => t.function.name);
    const primary = system.includes("Claude-style harness behavior:");
    const saved = system.includes("Saved checkpoint");
    const compact = system.includes("Preserve a usable continuation");
    const prompt = JSON.stringify(body.messages.filter(m => m.role === "user"));
    if (primary && prompt.includes("RETRY_FIXTURE")) {
      res.writeHead(500, { "content-type": "application/json" });
      res.end(JSON.stringify({ error: { message: "Synthetic retryable failure", type: "server_error" } }));
      return;
    }
    const delegation = /SUBAGENT_(FOREGROUND|BACKGROUND)/.exec(prompt)?.[1];
    const delegated = body.messages.some(m => m.role === "assistant" && m.tool_calls?.some(t => t.function.name === "subagent"));
    let call;
    if (primary && prompt.includes("GUARD_FIXTURE")) {
      const name = names.find(n => n.endsWith("checkpoint"));
      if (name) call = { index: 0, id: `call_${requests.length}`, type: "function", function: { name, arguments: JSON.stringify({ ...checkpoint, phase: "complete" }) } };
    } else if (primary && delegation && !delegated) {
      assert.ok(names.includes("subagent"), "native subagent tool must be available to builder");
      call = { index: 0, id: `call_${requests.length}`, type: "function", function: { name: "subagent", arguments: JSON.stringify({
        agent: "worker", description: "Run child fixture", prompt: "Run the synthetic child fixture and report the result.", background: delegation === "BACKGROUND",
      }) } };
    } else if (primary && !saved && !delegation) {
      const name = names.find(n => n.endsWith("checkpoint"));
      assert.ok(name, `checkpoint tool missing: ${names.join(", ")}`);
      call = { index: 0, id: `call_${requests.length}`, type: "function", function: { name, arguments: JSON.stringify(checkpoint) } };
    }
    const text = compact ? "Objective: Runtime fixture. Completed: Fixture checkpoint. Next: Finish fixture. Evidence: synthetic test evidence." : "Fixture completed.";
    const chunk = (delta, finish_reason = null) => ({ id: "fixture", object: "chat.completion.chunk", created: 1, model: "fixture", choices: [{ index: 0, delta, finish_reason }] });
    if (!body.stream) {
      res.writeHead(200, { "content-type": "application/json" });
      res.end(JSON.stringify({ id: "fixture", object: "chat.completion", created: 1, model: "fixture", choices: [{ index: 0, message: { role: "assistant", content: text }, finish_reason: "stop" }], usage: { prompt_tokens: 100, completion_tokens: 20 } }));
      return;
    }
    res.writeHead(200, { "content-type": "text/event-stream" });
    res.write(`data: ${JSON.stringify(chunk({ role: "assistant", ...(call ? { tool_calls: [call] } : { content: text }) }))}\n\n`);
    res.write(`data: ${JSON.stringify(chunk({}, call ? "tool_calls" : "stop"))}\n\n`);
    res.end("data: [DONE]\n\n");
  } catch (error) {
    failure = error;
    res.writeHead(500).end("fixture failed");
  }
});
model.listen(0, "127.0.0.1");
await once(model, "listening");
let child;
let output = "";
try {
  const configDir = join(root, "config/opencode");
  const project = join(root, "project");
  await mkdir(configDir, { recursive: true });
  await mkdir(project);
  // Copy the standalone package outside any node_modules ancestor to test the
  // actual runtime loader, not the workspace TypeScript resolver.
  await cp(join(source, "plugins/claude-harness"), join(configDir, "plugins/claude-harness"), { recursive: true });
  await cp(join(source, "agents"), join(configDir, "agents"), { recursive: true });
  const config = JSON.parse(await readFile(join(source, "opencode.json"), "utf8"));
  config.plugins = ["./plugins/claude-harness"];
  config.model = "harness-fixture/fixture";
  config.providers = {
    "harness-fixture": {
      package: "@ai-sdk/openai-compatible",
      settings: { baseURL: `http://127.0.0.1:${model.address().port}/v1`, apiKey: "local-fixture-only" },
      models: { fixture: { capabilities: { tools: true, input: ["text"], output: ["text"] }, limit: { context: 32000, output: 4096 } } },
    },
  };
  await writeFile(join(configDir, "opencode.json"), JSON.stringify(config));
  child = spawn("opencode", ["serve", "--hostname", "127.0.0.1", "--port", "0"], {
    cwd: project,
    env: { PATH: process.env.PATH, HOME: root, TMPDIR: root,
      XDG_CONFIG_HOME: join(root, "config"), XDG_DATA_HOME: join(root, "data"),
      XDG_CACHE_HOME: join(root, "cache"), XDG_STATE_HOME: join(root, "state"),
      OPENCODE_TEST_HOME: root, OPENCODE_DISABLE_MODELS_FETCH: "true", npm_config_cache: join(root, "npm") },
    stdio: ["ignore", "pipe", "pipe"],
  });
  child.stdout.on("data", chunk => { output += chunk; });
  child.stderr.on("data", chunk => { output += chunk; });
  child.on("error", error => { failure = error; });
  let url, password;
  for (let i = 0; i < 100; i++) {
    if (failure) throw failure;
    url = output.match(/server listening on (http:\/\/\S+)/)?.[1];
    password = output.match(/server password (\S+)/)?.[1];
    if (url && password) break;
    await delay(100);
  }
  assert.ok(url && password, "isolated OpenCode server did not start");
  async function api(path, data, method = data === undefined ? "GET" : "POST") {
    const response = await fetch(`${url}/api${path}`, {
      method, signal: AbortSignal.timeout(30000),
      headers: { authorization: `Basic ${Buffer.from(`opencode:${password}`).toString("base64")}`, "content-type": "application/json" },
      body: data === undefined ? undefined : JSON.stringify(data),
    });
    assert.ok(response.ok, `${path}: ${response.status} ${response.ok ? "" : await response.text()}`);
    return response.status === 204 ? undefined : await response.json();
  }
  async function ready() {
    for (let i = 0; i < 100; i++) {
      const { data } = await api("/plugin");
      if (data.some(p => p.id === "dotfiles.claude-harness" && p.state.status === "active")) return;
      await delay(100);
    }
    throw new Error("harness did not load; check filesystem-watch permissions");
  }
  await ready();
  const { data: agents } = await api("/agent");
  assert.equal(agents.find(a => a.id === "worker").steps, 40);
  const { data: session } = await api("/session", { agent: "builder", title: "Harness fixture", location: { directory: project } });
  await api(`/session/${session.id}/prompt`, { text: "Run the synthetic harness fixture." });
  await api(`/experimental/session/${session.id}/wait`, undefined, "POST");
  if (failure) throw failure;
  const { data: info } = await api(`/session/${session.id}`);
  assert.equal(info.outcome, "succeeded", JSON.stringify(info));
  let context = await api(`/session/${session.id}/context`);
  assert.match(JSON.stringify(context), /Fixture checkpoint/);
  assert.match(JSON.stringify(context), /Fixture completed/);
  assert.ok(requests.some(r => r.messages.some(m => m.role === "tool")), "tool result must reach the next model request");
  console.log("PASS native tool loop: checkpoint executes and paired result reaches the next request");

  await api("/location/reload", {});
  await ready();
  const beforeResume = requests.length;
  await api(`/session/${session.id}/prompt`, { text: "Resume from the checkpoint." });
  await api(`/experimental/session/${session.id}/wait`, undefined, "POST");
  assert.ok(requests.slice(beforeResume).some(r => JSON.stringify(r.messages).includes("Saved checkpoint")), "checkpoint must survive runtime reload");
  console.log("PASS checkpoint persists across real plugin reload");

  await api(`/session/${session.id}/compact`, {});
  await api(`/experimental/session/${session.id}/wait`, undefined, "POST");
  if (failure) throw failure;
  assert.ok(requests.some(r => JSON.stringify(r.messages).includes("Preserve a usable continuation")), "compaction hook must reach the summary model call");
  context = await api(`/session/${session.id}/context`);
  assert.match(JSON.stringify(context), /compaction/);
  console.log("PASS native compaction makes a summary request with harness continuation instructions");

  for (const mode of ["FOREGROUND", "BACKGROUND"]) {
    const { data: parent } = await api("/session", { agent: "builder", title: `Child fixture ${mode}`, location: { directory: project } });
    await api(`/session/${parent.id}/prompt`, { text: `SUBAGENT_${mode}: Run the synthetic child fixture.` });
    await api(`/experimental/session/${parent.id}/wait`, undefined, "POST");
    const { data: children } = await api(`/session?parentID=${parent.id}`);
    assert.equal(children.length, 1, "exactly one native child should be launched");
    const id = children[0].id;
    await api(`/experimental/session/${id}/wait`, undefined, "POST");
    const { data: childInfo } = await api(`/session/${id}`);
    assert.equal(childInfo.agent, "worker");
    assert.equal(childInfo.outcome, "succeeded");
    const childContext = await api(`/session/${id}/context`);
    assert.match(JSON.stringify(childContext), /Fixture checkpoint/);
    assert.match(JSON.stringify(childContext), /Fixture completed/);
    console.log(`PASS native ${mode.toLowerCase()} worker session completes with its own checkpoint`);
  }

  for (const scenario of ["GUARD_FIXTURE", "RETRY_FIXTURE"]) {
    const start = requests.length;
    const { data: session } = await api("/session", { agent: "builder", title: scenario, location: { directory: project } });
    await api(`/session/${session.id}/prompt`, { text: scenario });
    await api(`/experimental/session/${session.id}/wait`, undefined, "POST");
    const primary = requests.slice(start).filter(r => JSON.stringify(r.messages).includes("Claude-style harness behavior:") && JSON.stringify(r.messages).includes(scenario));
    const { data: info } = await api(`/session/${session.id}`);
    if (scenario === "GUARD_FIXTURE") {
      assert.equal(primary.length, 4, "three failed calls then one recovery round: " + JSON.stringify(primary.slice(0, 5).map(r => ({ tools: r.tools.map(t => t.function.name), messages: r.messages.filter(m => m.role === "tool"), guard: JSON.stringify(r.messages).includes("It is unavailable") }))));
      assert.ok(!primary[3].tools.some(t => t.function.name.endsWith("checkpoint")));
      assert.equal(info.outcome, "succeeded");
      console.log("PASS native repeated-tool failure guard changes the fourth request");
    } else {
      assert.equal(primary.length, 3, "initial request plus exactly two retries");
      assert.equal(info.outcome, "failed");
      console.log("PASS native retry exhaustion stops after three model attempts");
    }
  }
} finally {
  if (child?.pid && child.exitCode === null && child.signalCode === null) {
    child.kill("SIGTERM");
    await Promise.race([once(child, "exit"), delay(3000)]);
    if (child.exitCode === null && child.signalCode === null) { child.kill("SIGKILL"); await once(child, "exit"); }
  }
  model.closeAllConnections();
  await new Promise(resolve => model.close(resolve));
  await rm(root, { recursive: true, force: true });
}
