import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync, existsSync, statSync } from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import test from "node:test";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const scratch = mkdtempSync(join(process.env.AUDIT_TEST_TMPDIR ?? tmpdir(), "git-terminal-"));
// Retain isolated fixtures for inspection; never initialize a Git repository.
const bin = join(scratch, "bin");
mkdirSync(bin);
const project = join(scratch, "project with 'quotes' and $dollars");
mkdirSync(project);
const log = join(scratch, "calls.jsonl");
const mock = `#!${process.execPath}
const fs = require('node:fs');
const name = require('node:path').basename(process.argv[1]);
const args = process.argv.slice(2);
fs.appendFileSync(process.env.CALL_LOG, JSON.stringify({name, args}) + '\\n');
switch (name) {
  case 'git':
    if (args[0] !== '-C' || args.slice(2).join(' ') !== 'remote get-url origin') process.exit(99);
    if (process.env.GIT_FAIL) process.exit(1);
    console.log(process.env.ORIGIN); break;
  case 'tmux':
    if (args[0] === 'display-message') {
      if (process.env.TMUX_FAIL) process.exit(1);
      console.log(process.env.PANE_CWD);
    } else if (args[0] === 'has-session') process.exit(process.env.SESSION_EXISTS ? 0 : 1);
    else if (args[0] === 'new-session' && process.env.NEW_FAIL) process.exit(1);
    break;
  case 'fd': console.log(process.env.PANE_CWD); break;
  case 'fzf':
    fs.readFileSync(0);
    if (process.env.FZF_STATUS) process.exit(Number(process.env.FZF_STATUS));
    console.log(process.env.PANE_CWD); break;
  case 'open': if (process.env.OPEN_FAIL) process.exit(1); break;
  case 'nvim': break;
  default: process.exit(99);
}
`;
for (const name of ["git", "tmux", "fd", "fzf", "open", "nvim"]) {
  writeFileSync(join(bin, name), mock, { mode: 0o700 });
}
const env = {
  PATH: `${bin}:/usr/bin:/bin`, HOME: scratch, CALL_LOG: log,
  PANE_CWD: project, ORIGIN: "git@github.com:example/widgets.git", TMUX_PANE: "%42",
  LC_ALL: "C",
};
function run(file, args = [], input = "", overrides = {}) {
  writeFileSync(log, "");
  const result = spawnSync(file.startsWith("git/") ? "/bin/sh" : "/bin/bash", [join(root, file), ...args], {
    cwd: root, env: { ...env, ...overrides }, input, encoding: "utf8",
  });
  assert.ifError(result.error);
  return { ...result, calls: readFileSync(log, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse) };
}
const oid = "1".repeat(40);
const zero = "0".repeat(40);
const ref = (destination, source = "refs/heads/local-name", local = oid, remote = zero) =>
  `${source} ${local} ${destination} ${remote}\n`;

test("pre-push checks destination branches, independent of HEAD or source", () => {
  for (const branch of ["main", "develop", ...["feat", "fix", "docs", "style", "refactor", "test", "chore"].map(t => `${t}/lowercase-1.2_name`)]) {
    for (const source of ["refs/heads/Invalid", "HEAD", oid, "HEAD~"]) {
      const result = run("git/hooks/pre-push", ["origin", "unused"], ref(`refs/heads/${branch}`, source));
      assert.equal(result.status, 0, result.stderr);
      assert.deepEqual(result.calls, [], "must not query HEAD or execute Git");
    }
  }
  for (const branch of ["Invalid", "feat/Uppercase", "ci/check", "nix/check", "feat/", "feat/a/b"]) {
    const result = run("git/hooks/pre-push", [], ref(`refs/heads/${branch}`, "refs/heads/feat/valid"));
    assert.equal(result.status, 1);
    assert.match(result.stderr, /Invalid destination branch/);
  }
});

test("pre-push supports tags, deletion, empty input, SHA-256 and multiple refs", () => {
  const exempt = ref("refs/tags/v1.0") + ref("refs/notes/commits") + ref("refs/heads/OldName", "(delete)", zero);
  for (const input of ["", exempt, ref("refs/heads/OldName", "(delete)", "0".repeat(64)), ref("refs/heads/fix/a", "HEAD", "a".repeat(64)), exempt + ref("refs/heads/fix/a")]) {
    assert.equal(run("git/hooks/pre-push", [], input).status, 0);
  }
  const result = run("git/hooks/pre-push", [], ref("refs/heads/BadFirst") + exempt + ref("refs/heads/BadLast"));
  assert.equal(result.status, 1);
  assert.match(result.stderr, /BadFirst/);
  assert.match(result.stderr, /BadLast/);
  assert.equal(run("git/hooks/pre-push", [], "malformed input\n").status, 1);
});

