import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, symlinkSync, readlinkSync, lstatSync, readdirSync, rmSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import test from "node:test";

const switcher = fileURLToPath(new URL("../../zsh/.zshrc.d/opencode-profile.zsh", import.meta.url));
function fixture() {
  const root = mkdtempSync(path.join(tmpdir(), "opencode-profile-"));
  const dotfiles = path.join(root, "dotfiles with spaces");
  const source = path.join(dotfiles, "opencode");
  const config = path.join(root, "config with spaces");
  const destination = path.join(config, "opencode");
  mkdirSync(source, { recursive: true });
  for (const name of ["opencode.json", "work.jsonc", "personal.jsonc"]) writeFileSync(path.join(source, name), "{}\n");
  for (const name of ["agents", "shared-commands", "shared-skills"]) mkdirSync(path.join(source, name));
  const environment = { ...process.env };
  delete environment.NODE_TEST_CONTEXT;
  const run = (args = ["work"], extraEnv: Record<string, string> = {}, suffix = "") => spawnSync("zsh", ["-f", "-c", 'source "$1"; shift; opencode-profile "$@"' + suffix, "test", switcher, ...args], {
    env: { ...environment, DOTFILES_HOME: dotfiles, XDG_CONFIG_HOME: config, ...extraEnv }, encoding: "utf8",
  });
  const snapshot = () => existsSync(destination) ? Object.fromEntries(readdirSync(destination).map(name => [name, lstatSync(path.join(destination, name)).isSymbolicLink() ? readlinkSync(path.join(destination, name)) : "regular"])) : {};
  return { root, dotfiles, source, config, destination, run, snapshot, cleanup: () => rmSync(root, { recursive: true, force: true }) };
}

test("work/personal/work changes only the profile link and preserves unrelated state", () => {
  const f = fixture();
  try {
    mkdirSync(f.destination, { recursive: true });
    writeFileSync(path.join(f.destination, "service.json"), "runtime state");
    mkdirSync(path.join(f.source, "shared-plugins"));
    writeFileSync(path.join(f.source, "cli.json"), "{}");
    assert.equal(f.run().status, 0);
    const first = f.snapshot();
    const inode = lstatSync(path.join(f.destination, "agents")).ino;
    assert.equal(f.run(["personal"]).status, 0);
    assert.deepEqual(f.snapshot(), { ...first, "opencode.jsonc": path.join(f.source, "personal.jsonc") });
    assert.equal(lstatSync(path.join(f.destination, "agents")).ino, inode);
    assert.equal(f.run().status, 0);
    assert.deepEqual(f.snapshot(), first);
    assert.equal(lstatSync(f.destination).isSymbolicLink(), false);
    assert.equal(readdirSync(f.source).some(name => name === "opencode.jsonc"), false);
  } finally { f.cleanup(); }
});

test("rejects invalid arguments before touching the destination", () => {
  const f = fixture();
  try {
    for (const args of [[], ["other"], ["work", "personal"]]) assert.equal(f.run(args).status, 2);
    assert.equal(existsSync(f.destination), false);
  } finally { f.cleanup(); }
});

