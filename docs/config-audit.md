# Configuration audit: validation, dependencies and ownership

## Safe validation workflow

Run from the checkout you intend to inspect, or use
`just --justfile /absolute/path/to/checkout/Justfile doctor`. Validation uses the
Justfile's directory, including in linked Git worktrees; it does not assume
`~/.dotfiles` is the checkout under review.

| Command | Scope / side effects |
| --- | --- |
| `just doctor` | Read-only file/reference checks and PATH discovery. Missing validation tools/dependencies fail; optional application tools warn. Does not run discovered binaries, install, authenticate, source shell config or access databases. |
| `just doctor-deployed /absolute/home` | Same checks plus opt-in symlink metadata comparisons against this checkout. Missing/different deployed links warn; no contents of deployed files are read. |
| `just validate` / `just check` | Offline reference checks, zsh syntax, supported-shell ShellCheck, isolated audit tests, OpenCode offline tests/typecheck, hook tests. No package installation, network schemas, activation or Nix evaluation. Python fixtures are removed by the tests; Node hook/terminal fixtures are retained in the temporary directory for inspection. |
| `just validate-opencode` / `just validate-typecheck` | Uses already-installed local OpenCode dependencies; no `npx`, `bunx` or package-manager auto-install. Provision from the reviewed lockfile separately. |
| `just validate-hooks` | Runs `tests/git-terminal.test.mjs` with mocked commands; no staging, commits, live clipboard or active tmux changes. |
| `just validate-schema` | Explicit network schema tests, separate from offline/default validation. |
| `just validate-nix-eval` | Explicit evaluation of **both** `klaus-macbook` and `work-macbook` system derivations. No lock updates/writes or activation. May fetch inputs and write Nix evaluation/store caches. |
| `just validate-nix-build` | Explicit builds of both hosts; same lock protections plus `--no-link`. May download/build store paths; never runs `switch`, creates result links or modifies a profile. |

Each `validate-*` recipe can be run independently to expose all failures rather
than stopping at the first failing prerequisite. ShellCheck is selected by
supported shebangs (`sh`, `bash`, `dash`, `ksh`); zsh scripts receive `zsh -d -f -n`,
not a misleading Bash lint pass. `local.zsh` is excluded from syntax and isolated
startup tests because it is private, untracked configuration.

Nix uses explicit `path:` flake references so worktree/untracked module changes
are evaluated without staging. Keep the `nix/` tree free of private files before
evaluating: Nix may copy that source tree to its store. The older `rebuild*`,
`update*`, and `clean` recipes are **mutating maintenance commands**, not audit
checks. Do not invoke them during validation.

## Explicit dependencies

- Nix supplies Node.js, pnpm and Bun on both hosts. Shell startup no longer calls
  Homebrew or sources NVM. Nix Node is the default; users who explicitly need NVM
  can provision it and load its reviewed `nvm.sh` manually in that shell. No lazy
  function or hidden installer is added.
- `sqb` opens a Neovim SQL scratch buffer using `$EDITOR` (one executable, default
  `nvim`). It checks for `sqls` (work) or `postgres-language-server` (personal),
  matching `nvim/lsp/sqlls.lua` and `postgres_lsp.lua`. If neither exists it warns
  and still opens the buffer. It never runs Mason, installs a server, or runs a
  server just to probe it. LSP attachment still depends on Neovim's configured
  root/workspace rules; opening an editor is not an offline validation step.
- `ctx` is now an executable, not an interactive-only alias. It forwards arguments
  and exit status to an existing `ctx7`. If missing, it exits 127 with guidance.
  Home Manager includes `~/.local/bin` in the session PATH; non-login automation
  must inherit that PATH or call the checkout's `bin/ctx` by absolute path.
  The current upstream CLI documents **`npm install -g ctx7`**. Installation is an explicit user decision, never performed
  by the wrapper or doctor. Usage: `ctx library React "effect cleanup"`, then
  `ctx docs /facebook/react "effect cleanup"`. Actual queries use the network.
