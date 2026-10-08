import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import matter from "gray-matter";
import { Schema } from "effect";
import { parse } from "jsonc-parser";
import { ConfigAgent } from "@opencode/schema/config/agent";
import { ConfigCommand } from "@opencode/schema/config/command";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
type Rule = { action: string; resource: string; effect: "allow" | "ask" | "deny" };

// Static policy fixtures follow the pinned V2 whole-value wildcard/last-match
// contract. They do not exercise shell scanning, saved approvals, or live tools.
function match(input: string, pattern: string) {
  let escaped = pattern.replaceAll("\\", "/")
    .replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".");
  if (escaped.endsWith(" .*")) escaped = escaped.slice(0, -3) + "( .*)?";
  return new RegExp("^" + escaped + "$", "s").test(input.replaceAll("\\", "/"));
}
function effect(rules: Rule[], action: string, resource: string) {
  return [...rules].reverse().find(r => match(action, r.action) && match(resource, r.resource))?.effect ?? "ask";
}

{
  const directory = root;
  const config = parse(readFileSync(join(directory, "opencode.jsonc"), "utf8"));
  const rules = (agent: string, globals = config.permissions) => {
    const md = matter(readFileSync(join(directory, "agents", `${agent}.md`), "utf8"));
    return [...globals, ...(md.data.permissions ?? [])] as Rule[];
  };

  test(`shared: discovered agents have shared permissions and no stale primary`, () => {
    assert.equal(config.default_agent, "builder");
    assert.deepEqual(readdirSync(join(directory, "agents")).sort(),
      ["builder.md", "chat.md", "explore.md", "reviewer.md"]);
    for (const id of ["builder", "chat", "explore", "reviewer"]) {
      const md = matter(readFileSync(join(directory, "agents", `${id}.md`), "utf8"));
      const entry = { ...config.agents[id], ...md.data, system: md.content.trim(), permissions: rules(id) };
      assert.doesNotThrow(() => Schema.decodeUnknownSync(ConfigAgent.Info)(entry));
      assert.equal(entry.mode, ["builder", "chat"].includes(id) ? "primary" : "subagent");
      assert.equal(entry.hidden ?? false, false);
      assert.ok(entry.system.length > 100);
      assert.equal(entry.model, undefined);
      assert.ok(md.data.permissions.length > 0);
      assert.equal(config.agents[id], undefined);
    }
    assert.equal(config.agents.build.disabled, true);
    assert.equal(config.agents.plan.disabled, true);
    for (const old of ["explorer", "planner", "ticket-review", "pr-review", "test-planner", "Jira", "audit-worker", "audit-orchestrator"])
      assert.equal(config.agents[old], undefined);
    assert.ok(config.plugins.includes("./plugins/rtk"));
    const plannotator = config.plugins.find((p: any) => p.package?.startsWith("@plannotator/"));
    assert.equal(plannotator.package, "@plannotator/opencode@0.27.22");
    assert.equal(plannotator.options.workflow, "user-managed");
    assert.equal(effect(rules("builder"), "submit_plan", "*"), "allow");
    assert.equal(effect(rules("builder"), "skill", "implementation-plan"), "allow");
    assert.equal(effect(rules("builder"), "subagent", "builder"), "deny");
    assert.equal(effect(rules("builder"), "subagent", "explore"), "allow");
    assert.equal(effect(rules("builder"), "subagent", "reviewer"), "allow");
  });

  test("provider allowlists are the only machine-specific settings", () => {
    const configs = [["github-copilot", "github-copilot"], ["openai", "opencode"]].map(providers =>
      parse(readFileSync(join(root, "opencode.jsonc"), "utf8")
        .replaceAll("@primary-provider@", providers[0])
        .replaceAll("@secondary-provider@", providers[1])));
    for (const provider of ["openai", "opencode", "github-copilot", "anthropic"]) {
      assert.equal(effect(configs[0].experimental.policies, "provider.use", provider),
        provider === "github-copilot" ? "allow" : "deny");
      assert.equal(effect(configs[1].experimental.policies, "provider.use", provider),
        ["openai", "opencode"].includes(provider) ? "allow" : "deny");
    }
    delete configs[0].experimental;
    delete configs[1].experimental;
    assert.deepEqual(configs[0], configs[1]);
    assert.ok(!readdirSync(root).includes("personal"));
    assert.ok(!readdirSync(root).includes("work"));
  });

  test(`shared: readonly agents resist a global edit allow and deny mutation routes`, () => {
    for (const id of ["chat", "explore", "reviewer"]) {
      const policy = rules(id, [...config.permissions, { action: "edit", resource: "*", effect: "allow" }]);
      for (const path of ["src/app.ts", ".env.example", "work/report.md"])
        assert.equal(effect(policy, "edit", path), "deny", `${id}: ${path}`);
      for (const [action, resource] of [
        ["shell", "pnpm test"], ["shell", "npm install"],
        ["shell", "git add src/app.ts"], ["shell", "rtk git commit -m fix"],
        ["shell", "git diff --output=/tmp/result"],
        ["shell", "gh api --method GET repos/a/b/contents/test -X POST"],
        ["subagent", "builder"], ["subagent", "reviewer"],
        ["atlassian_createJiraIssue", "*"], ["playwright_browser_take_screenshot", "*"],
        ["submit_plan", "*"], ["external_directory", "/outside/*"],
      ]) assert.equal(effect(policy, action, resource), "deny", `${id}: ${action} ${resource}`);
      for (const command of ["git status", "git diff --stat", "rtk git log -5", "gh pr diff https://github.com/a/b/pull/1", "ctx7 docs /org/library query"])
        assert.equal(effect(policy, "shell", command), "allow", `${id}: ${command}`);
      assert.equal(effect(policy, "subagent", "explore"), id === "chat" ? "allow" : "deny");
    }
  });

  test(`shared: builder allows routine work while keeping external and credential gates`, () => {
    const policy = rules("builder");
    for (const command of ["pnpm test", "pnpm test:schema", "pnpm build", "pnpm typecheck", "git add src/app.ts", "git commit -m fix", "rtk git status"])
      assert.equal(effect(policy, "shell", command), "allow", command);
    for (const command of ["pnpm install", "curl https://example.com", "playwright-cli open https://example.com"])
      assert.equal(effect(policy, "shell", command), "ask", command);
    for (const command of ["git push", "rtk git push origin main", "git reset --hard", "git add -A", "git commit --amend", "gh pr merge 1", "gh issue delete 1"])
      assert.equal(effect(policy, "shell", command), "deny", command);
    assert.equal(effect(policy, "edit", "src/app.ts"), "allow");
    assert.equal(effect(policy, "external_directory", "/outside/*"), "ask");
    for (const id of ["builder", "chat", "explore", "reviewer"]) {
      for (const path of [".env", "apps/web/.env.local", "/users/person/.ssh/id_ed25519", "/users/person/.config/opencode/auth.json"])
        assert.equal(effect(rules(id), "read", path), "deny", `${id}: ${path}`);
      assert.equal(effect(rules(id), "read", ".env.example"), "allow");
    }
    const expected = "ask";
    assert.equal(effect(policy, "atlassian_createJiraIssue", "*"), expected);
    assert.equal(effect(policy, "playwright_browser_take_screenshot", "*"), expected);
  });

  test(`shared: commands select capable agents and load discoverable exact skill IDs`, () => {
    const commands = readdirSync(join(directory, "commands")).filter(f => f.endsWith(".md"));
    for (const file of commands) {
      const md = matter(readFileSync(join(directory, "commands", file), "utf8"));
      assert.doesNotThrow(() => Schema.decodeUnknownSync(ConfigCommand.Info)({ ...md.data, template: md.content.trim() }));
      const expectedAgent = file === "pw-review.md" ? "reviewer" : "builder";
      assert.equal(md.data.agent, expectedAgent);
      assert.ok(md.content.includes("$ARGUMENTS"));
      assert.ok(!md.content.includes("!`"), "commands must not execute shell substitutions");
      const skillIDs = [...md.content.matchAll(/`([a-z][a-z-]+)`/g)].map(m => m[1]);
      for (const id of skillIDs) {
        if (["builder", "reviewer"].includes(id)) continue;
        const skill = matter(readFileSync(join(directory, "skills", id, "SKILL.md"), "utf8"));
        assert.equal(typeof skill.data.description, "string");
        assert.ok(skill.content.trim());
        assert.equal(effect(rules(expectedAgent), "skill", id), "allow", `${file}: ${id}`);
      }
    }
    for (const id of ["jira-ticket", "jira-bug"]) {
      assert.equal(readdirSync(join(directory, "skills")).includes(id), true);
    }
    assert.equal(commands.includes("bug.md"), true);
    assert.equal(!!config.mcp?.servers?.atlassian, true);
    assert.equal(config.mcp.servers.playwright.disabled, true);
    assert.ok(config.plugins.includes("./plugins/pr-context"));
  });
}