test("commit subjects and template agree without creating any commits", () => {
  const message = join(scratch, "message with spaces");
  const types = readFileSync(join(root, "git/commit-template"), "utf8").match(/# Types: (.*)/)[1].split(", ");
  assert.deepEqual(types, ["feat", "fix", "docs", "style", "refactor", "test", "chore"]);
  for (const type of types) {
    for (const subject of [`${type}: summary`, `${type}(api.v2)!: preserve \\n literally`]) {
      writeFileSync(message, subject);
      const result = run("git/hooks/commit-msg", [message]);
      assert.equal(result.status, 0, result.stderr);
      assert.equal(readFileSync(message, "utf8"), subject);
      assert.deepEqual(result.calls, []);
    }
  }
  for (const subject of ["", "fix: ", "fix:    ", "nix: unsupported", "ci: unsupported", "fix(API): uppercase scope", "feat:no space", "fix: \nfeat: valid second line"]) {
    writeFileSync(message, subject);
    assert.equal(run("git/hooks/commit-msg", [message]).status, 1, subject);
  }
  assert.equal(run("git/hooks/commit-msg", []).status, 1);
  assert.equal(run("git/hooks/commit-msg", [join(scratch, "missing")]).status, 1);
});

test("Git config resolves matching mergetool and preserves argument quoting", () => {
  function config(key) {
    // Explicit file + no includes: never read installed user credentials/config.
    const result = spawnSync("git", ["config", "--file", join(root, "git/.gitconfig"), "--no-includes", "--get", key], {
      cwd: root, encoding: "utf8", env: { PATH: process.env.PATH, HOME: scratch, GIT_CONFIG_NOSYSTEM: "1", GIT_CONFIG_GLOBAL: "/dev/null" },
    });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  }
  assert.equal(config("merge.tool"), "nvim_diff");
  assert.equal(config("mergetool.nvim.trustExitCode"), "false");
  assert.equal(config("core.hooksPath"), "~/.dotfiles/git/hooks");
  const cmd = config("mergetool.nvim.cmd");
  assert.equal(cmd, 'nvim -d "$LOCAL" "$BASE" "$REMOTE" "$MERGED"');
  writeFileSync(log, "");
  const files = { LOCAL: "local with spaces", BASE: "base 'quote'", REMOTE: "$literal remote", MERGED: "merged;not-a-command" };
  const result = spawnSync("/bin/sh", ["-c", cmd], { cwd: root, env: { ...env, ...files }, encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(JSON.parse(readFileSync(log, "utf8")).args, ["-d", ...Object.values(files)]);
});

test("GitHub helper queries current pane cwd and normalizes supported remotes", () => {
  for (const origin of ["git@github.com:example/widgets.git", "ssh://git@github.com/example/widgets.git", "https://github.com/example/widgets.git", "https://github.com/example/widgets"]) {
    const result = run("scripts/open-github.sh", ["%7"], "", { ORIGIN: origin });
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(result.calls, [
      { name: "tmux", args: ["display-message", "-p", "-t", "%7", "#{pane_current_path}"] },
      { name: "git", args: ["-C", project, "remote", "get-url", "origin"] },
      { name: "open", args: ["https://github.com/example/widgets"] },
    ]);
  }
  assert.equal(run("scripts/open-github.sh").calls[0].args[3], "%42");
});

test("GitHub helper refuses invalid origins and stops on failures", () => {
  for (const overrides of [
    { TMUX_FAIL: "1" }, { PANE_CWD: join(scratch, "missing") }, { GIT_FAIL: "1" },
    ...["https://github.com.evil/example/repo", "https://evil/github.com/repo", "https://user:secret@github.com/owner/repo", "https://github.com/owner/repo?token=x", "git@github.com:owner/repo;evil", "https://github.com/owner/..", "https://github.com/../repo"].map(ORIGIN => ({ ORIGIN })),
  ]) {
    const result = run("scripts/open-github.sh", [], "", overrides);
    assert.equal(result.status, 1);
    assert.ok(!result.calls.some(call => call.name === "open"));
  }
  assert.equal(run("scripts/open-github.sh", [], "", { OPEN_FAIL: "1" }).status, 1);
  assert.equal(run("scripts/open-github.sh", [], "", { TMUX_PANE: "" }).status, 1);
});

test("session helper uses fzf, quotes paths and does not switch after failed creation", () => {
  const result = run("scripts/tmux-session-dispensary.sh");
  assert.equal(result.status, 0, result.stderr);
  assert.ok(result.calls.some(call => call.name === "fzf"));
  assert.deepEqual(result.calls.find(call => call.args[0] === "new-session").args.slice(-2), ["-c", project]);
  const existing = run("scripts/tmux-session-dispensary.sh", [project], "", { SESSION_EXISTS: "1" });
  assert.equal(existing.status, 0);
  assert.ok(!existing.calls.some(call => ["fd", "fzf"].includes(call.name) || call.args[0] === "new-session"));
  const failed = run("scripts/tmux-session-dispensary.sh", [project], "", { NEW_FAIL: "1" });
  assert.equal(failed.status, 1);
  assert.ok(!failed.calls.some(call => call.args[0] === "switch-client"));
  for (const status of ["1", "130"]) {
    const cancelled = run("scripts/tmux-session-dispensary.sh", [], "", { FZF_STATUS: status });
    assert.equal(cancelled.status, 0);
    assert.ok(!cancelled.calls.some(call => call.name === "tmux"));
  }
  assert.equal(run("scripts/tmux-session-dispensary.sh", [], "", { FZF_STATUS: "2" }).status, 2);
  assert.equal(run("scripts/tmux-session-dispensary.sh", [join(scratch, "missing")]).status, 1);
});

test("tmux clipboard and terminal settings are correct without touching a server", () => {
  const text = readFileSync(join(root, "tmux/.tmux.conf"), "utf8");
  assert.match(text, /^set -g default-terminal "tmux-256color"$/m);
  assert.doesNotMatch(text, /^set.*terminal-features/m);
  assert.match(text, /copy-pipe-and-cancel "pbcopy"/);
  assert.doesNotMatch(text, /xclip|pane_start_path/);
  assert.match(text, /open-github\.sh #\{pane_id\}/);
  for (const file of ["scripts/open-github.sh", "scripts/tmux-session-dispensary.sh", "git/hooks/pre-push", "git/hooks/commit-msg"]) {
    assert.ok(existsSync(join(root, file)));
    assert.ok(statSync(join(root, file)).mode & 0o100, `${file} must remain executable`);
  }
});
