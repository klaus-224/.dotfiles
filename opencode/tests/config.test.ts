import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { dirname, join, resolve, relative } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { parse, type ParseError } from "jsonc-parser";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
function readJsonc(name: string): Record<string, any> {
  const errors: ParseError[] = [];
  const value = parse(readFileSync(join(root, name), "utf8"), errors, { allowTrailingComma: true });
  assert.deepEqual(errors, [], `${name} must be valid JSONC`);
  return value;
}
const work = readJsonc("opencode.work.jsonc");
const personal = readJsonc("opencode.personal.jsonc");
const profiles = { work, personal };

test("profiles preserve distinct defaults, providers and plugin workflows", () => {
  assert.equal(work.default_agent, "chat");
  assert.equal(personal.default_agent, "pair-programmer");
  assert.deepEqual(work.enabled_providers, ["github-copilot"]);
  assert.deepEqual(work.disabled_providers, ["opencode", "openai"]);
  assert.equal(work.mcp.atlassian.enabled, true);
  assert.deepEqual(personal.enabled_providers, ["openai", "opencode"]);
  assert.equal(personal.mcp, undefined);
  assert.deepEqual(work.plugin, []);
  assert.deepEqual(personal.plugin, [["@plannotator/opencode@0.27.12", {
    workflow: "user-managed", planningAgents: ["planner", "orchestrator"],
  }]]);
  for (const profile of Object.values(profiles)) {
    assert.equal(profile.autoupdate, false, "Nix owns OpenCode updates");
    assert.equal(profile.permission.webfetch, "deny");
    assert.equal(profile.permission.external_directory, "deny");
    const agent = profile.agent[profile.default_agent];
    assert.ok(agent && agent.disable !== true);
    assert.equal(agent.mode, "primary");
  }
});

test("all configured agents have explicit modes/descriptions and valid task targets", () => {
  for (const [profileName, profile] of Object.entries(profiles)) {
    for (const [name, agent] of Object.entries<any>(profile.agent)) {
      assert.ok(agent.description?.trim(), `${profileName}/${name} description`);
      assert.ok(["primary", "subagent", "all"].includes(agent.mode), `${name} mode`);
      if (typeof agent.permission?.task !== "object") continue;
      for (const [target, action] of Object.entries(agent.permission.task)) {
        if (target === "*" || action === "deny") continue;
        assert.ok(profile.agent[target], `${name} task target ${target}`);
        assert.ok(["subagent", "all"].includes(profile.agent[target].mode));
      }
    }
  }
});

test("every file interpolation exists within the config directory", () => {
  for (const profile of Object.values(profiles)) {
    for (const match of JSON.stringify(profile).matchAll(/\{file:([^}]+)\}/g)) {
      const path = resolve(root, match[1]);
      assert.ok(!relative(root, path).startsWith(".."));
      assert.ok(readFileSync(path, "utf8").trim(), `nonempty prompt ${path}`);
    }
  }
});

test("profile-scoped and shared commands never reference missing agents", () => {
  for (const profile of Object.values(profiles)) {
    for (const command of Object.values<any>(profile.command ?? {})) {
      assert.ok(profile.agent[command.agent]);
      assert.ok(command.template);
    }
    for (const file of readdirSync(join(root, "commands"))) {
      const text = readFileSync(join(root, "commands", file), "utf8");
      const agent = text.match(/^agent:\s*(\S+)/m)?.[1];
      if (agent) assert.ok(profile.agent[agent], `${file}: ${agent}`);
    }
  }
  assert.equal(personal.command["test-plan"].agent, "orchestrator");
  assert.equal(work.command["test-plan"], undefined);
  assert.equal(work.command["summarize-jira-ticket"].agent, "jira-operator");
  assert.equal(personal.command["summarize-jira-ticket"], undefined);
});

test("chat roles permit discovery but not unapproved shell or edits", () => {
  for (const profile of Object.values(profiles)) {
    const permissions = profile.agent[profile.default_agent].permission;
    assert.equal(permissions["*"], "deny");
    for (const tool of ["read", "glob", "grep"]) assert.equal(permissions[tool], "allow");
    assert.ok(["ask", "deny"].includes(permissions.bash["*"]));
    assert.ok(Object.values(permissions.bash).every((action) => action !== "allow"));
    assert.notEqual(permissions.edit, "allow");
  }
  const prompt = readFileSync(join(root, "prompts/chat.md"), "utf8");
  assert.match(prompt, /only when directly relevant/);
  assert.match(prompt, /read-only access/);
});

test("work audit roles retain bounded delegation and explicit worker mode", () => {
  assert.equal(work.agent["audit-orchestrator"].mode, "primary");
  assert.equal(work.agent["audit-worker"].mode, "subagent");
  assert.deepEqual(work.agent["audit-orchestrator"].permission.task, {
    "*": "deny", "audit-worker": "allow",
  });
  assert.equal(work.agent["audit-worker"].permission.task, "deny");
  for (const name of ["audit-orchestrator", "audit-worker"]) {
    assert.equal(work.agent[name].permission.bash["*"], "ask");
    assert.equal(work.agent[name].permission.bash["git commit*"], "deny");
    assert.equal(work.agent[name].permission.bash["git push*"], "deny");
  }
});

test("Jira summary only exposes approval-gated read operations", () => {
  const permissions = work.agent["jira-operator"].permission;
  assert.equal(permissions["*"], "deny");
  assert.equal(permissions.bash["*"], "deny");
  assert.equal(permissions.atlassian_getJiraIssue, "ask");
  assert.equal(permissions["atlassian_*"], undefined);
  for (const command of ["gh pr list *", "gh pr view *", "gh pr diff *"]) {
    assert.equal(permissions.bash[command], "ask");
  }
});

test("personal planning retains read-only specialists and optional retrospectives", () => {
  const prompt = readFileSync(join(root, "prompts/planner.txt"), "utf8");
  assert.match(prompt, /optional retrospective tool/);
  const { planner, orchestrator, explorer, oracle } = personal.agent;
  assert.equal(planner.permission.submit_plan, "allow");
  for (const denied of ["edit", "write", "task", "bash", "external_directory"]) {
    assert.equal(planner.permission[denied], "deny");
  }
  assert.deepEqual(orchestrator.permission.task, { "*": "deny", explorer: "allow", oracle: "allow" });
  assert.equal(orchestrator.permission.pr_context_get, "allow");
  assert.equal(orchestrator.permission.submit_plan, "allow");
  for (const agent of [orchestrator, explorer, oracle]) {
    for (const denied of ["edit", "write", "apply_patch", "bash", "external_directory"]) {
      assert.equal(agent.permission[denied], "deny");
    }
  }
  assert.equal(explorer.permission.task, "deny");
  assert.equal(oracle.permission.task, "deny");
});

test("test-plan keeps its bounded workflow contract", () => {
  const command = readFileSync(join(root, "prompts/test-plan.md"), "utf8");
  assert.match(command, /Launch only the two discovery stages in parallel/);
  assert.match(command, /fresh `oracle` session/);
  assert.match(command, /one correction pass/);
  assert.match(command, /call `submit_plan`, and stop/);
});

test("Plannotator review and annotation commands remain registered", () => {
  for (const name of ["plannotator-review.md", "plannotator-annotate.md"]) {
    const command = readFileSync(join(root, "commands", name), "utf8");
    assert.match(command, /^---\n/);
    assert.match(command, /Plannotator/);
  }
});