- `agent_memory` and `session_reader` are optional, externally maintained private
  executables, not dependencies supplied by this repository or Nix. Provision
  only from a trusted source and put them on PATH if you use those tools. No
  public package name is assumed. Missing helpers produce actionable errors.
  Doctor only checks executable presence; it never tests `init`, queries sessions,
  reads transcripts, or touches SQLite files. Their mutation commands remain
  explicitly user-invoked application features, not validation.
- Python 3 and ShellCheck are declared in common Home Manager packages so both
  hosts can run the same offline checks. Optional prompt/plugins are guarded when
  missing, and no empty completion directory or accidental `/go/bin` is added.

## Shell startup and bindings

Vi mode is selected before personal keybindings are applied. History widgets are
autoloaded before registration. `Ctrl-G` remains unbound, `jk` remains vi escape,
and history/backspace/navigation bindings are preserved. `Ctrl-B` only binds the
optional Ghostty transparency widget if a local module provides it; the former
unconditional binding named a function absent from this checkout. `stty` only
runs with a terminal. Autosuggestions and syntax highlighting load after widget
definitions, and only from readable configured paths.

`DOTFILES_HOME` can be supplied explicitly for an alternate checkout; its default
remains `~/.dotfiles`. The isolated tests copy only reviewed shell modules to a
temporary home, with sanitized environment and `zsh -d -f`, never source the real
home or its `local.zsh`, and measure only that isolated startup. A real interactive
terminal check (prompt rendering, plugins, vi cursor shape and local customizations)
is still a manual post-review step; isolated timings are not real-home benchmarks.

## Managed links, migration and rollback

Live out-of-store links remain the intentional default for editable configs. This
audit does **not** convert the repository to immutable Nix-store configuration.
Home Manager owns each named `~/.local/bin/<helper>` link individually, not the
entire `~/.local/bin` directory; unmanaged executable names must be preserved.
Add a corresponding explicit `home.file` entry when adding a new `bin/` helper.
Source scripts must retain executable mode; doctor checks it. No activation-time
chmod is used that could change a live source through a symlink.

**Migration requires manual inspection before activation.** An existing
`~/.local/bin` directory symlink may point through a Home Manager generation to
the entire checkout's `bin/`. Do not create child links through that directory
symlink: that can modify the checkout. Record the link chain and inventory both
managed and unmanaged names, preserve any unmanaged files, then plan replacing
only the directory symlink with a real directory. Resolve filename collisions
and existing `.backup` files deliberately. The audit performs none of this
migration, deletion, activation or automatic overwrite.

The repository ignores `git/.gitconfig.local` explicitly for private overrides.
Neither the repository nor the global ignore template hides
`.pre-commit-config.yaml`; hook policy files should remain reviewable. A user's
independently deployed global ignore may still contain the old rule until they
choose to update it.

**Rollback limitation:** selecting an older Nix/Home Manager generation restores
its link arrangement and packages, but live links still read the current checkout
contents. It does not restore prior file contents, unmanaged executables, local
overrides or databases. Before deployment, preserve the reviewed source revision
and any uncommitted/local changes independently. Content rollback and generation
rollback are separate operations; never use a destructive checkout/reset as a
substitute for preserving the user's changes.

## Documentation consulted

- [Context7 CLI](https://github.com/upstash/context7/tree/master/packages/cli): executable, installation and query syntax.
- [just functions](https://just.systems/man/en/functions.html): `justfile_directory()` and shell quoting.
- [Nix build](https://nix.dev/manual/nix/2.28/command-ref/new-cli/nix3-build.html): `--no-link`, lock flags and evaluation/build side effects.
- [Zsh line editor](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html): keymap selection and widget registration.
- [Home Manager home options](https://nix-community.github.io/home-manager/options/home-manager/home.html): individual `home.file` ownership, source-mode defaults and session PATH.
