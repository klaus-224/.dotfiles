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
  const config = parse(readFileSync(join(directory, "opencode.json"), "utf8"));
  const rules = (agent: string, globals = config.permissions) => {
    const md = matter(readFileSync(join(directory, "agents", `${agent}.md`), "utf8"));
    return [...(globals ?? []), ...(config.agents[agent]?.permissions ?? []), ...(md.data.permissions ?? [])] as Rule[];
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
      assert.deepEqual(md.data, {});
      assert.ok(config.agents[id].permissions.length > 0);
      assert.equal(typeof config.agents[id].description, "string");
      assert.equal(config.agents[id].system, undefined);
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

  test("provider allowlists and work model defaults live only in root profiles", () => {
    const work = parse(readFileSync(join(root, "work.jsonc"), "utf8"));
    const personal = parse(readFileSync(join(root, "personal.jsonc"), "utf8"));
    for (const provider of ["openai", "opencode", "github-copilot", "anthropic"]) {
      assert.equal(effect(work.experimental.policies, "provider.use", provider),
        provider === "github-copilot" ? "allow" : "deny");
      assert.equal(effect(personal.experimental.policies, "provider.use", provider),
        ["openai", "opencode"].includes(provider) ? "allow" : "deny");
    }
    assert.equal(config.experimental, undefined);
    assert.equal(config.model, undefined);
    assert.equal(work.model, "github-copilot/gpt-6.1-sol");
    assert.equal(work.agents.chat.model, "github-copilot/claude-sonnet-5.5");
    assert.equal(work.agents.explore.model, "github-copilot/claude-haiku-5.5");
    assert.equal(work.agents.reviewer.model, "github-copilot/gpt-6.1-sol");
    assert.equal(personal.model, undefined);
    assert.ok(!readdirSync(root).includes("personal"));
    assert.ok(!readdirSync(root).includes("work"));
  });

  test(`shared: readonly agents resist a global edit allow and stay out of planning and delegation`, () => {
    for (const id of ["chat", "explore", "reviewer"]) {
      const policy = rules(id, [...config.permissions, { action: "edit", resource: "*", effect: "allow" }]);
      for (const path of ["src/app.ts", ".env.example", "work/report.md"])
        assert.equal(effect(policy, "edit", path), "deny", `${id}: ${path}`);
      for (const [action, resource] of [["subagent", "builder"], ["subagent", "reviewer"], ["submit_plan", "*"]])
        assert.equal(effect(policy, action, resource), "deny", `${id}: ${action} ${resource}`);
      for (const command of ["git status", "git diff --stat", "rtk git log -5", "gh pr diff https://github.com/a/b/pull/1", "ctx7 docs /org/library query"])
        assert.equal(effect(policy, "shell", command), "allow", `${id}: ${command}`);
      assert.equal(effect(policy, "subagent", "explore"), id === "chat" ? "allow" : "deny");
    }
  });

  test(`shared: agents allow routine work while gating dangerous and external operations`, () => {
    for (const id of ["builder", "chat", "explore", "reviewer"]) {
      const policy = rules(id);
      for (const command of ["pnpm test", "pnpm install", "curl https://example.com", "git add src/app.ts", "git commit -m fix", "rtk git status", "gh api repos/a/b/contents/x"])
        assert.equal(effect(policy, "shell", command), "allow", `${id}: ${command}`);
      for (const command of ["sudo ls", "git push", "rtk git push origin main", "git rebase main", "git restore src/app.ts",
        "git commit --amend", "gh pr merge 1", "rtk gh pr comment 1", "gh api --method POST repos/a/b/issues", "rtk gh api -X PATCH repos/a/b"])
        assert.equal(effect(policy, "shell", command), "ask", `${id}: ${command}`);
      for (const command of ["rm -rf build", "git reset --hard", "rtk git clean -fd", "git branch -D topic", "git commit --no-verify -m fix",
        "git push --force", "rtk git push origin -f main", "gh issue delete 1", "rtk gh api --method DELETE repos/a/b", "gh api -X DELETE repos/a/b",
        "cat .env", "cat ~/.aws/credentials"])
        assert.equal(effect(policy, "shell", command), "deny", `${id}: ${command}`);
      assert.equal(effect(policy, "external_directory", "/outside/*"), "ask");
      assert.equal(effect(policy, "atlassian_createJiraIssue", "*"), "ask");
      assert.equal(effect(policy, "playwright_browser_take_screenshot", "*"), "allow");
      for (const path of [".env", "apps/web/.env.local", "/users/person/.ssh/id_ed25519", "/users/person/.config/opencode/auth.json", "certs/server.pem"])
        for (const action of ["read", "edit"])
          assert.equal(effect(policy, action, path), "deny", `${id}: ${action} ${path}`);
      assert.equal(effect(policy, "read", ".env.example"), "allow");
    }
    assert.equal(effect(rules("builder"), "edit", "src/app.ts"), "allow");
    assert.equal(effect(rules("builder"), "edit", ".env.example"), "allow");
  });

  test("shared: writing is available to every agent", () => {
    const skill = matter(readFileSync(join(directory, "skills/writing/SKILL.md"), "utf8"));
    assert.equal(skill.data.name, "writing");
    assert.equal(typeof skill.data.description, "string");
    for (const id of ["builder", "chat", "explore", "reviewer"])
      assert.equal(effect(rules(id), "skill", "writing"), "allow");
    const path = "/users/person/.config/opencode/skills/writing/scripts/render_html.py";
    assert.equal(effect(rules("builder"), "shell", `python3 ${path} work/input.json --output output/result`), "allow");
    assert.equal(effect(rules("builder"), "shell", `python3 ${path} input.json --output /users/person/.aws/credentials`), "deny");
  });

  test(`shared: commands select capable agents and load discoverable exact skill IDs`, () => {
    const commands = readdirSync(join(directory, "shared-commands")).filter(f => f.endsWith(".md"));
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
    assert.equal(commands.includes("bug.md"), false);
    assert.equal(commands.includes("pw-test.md"), false);
    assert.equal(commands.includes("manual-test-plan.md"), false);
    assert.equal(config.mcp, undefined);
    const installedSkills = readdirSync(join(directory, "shared-skills"));
    for (const excluded of ["jira-ticket", "jira-bug", "playwright", "playwright-cli", "manual-test-plan", "manual-testing", "test-planning"])
      assert.equal(installedSkills.includes(excluded), false);
    for (const shared of ["writing", "implementation-plan", "pr-review", "git-workflow", "nix-check"])
      assert.equal(installedSkills.includes(shared), true);
    assert.ok(config.plugins.includes("./plugins/pr-context"));
  });
}
