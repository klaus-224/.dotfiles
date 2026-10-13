# Define during startup; select a profile explicitly. Requires the existing Node runtime.
function opencode-profile() {
  emulate -L zsh
  if (( $# != 1 )) || [[ "$1" != (work|personal) ]]; then
    print -u2 -- 'Usage: opencode-profile work|personal'
    return 2
  fi
  if ! (( $+commands[node] )); then
    print -u2 -- 'opencode-profile: node is required for strict symlink validation'
    return 1
  fi
  command node - "${DOTFILES_HOME:-$HOME/.dotfiles}/opencode" \
    "${XDG_CONFIG_HOME:-$HOME/.config}/opencode" "$1" <<'JS'
const fs = require('node:fs');
const path = require('node:path');
const [sourceInput, destinationInput, profile] = process.argv.slice(2);
const fail = (message) => { throw new Error(message); };
const stat = (file) => {
  try { return fs.lstatSync(file); }
  catch (error) { if (error.code === 'ENOENT') return; throw error; }
};
const real = (file) => {
  try { return fs.realpathSync(file); }
  catch (error) { fail(`cannot strictly resolve ${file}: ${error.message}`); }
};
const inside = (root, file) => file === root || file.startsWith(root + path.sep);
// Canonicalize existing parents without creating missing destination directories.
const canonical = (file) => stat(file) ? real(file)
  : path.join(canonical(path.dirname(file)), path.basename(file));
const requireReal = (file, directory) => {
  const info = stat(file);
  if (!info || info.isSymbolicLink() || !(directory ? info.isDirectory() : info.isFile()))
    fail(`expected a real ${directory ? 'directory' : 'file'}: ${file}`);
};
try {
  const sourcePath = path.resolve(sourceInput);
  const destinationPath = path.resolve(destinationInput);
  requireReal(sourcePath, true);
  const destinationInfo = stat(destinationPath);
  if (destinationInfo) requireReal(destinationPath, true);
  const source = real(sourcePath);
  const destination = canonical(destinationPath);
  if (inside(source, destination) || inside(destination, source))
    fail(`source and destination overlap: ${source} / ${destination}`);
  for (const name of ['opencode.json', 'work.jsonc', 'personal.jsonc'])
    requireReal(path.join(source, name), false);
  const planned = new Map([
    ['opencode.json', path.join(source, 'opencode.json')],
    ['agents', path.join(source, 'agents')],
    ['commands', path.join(source, 'commands')],
    // Originals include excluded Jira/PW assets; install only the curated library.
    ['skills', path.join(source, 'shared-skills')],
  ]);
  for (const name of ['plugins', 'cli.json', 'opencode.schema.json']) {
    if (stat(path.join(source, name))) planned.set(name, path.join(source, name));
  }
  planned.set('opencode.jsonc', path.join(source, `${profile}.jsonc`));
  const directoryEntries = new Set(['agents', 'commands', 'skills', 'plugins']);
  const resolveSource = (file) => {
    const resolved = real(file);
    if (!inside(source, resolved)) fail(`source link escapes ${source}: ${file} -> ${resolved}`);
    // Check intermediate hops too: never route through an installed link
    // that happens to resolve back into the source tree.
    let current = source;
    for (const part of path.relative(source, file).split(path.sep).filter(Boolean)) {
      current = path.join(current, part);
      if (fs.lstatSync(current).isSymbolicLink()) {
        const target = path.resolve(path.dirname(current), fs.readlinkSync(current));
        if (!inside(source, target)) fail(`source link escapes ${source}: ${current} -> ${target}`);
        current = resolveSource(target);
      }
    }
    return resolved;
  };
  const walk = (file, active = new Set()) => {
    const resolved = resolveSource(file);
    const info = fs.statSync(resolved);
    if (!info.isDirectory()) {
      if (!info.isFile()) fail(`unsupported source entry: ${file}`);
      return;
    }
    if (active.has(resolved)) fail(`recursive source directory cycle: ${file} -> ${resolved}`);
    const next = new Set(active).add(resolved);
    for (const name of fs.readdirSync(resolved)) walk(path.join(resolved, name), next);
  };
  const validateSource = () => {
    for (const [name, target] of planned) {
      requireReal(target, directoryEntries.has(name));
      walk(target);
    }
  };
  validateSource();
  // Check every conflict before creating a directory or replacing any link.
  for (const name of planned.keys()) {
    const installed = path.join(destination, name);
    const info = stat(installed);
    if (info && !info.isSymbolicLink())
      fail(`back up this conflicting path before retrying: ${installed}`);
  }
  fs.mkdirSync(destination, { recursive: true });
  requireReal(destinationPath, true);
  if (real(destinationPath) !== destination) fail(`destination changed during setup: ${destinationPath}`);
  for (const [name, target] of planned) {
    const installed = path.join(destination, name);
    const info = stat(installed);
    if (info?.isSymbolicLink() && fs.readlinkSync(installed) === target) continue;
    if (info) {
      if (!info.isSymbolicLink()) fail(`destination entry changed during setup: ${installed}`);
      fs.unlinkSync(installed); // Remove the link itself; never follow a directory link.
    }
    fs.symlinkSync(target, installed);
  }
  validateSource();
  for (const [name, target] of planned) {
    const installed = path.join(destination, name);
    if (!stat(installed)?.isSymbolicLink() || fs.readlinkSync(installed) !== target || real(installed) !== target)
      fail(`installed link failed verification: ${installed} -> ${target}`);
  }
  console.log(`OpenCode profile: ${profile} (${destination})`);
} catch (error) {
  console.error(`opencode-profile: ${error.message}`);
  process.exitCode = 1;
}
JS
  local result=$?
  (( result == 0 )) || return $result
  unset OPENCODE_CONFIG OPENCODE_CONFIG_CONTENT
}
