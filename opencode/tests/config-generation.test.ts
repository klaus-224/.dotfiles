import assert from "node:assert/strict";
import { readFileSync, readdirSync, realpathSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";
import { composeProfile, profiles, renderProfile, root } from "../scripts/generate-config.js";

test("checked-in profiles match their shared sources and selected skill links", () => {
  for (const name of profiles) {
    assert.equal(readFileSync(resolve(root, name, "opencode.jsonc"), "utf8"), renderProfile(name), `${name}: run pnpm config:generate`);
    const { config, skills } = composeProfile(name);
    assert.deepEqual(readdirSync(resolve(root, name, "skills")).sort(), [...skills].sort());
    for (const skill of skills) {
      assert.equal(realpathSync(resolve(root, name, "skills", skill)), realpathSync(resolve(root, "skills", skill)));
    }
    for (const [id, agent] of Object.entries(config.agents ?? {})) {
      if (agent.disabled || !agent.system) continue;
      assert.ok(!agent.system.includes("{file:"), `${id}: unresolved Markdown reference`);
      for (const rule of agent.permissions ?? []) {
        if (rule.action === "skill" && rule.effect === "allow") assert.ok(skills.includes(rule.resource), `${id}: skill ${rule.resource} is not exposed`);
        if (rule.action === "subagent" && rule.effect === "allow") {
          const target = config.agents?.[rule.resource];
          assert.ok(target && !target.disabled, `${id}: unavailable subagent ${rule.resource}`);
          assert.ok(target.mode === "subagent" || target.mode === "all");
        }
      }
    }
  }
});

test("work exposes only Jira and Playwright workflows", () => {
  const { config, skills } = composeProfile("work");
  assert.deepEqual(Object.entries(config.agents ?? {}).filter(([, agent]) => !agent.disabled).map(([id]) => id).sort(), [
    "Jira", "playwright-user", "pr-review", "pw-test-writer", "test-planner", "ticket-review",
  ]);
  for (const id of ["general", "build", "plan"]) assert.equal(config.agents?.[id].disabled, true);
  assert.equal(config.default_agent, "ticket-review");
  assert.equal(config.references, undefined);
  assert.equal(config.lsp, undefined);
  assert.deepEqual(config.plugins, ["./plugins/rtk"]);
  assert.deepEqual(skills, ["find-docs", "manual-test-plan", "playwright-cli"]);
  assert.deepEqual(Object.keys(config.commands ?? {}), ["bug", "test-plan"]);
  assert.equal(config.commands?.["test-plan"].agent, "ticket-review");
  assert.equal(config.commands?.bug.agent, "Jira");
  assert.ok(config.commands?.bug.template.includes('decision: "approved"'));
  assert.ok(config.commands?.["test-plan"].template.includes("$ARGUMENTS"));
  for (const agent of Object.values(config.agents ?? {})) {
    if (agent.model) assert.ok(typeof agent.model === "string" && agent.model.startsWith("github-copilot/"));
  }
});

test("personal retains its agents, model choices, and plugin ordering", () => {
  const { config } = composeProfile("personal");
  assert.equal(config.default_agent, "chat");
  assert.equal(config.agents?.planner.model, "openai/gpt-6-astra#high");
  assert.equal(config.agents?.builder.model, "openai/gpt-5.6-sol#medium");
  assert.equal(config.agents?.["audit-worker"].mode, "subagent");
  assert.deepEqual(config.plugins?.slice(0, 2), ["./plugins/rtk", "./plugins/pr-context"]);
  assert.equal(config.mcp, undefined);
  assert.equal(config.agents?.["ticket-review"], undefined);
  assert.equal(config.agents?.["playwright-user"], undefined);
});