const failures: Array<[string, (f: ReturnType<typeof fixture>) => void]> = [
  ["missing unselected profile", f => rmSync(path.join(f.source, "personal.jsonc"))],
  ["symlinked shared source directory", f => { rmSync(path.join(f.source, "agents"), { recursive: true }); symlinkSync("shared-commands", path.join(f.source, "agents")); }],
  ["symlinked optional CLI source", f => symlinkSync("work.jsonc", path.join(f.source, "cli.json"))],
  ["source profile linked back to the installed profile", f => { rmSync(path.join(f.source, "work.jsonc")); symlinkSync(path.join(f.destination, "opencode.jsonc"), path.join(f.source, "work.jsonc")); }],
  ["nested dangling source link", f => symlinkSync("missing", path.join(f.source, "agents", "bad.md"))],
  ["nested symlink resolution loop", f => { symlinkSync("b", path.join(f.source, "agents", "a")); symlinkSync("a", path.join(f.source, "agents", "b")); }],
  ["nested directory ancestor cycle", f => symlinkSync(".", path.join(f.source, "agents", "cycle"))],
  ["nested directory cross cycle", f => { symlinkSync("../shared-skills", path.join(f.source, "agents", "skills")); symlinkSync("../agents", path.join(f.source, "shared-skills", "agents")); }],
  ["nested link outside source", f => symlinkSync(f.root, path.join(f.source, "agents", "outside"))],
  ["nested link through an installed link back to source", f => symlinkSync(path.join(f.destination, "agents"), path.join(f.source, "agents", "installed"))],
  ["intermediate source link outside the root", f => { symlinkSync(f.source, path.join(f.root, "alias")); symlinkSync(path.join(f.root, "alias", "shared-commands"), path.join(f.source, "agents", "alias")); }],
  ["regular destination file", f => { rmSync(path.join(f.destination, "opencode.jsonc")); writeFileSync(path.join(f.destination, "opencode.jsonc"), "local config"); }],
  ["regular destination directory", f => { rmSync(path.join(f.destination, "agents")); mkdirSync(path.join(f.destination, "agents")); }],
];
for (const [name, breakFixture] of failures) test(`preflight preserves links when rejecting ${name}`, () => {
  const f = fixture();
  try {
    assert.equal(f.run().status, 0);
    breakFixture(f);
    const before = f.snapshot();
    const result = f.run(["personal"]);
    assert.equal(result.status, 1, result.stdout + result.stderr);
    assert.match(result.stdout + result.stderr, /opencode-profile:/);
    assert.deepEqual(f.snapshot(), before);
  } finally { f.cleanup(); }
});

test("refuses a whole destination directory symlink without writing into its target", () => {
  const f = fixture();
  try {
    mkdirSync(f.config);
    symlinkSync(f.source, f.destination);
    const before = readdirSync(f.source);
    assert.equal(f.run().status, 1);
    assert.deepEqual(readdirSync(f.source), before);
    assert.equal(readlinkSync(f.destination), f.source);
  } finally { f.cleanup(); }
});

test("rejects a symlinked source root", () => {
  const f = fixture();
  try {
    const alias = path.join(f.root, "alias-dotfiles");
    mkdirSync(alias);
    symlinkSync(f.source, path.join(alias, "opencode"));
    assert.equal(f.run(["work"], { DOTFILES_HOME: alias }).status, 1);
    assert.equal(existsSync(f.destination), false);
  } finally { f.cleanup(); }
});

test("a late optional entry conflict leaves all installed entries untouched", () => {
  const f = fixture();
  try {
    mkdirSync(f.destination, { recursive: true });
    mkdirSync(path.join(f.source, "shared-plugins"));
    mkdirSync(path.join(f.destination, "plugins"));
    const before = f.snapshot();
    assert.equal(f.run().status, 1);
    assert.deepEqual(f.snapshot(), before);
  } finally { f.cleanup(); }
});

test("canonical parent aliases cannot hide identical or nested roots", () => {
  const f = fixture();
  try {
    symlinkSync(f.dotfiles, f.config);
    assert.equal(f.run().status, 1);
    assert.equal(f.run(["work"], { XDG_CONFIG_HOME: f.source }).status, 1);
  } finally { f.cleanup(); }
});

test("rejects a destination containing the source", () => {
  const f = fixture();
  try {
    const nested = path.join(f.root, "opencode", "dotfiles");
    mkdirSync(path.join(nested, "opencode"), { recursive: true });
    assert.equal(f.run(["work"], { XDG_CONFIG_HOME: f.root, DOTFILES_HOME: nested }).status, 1);
  } finally { f.cleanup(); }
});

test("accepts contained acyclic nested links and removes inherited config overrides", () => {
  const f = fixture();
  try {
    mkdirSync(path.join(f.source, "skills"));
    writeFileSync(path.join(f.source, "skills", "SKILL.md"), "---\nname: shared\n---\nbody");
    symlinkSync("../skills", path.join(f.source, "shared-skills", "shared"));
    const result = f.run(["personal"], { OPENCODE_CONFIG: "/obsolete", OPENCODE_CONFIG_CONTENT: "{}" }, '; result=$?; [[ -z ${OPENCODE_CONFIG+x} && -z ${OPENCODE_CONFIG_CONTENT+x} ]] || exit 9; exit $result');
    assert.equal(result.status, 0, result.stderr);
  } finally { f.cleanup(); }
});
