import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { parse } from "jsonc-parser";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

function readJsonc(name: string): Record<string, any> {
  const errors: { error: number; offset: number; length: number }[] = [];
  const value = parse(readFileSync(join(root, name), "utf8"), errors, {
    allowTrailingComma: true,
    disallowComments: false,
  });
  assert.deepEqual(errors, [], `${name} must be valid JSONC`);
  return value;
}

const profiles = [
  ["work", readJsonc("opencode.work.jsonc")],
  ["personal", readJsonc("opencode.personal.jsonc")],
] as const;

test("both profiles pin the target before user-managed Plannotator", () => {
  for (const [name, profile] of profiles) {
    assert.equal(profile.default_agent, "pair-programmer", `${name} default agent`);
    assert.equal(profile.permission.webfetch, "deny");
    assert.equal(profile.permission.external_directory, "deny");
    assert.equal(profile.plugin[0], "oh-my-openagent@4.19.4");
    assert.equal(profile.plugin[1][0], "@plannotator/opencode@0.27.12");
    assert.equal(profile.plugin[1][1].workflow, "user-managed");
    assert.deepEqual(profile.plugin[1][1].planningAgents, ["planner", "orchestrator"]);
  }
});

test("work and personal provider/MCP isolation is unchanged", () => {
  const work = profiles[0][1];
  const personal = profiles[1][1];

  assert.deepEqual(work.enabled_providers, ["github-copilot"]);
  assert.deepEqual(work.disabled_providers, ["opencode", "openai"]);
  assert.equal(work.mcp.atlassian.enabled, true);

  assert.deepEqual(personal.enabled_providers, ["openai", "opencode"]);
  assert.equal(personal.mcp, undefined);
});

test("planner is read-only and compound analysis remains optional", () => {
  const prompt = readFileSync(join(root, "prompts/planner.txt"), "utf8");
  assert.match(prompt, /optional retrospective tool/);
  assert.doesNotMatch(prompt, /Always load the plannotator-compound skill/);

  for (const [, profile] of profiles) {
    const planner = profile.agent.planner;
    assert.equal(planner.permission.submit_plan, "allow");
    for (const denied of ["edit", "write", "task", "bash", "external_directory"]) {
      assert.equal(planner.permission[denied], "deny", `planner must deny ${denied}`);
    }
  }
});

test("repository-owned planning specialists retain narrow permissions", () => {
  for (const [, profile] of profiles) {
    const { orchestrator, explorer, oracle } = profile.agent;
    assert.deepEqual(orchestrator.permission.task, {
      "*": "deny",
      explorer: "allow",
      oracle: "allow",
    });
    assert.equal(orchestrator.permission.pr_context_get, "allow");
    assert.equal(orchestrator.permission.submit_plan, "allow");

    for (const agent of [orchestrator, explorer, oracle]) {
      for (const denied of ["edit", "write", "apply_patch", "bash", "external_directory"]) {
        assert.equal(agent.permission[denied], "deny", `${agent.description} must deny ${denied}`);
      }
    }
    assert.equal(explorer.permission.task, "deny");
    assert.equal(oracle.permission.task, "deny");
  }
});

test("target config is pinned to a passive, provider-neutral integration", () => {
  const config = readJsonc("omo.jsonc");
  const target = config["[opencode]"];

  assert.match(config.$schema, /b072d279110bdda2c6ac2525d0d24dc54d16148a/);
  assert.deepEqual(Object.keys(config.profiles).sort(), ["personal", "work"]);
  assert.equal(target.auto_update, false);
  assert.equal(target.telemetry, false);
  assert.equal(target.sisyphus_agent.disabled, true);
  assert.equal(target.sisyphus_agent.replace_plan, false);
  assert.equal(target.experimental.task_system, false);
  assert.equal(target.team_mode.enabled, false);
  assert.equal(target.codegraph.enabled, false);
  assert.equal(target.disabled_agents.includes("oracle"), true);
  assert.equal(target.disabled_agents.includes("explore"), true);
  assert.equal(target.disabled_mcps.includes("websearch"), true);
  for (const skill of [
    "security-research",
    "security-review",
    "ast-grep",
    "coding-agent-sessions",
    "data-scientist",
    "debugging",
    "frontend",
    "git-master",
    "init-deep",
    "lsp-setup",
    "programming",
    "refactor",
    "remove-ai-slops",
    "review-work",
    "start-work",
    "ultimate-browsing",
    "ulw-plan",
    "ulw-research",
    "visual-qa",
  ]) {
    assert.equal(target.disabled_skills.includes(skill), true, `target skill ${skill} disabled`);
  }
  assert.equal("agents" in target, false);
  assert.equal("categories" in target, false);
});

test("test-plan keeps its bounded workflow contract", () => {
  const command = readFileSync(join(root, "commands/test-plan.md"), "utf8");
  assert.match(command, /agent: orchestrator/);
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

test("shell profile selection uses OMO profiles without experimental subagents", () => {
  const shell = readFileSync(join(root, "../zsh/.zshenv"), "utf8");
  assert.match(shell, /OMO_PROFILE="personal"/);
  assert.match(shell, /OMO_PROFILE="work"/);
  assert.doesNotMatch(shell, /OH_MY_OPENCODE_SLIM_PRESET/);
  assert.doesNotMatch(shell, /OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS/);
});
