# Devenv implementation plan

## Target structure

```text
~/.dotfiles/
└── devenv/
    ├── devenv.nix
    ├── devenv.yaml
    └── modules/
        ├── base.nix
        ├── work.nix
        ├── personal.nix
        └── dotfiles.nix
```

Build one shared environment with explicit profiles. Work repositories use an out-of-tree binding; established personal projects own their configuration. Enable native zsh auto-activation and manage work secrets at command runtime.

This is an implementation plan, not an applied repository change. Reviewed against the repository’s default branch and documentation on September 11, 2026. Validate package attributes and shell behavior on the target macOS machine during implementation.

## 1. Establish package ownership

| Layer | Contents |
| --- | --- |
| Home Manager | devenv, Neovim, git, tmux, gh, ripgrep, fd, fzf, jq, just, shell utilities, Starship, OpenCode |
| base | YAML and JSON LSPs; small shared build/scripting toolset |
| work | Node/pnpm and Python/uv initially; AWS CLI; additional work runtimes only where needed |
| personal | Generic Node/pnpm and Python/uv fallback for projects without their own environment |
| dotfiles | Nix and Lua LSPs, Nix formatter, TOML tooling and the formatter used by dotfiles |
| Repository environment | Project-specific runtime versions, language tools, databases and development processes |

- [ ] Install a pinned devenv version supporting persistent bindings: minimum 2.2, preferably a current tested patch release.
- [ ] Keep devenv globally available so activation does not depend on an already-active development shell.
- [ ] Confirm the existing package inventory before removal; migrate packages only after their destination profile works.

The current `nix/home.nix` includes YAML/JSON/Lua LSPs, tombi, oxfmt, nixd, nixfmt, awscli2 and duckdb. Move YAML/JSON to base; move Nix/Lua/TOML/dotfiles formatting tools to dotfiles; move AWS CLI to work. Place DuckDB in the profile or project that actually uses it. Keep jq in Home Manager instead of duplicating it. [Current Home Manager configuration](https://github.com/klaus-224/.dotfiles/blob/main/nix/home.nix)

## 2. Compose profiles

- [ ] Add `devenv/devenv.nix`:

```nix
{ ... }:
{
  profiles = {
    base.module = import ./modules/base.nix;

    work = {
      extends = [ "base" ];
      module = import ./modules/work.nix;
    };

    personal = {
      extends = [ "base" ];
      module = import ./modules/personal.nix;
    };

    dotfiles = {
      extends = [ "base" ];
      module = import ./modules/dotfiles.nix;
    };
  };
}
```

Each context explicitly inherits base. Select the context through directory bindings rather than username or hostname, since work and personal projects share a machine. [Profile composition](https://devenv.sh/profiles/)

- [ ] Add `devenv/devenv.yaml` with a pinned input resolved through its lockfile:

```yaml
inputs:
  nixpkgs:
    url: github:cachix/devenv-nixpkgs/rolling
```

- [ ] Generate and commit `devenv/devenv.lock` alongside the configuration. Treat it separately from the workstation’s `flake.lock`.
- [ ] Ignore generated `.devenv/` state; track all imported module files.
- [ ] Keep work credentials and SecretSpec evaluation disabled in this shared YAML configuration.

## 3. Populate the modules

### base.nix

```nix
{ pkgs, ... }:
{
  packages = with pkgs; [
    yaml-language-server
    vscode-langservers-extracted
    gnumake
    pkg-config
    shellcheck
  ];
}
```

- [ ] Use `yaml-language-server --stdio` and `vscode-json-language-server --stdio` in the existing Neovim LSP configurations.
- [ ] Retain existing LSP configuration names and settings; change package ownership, not the editor architecture.
- [ ] Add yq, zip/unzip or other shared helpers only when a recurring need exists.

The JSON server is supplied by `vscode-langservers-extracted`; the package also includes other web language servers. Base means every central profile inherits these tools. A standalone repository-owned devenv must declare its own LSP packages if needed.

### work.nix

Initial package sketch:

```nix
{ pkgs, ... }:
{
  packages = with pkgs; [
    nodejs
    pnpm
    python3
    uv
    awscli2
  ];
}
```

- [ ] Select explicit runtime versions matching current work requirements before merging; the sketch uses nixpkgs defaults.
- [ ] Add Go, Rust or infrastructure tools only if current work requires them.
- [ ] Keep dependency installation and server startup out of shell entry.
- [ ] Configure work-only secret manifests as described below.

### personal.nix

- [ ] Start with Node/pnpm and Python/uv if both are used across personal scratch projects.
- [ ] Keep exact application dependencies and services in each established project.
- [ ] Do not import `~/.dotfiles` from a shared personal repository’s devenv; a fresh clone should stand on its own.

### dotfiles.nix

```nix
{ pkgs, ... }:
{
  packages = with pkgs; [
    nixd
    nixfmt
    lua-language-server
    tombi
    oxfmt
  ];
}
```

- [ ] Bind the `.dotfiles` repository root, so editing `nvim/`, `nix/` and `zsh/` activates this profile.
- [ ] Confirm the actual configured Lua formatter before adding or moving its package.
- [ ] Launch Neovim after activation; an already-running editor does not acquire a new shell’s PATH automatically.

## 4. Enable automatic activation

- [ ] Add the hook once at the end of the tracked `zsh/.zshrc`, after existing initialization:

```zsh
if command -v devenv >/dev/null 2>&1; then
  eval "$(devenv hook zsh)"
fi
```

The current Home Manager configuration symlinks this file to `~/.zshrc`; edit the tracked source. Audit sourced `.zshrc.d` files for existing activation hooks. [Current zsh entrypoint](https://github.com/klaus-224/.dotfiles/blob/main/zsh/.zshrc)

- [ ] Use a single activation mechanism for each project; remove any overlapping direnv activation for migrated projects.
- [ ] Test with a fresh interactive zsh.

Native activation starts a trusted project subshell and exits it when leaving the project. It is not direnv-style modification of the original shell. Subdirectories remain within the same environment. [Auto-activation behavior](https://devenv.sh/auto-activation/)

### Bind directories once

Work repository:

```zsh
cd ~/code/work-project
devenv --from "path:$HOME/.dotfiles/devenv" --profile work allow
```

Personal fallback:

```zsh
cd ~/code/personal-project
devenv --from "path:$HOME/.dotfiles/devenv" --profile personal allow
```

Dotfiles:

```zsh
cd ~/.dotfiles
devenv --from "path:$HOME/.dotfiles/devenv" --profile dotfiles allow
```

Bindings retain the source and profile for future commands and shell entry. Register individual repository roots, not the entire `~/code` tree. Recreate bindings on a new machine or after moving a checkout; keep these onboarding commands in the repository documentation. Do not copy or modify devenv’s internal trust database. Local source edits are picked up without rebinding. [Persistent out-of-tree environments](https://devenv.sh/blog/2026/07/28/devenv-22-attach-to-running-processes-and-persistent-out-of-tree-environments/)

### Adopt a repository-owned environment

- [ ] Leave the active fallback shell, revoke the old binding from the project directory, add the local configuration, and run plain `devenv allow`.
- [ ] Verify the project now resolves its local environment with no saved central profile.
- [ ] Explicitly validate this transition on the installed version instead of relying on an assumed precedence rule between local files and an existing binding.

## 5. Integrate tmux through working directories

- [ ] Ensure session creation starts an interactive zsh at the selected repository root.
- [ ] Preserve `-c '#{pane_current_path}'` on normal splits; it already exists in the current configuration.
- [ ] Add that working-directory argument to ordinary new-window bindings if project-local windows are desired.
- [ ] Inspect `scripts/tmux-session-dispensary.sh` and retain directory selection there; let the zsh hook handle activation.
- [ ] Separately test direct-command panes such as the existing OpenCode split: these may not initialize interactive zsh and cannot be assumed to run its hook.

Do not add a second automatic `devenv shell` launch to normal tmux shell panes. Test both a fresh tmux server and an existing server, since inherited environment state can differ. [Current tmux configuration](https://github.com/klaus-224/.dotfiles/blob/main/tmux/.tmux.conf)

Example validation session:

```zsh
tmux new-session -s devenv-check -c "$HOME/code/work-project"
```

Kill this test session, recreate it, and verify that its first shell activates the work profile without another `allow`.

## 6. Manage work secrets with SecretSpec

Use SecretSpec with macOS Keychain for local credentials by default. If work already has an approved shared secret provider, configure that provider instead. Keep work secrets isolated from personal and dotfiles profiles.

Load credentials into the command that needs them. Normal shell activation should work without resolving secrets. Do not put secret values in Nix expressions, `env.*`, generated scripts or shell entry hooks. This follows devenv’s recommended runtime-loading approach. [SecretSpec integration](https://devenv.sh/integrations/secretspec/)

- [ ] Confirm the bundled `secretspec` CLI is available and supports the example flags.
- [ ] Add declaration-only manifests under `devenv/secrets/<project>.toml` as needed. This is an extension to the initial structure, alongside the generated lockfile.
- [ ] Keep sensitive work-specific names or metadata outside the public dotfiles repository if necessary; the CLI can read a manifest from a private local path.
- [ ] Give each project a distinct SecretSpec project name. Do not share one work-wide `DATABASE_URL` across unrelated repositories.

Example `devenv/secrets/work-project.toml`:

```toml
[project]
name = "roh-work-project"
revision = "1.0"

[profiles.default]
DATABASE_URL = { description = "Development database connection", required = true }
```

Provision the value interactively; do not pass it as a command-line argument:

```zsh
secretspec --file "$HOME/.dotfiles/devenv/secrets/work-project.toml" \
  set DATABASE_URL --provider keyring
```

Store only declarations in Git. Credentials remain in the provider. SecretSpec’s profiles select secret sets; they are distinct from devenv’s tooling profiles. [SecretSpec quick start](https://secretspec.dev/quick-start/)

From the work repository, run:

```zsh
secretspec --file "$HOME/.dotfiles/devenv/secrets/work-project.toml" \
  run --provider keyring -- pnpm dev
```

The explicit manifest path supports repositories with no added configuration files. The application keeps the current working directory. Repeat the same pattern for tests or other commands needing credentials. After validating one project, optionally add a short project-specific devenv script in `work.nix` to avoid repeating the manifest path. [SecretSpec CLI](https://secretspec.dev/reference/cli/)

- [ ] Verify a missing required credential prevents the wrapped application from launching.
- [ ] Verify the parent shell does not gain `DATABASE_URL` after the command exits; check presence without printing values.
- [ ] Verify Keychain access and credential rotation with one development secret.
- [ ] Retain existing AWS login/SSO workflows where applicable; do not replace them with embedded access keys.

## 7. Validate and finish migration

| Check | Expected result |
| --- | --- |
| Enter work repository | Work tools and base LSPs available automatically |
| Start zsh directly in repository | Same activation as entering with cd |
| Enter repository subdirectory | Same environment, no nested shell |
| Leave repository | Profile tools/environment unload |
| Move from work to personal repository | Correct destination profile; no work credentials |
| Recreate tmux session; open window/split | Correct profile from starting directory |
| Edit YAML and JSON in Neovim | Configured servers start from activated PATH |
| Edit Nix and Lua under `.dotfiles` | Dotfiles language servers available |
| Missing work credential | Shell opens; secret-dependent command fails clearly |
| Company repository status | No tracked configuration changes; inspect any generated local state |
| Local personal devenv after migration | Uses project configuration independently of dotfiles |

- [ ] Verify binaries with `command -v`, versions with each tool’s version command, and LSP attachment inside Neovim.
- [ ] Check PATH ordering in newly activated shells; current zsh prepends custom bin directories, so ensure they do not shadow selected runtimes.
- [ ] Remove migrated global packages only after these checks pass and rebuild Home Manager/nix-darwin using the existing workflow.
- [ ] Confirm global workstation commands still work outside projects.
- [ ] Document that YAML/JSON LSPs are now environment-scoped; unrelated files opened outside a devenv will not have these global fallbacks.

## Completion criteria and rollback

Done when work, personal fallback and dotfiles bindings activate automatically, tmux recreations work, YAML/JSON LSPs come from base, and one real work command successfully obtains its secrets at runtime.

If activation fails, temporarily disable the zsh hook and invoke `devenv --from "path:$HOME/.dotfiles/devenv" --profile work shell` explicitly. Restore moved Home Manager packages if needed. Revoke only the affected test binding. Keep credential storage intact while fixing environment activation.

### OLD

# Implementation Plan: Centralized devenv Environments

## Goal

Manage project runtimes and development dependencies through devenv:

- Personal repositories own their environment configuration.
- Company repositories use environments stored in `~/.dotfiles`.
- Home Manager provides universal tools such as Git, Neovim, tmux, and devenv.
- Company repositories require no tracked Nix or activation files.

## Environment Selection Policy

| Project state | Intended environment |
| --- | --- |
| Repository defines `devenv.nix` | Repository environment |
| Repository has no environment | Explicitly bound dotfiles environment |
| Bound repository later adds `devenv.nix` | Remove the external binding and adopt the repository environment |
| Unbound directory without configuration | Normal shell |

Treat these as alternative configuration sources. Do not assume configurations merge or that a new local configuration automatically overrides an existing binding.

# Phase 0: Move flake.nix
You can move both files into `nix/`, but this is more than a file move because Nix resolves relative paths from the directory containing `flake.nix`.

## Current impact

## Recommended target layout

```text
.dotfiles/
├── nix/
│   ├── flake.nix
│   ├── flake.lock
│   ├── darwin.nix
│   └── home.nix
├── Justfile
├── README.md
├── nvim/
├── ghostty/
├── tmux/
└── ...
```

## Important command changes

Use the explicit flake path. Do not rely on running commands from `nix/`, because the repository shortcuts are intended to work from anywhere.

```sh
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#klaus-macbook
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#work-macbook

nix flake update --flake ~/.dotfiles/nix
nix flake check ~/.dotfiles/nix
```

For the bootstrap flow:

```sh
git clone git@github.com:klaus-224/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

sudo nix run nix-darwin/master#darwin-rebuild -- \
  switch --flake ./nix#work-macbook
```

The `./` matters for a relative local flake path. Nix supports a flake in a subdirectory, but the command must point directly at that directory.

## Planned `flake.nix` path changes

Once the file is inside `nix/`, these paths become:

```nix
modules = [
  ./darwin.nix
  home-manager.darwinModules.home-manager
];

users.${username} = ./home.nix;
```

The current `nix/darwin.nix` and `nix/home.nix` files themselves do not appear to contain paths that depend on the flake being at the repository root.

## Suggested refactor sequence

When you are ready to make the change:

```sh
git mv flake.nix nix/flake.nix
git mv flake.lock nix/flake.lock
```

Then update:

done 1. Relative module paths in `nix/flake.nix`.
done 2. Flake paths in `Justfile`.
done  3. Flake paths and layout references in `README.md`.
done 4. The Nix LSP root detection in `nvim/lsp/nixd.lua`.

Avoid adding a root-level forwarding `flake.nix` unless you specifically want backward compatibility. A forwarding flake would not be a transparent solution because the lock file belongs to the actual flake directory, and commands such as `nix flake update` could become ambiguous.

## Verification plan

From the repository root:

```sh
nix flake metadata ./nix
nix flake check ./nix
nix flake show ./nix

nix flake update --flake ./nix --no-write-lock-file
```

The last command checks that the moved lock file and flake can be read without modifying anything.

Then validate the exact consumers:

```sh
just check
just rebuild-work
```

Only run `just rebuild-work` if you intend to activate the macOS configuration; it invokes `sudo darwin-rebuild switch`.

## Current repository state

I did not make edits. The worktree already had unrelated changes:

```text
D  nix-migration-plan.md
?? devenv-implementation.md
```

The existing root flake currently passes:

```text
nix flake check .
```

with both Darwin configurations evaluating successfully.

## Phase 1: Confirm the Existing Setup

- [x] Inspect the current Home Manager and zsh configuration.
- [x] Confirm `devenv --version` reports version 2.2 or newer.
- [x] Install or update devenv through the existing Nix configuration if needed.
- [x] Inventory globally installed project runtimes and package managers.
- [x] Identify the Node and pnpm versions required by the first work repository.
- [x] Check for existing direnv or devenv activation hooks.

Keep existing runtimes available until the replacement environment passes validation.

## Phase 2: Create the Work Environment

Create these files in the dotfiles repository:

| File | Purpose |
| --- | --- |
| `devenv/work/devenv.nix` | Work tooling and runtime configuration |
| `devenv/work/devenv.yaml` | Environment inputs |
| `devenv/work/devenv.lock` | Locked input revisions |
| `devenv/README.md` | Binding, activation, updates, and troubleshooting |

- [ ] Initialize the environment from `~/.dotfiles/devenv/work`.
- [ ] Start with Node and pnpm.
- [ ] Match versions to repository requirements.
- [ ] Add Python, uv, Go, Rust, or other tools only when required.
- [ ] Commit configuration and lock files.
- [ ] Ignore generated environment state in the dotfiles repository.

Use the generated devenv configuration as the starting point. Configure Node and pnpm together using the JavaScript language options supported by the installed version.

Do not enable automatic dependency installation initially.

## Phase 3: Enable zsh Activation

- [ ] Add the native hook once, in the existing zsh configuration:

```zsh
eval "$(devenv hook zsh)"
```

- [ ] Place it after devenv becomes available on PATH.
- [ ] Ensure later shell initialization does not override the environment PATH.
- [ ] Avoid configuring both direnv and native devenv activation for the same project.
- [ ] Rebuild the existing nix-darwin/Home Manager configuration.
- [ ] Open a fresh terminal and check for startup errors.

Keep Lua tooling used to maintain Neovim in Home Manager for now, as previously decided.

## Phase 4: Bind One Work Repository

For a repository without its own devenv configuration:

```bash
cd ~/code/company/example-repo
devenv --from "path:$HOME/.dotfiles/devenv/work" allow
devenv shell
```

- [ ] Bind the individual repository root, rather than the entire company directory.
- [ ] Confirm Node and pnpm resolve from the environment.
- [ ] Check the resulting versions against repository requirements.
- [ ] Run the repository’s existing install and verification commands.
- [ ] Confirm Git status contains no new tracked configuration changes.
- [ ] Inspect generated local files and add local excludes only if needed.

For repositories with their own configuration:

```bash
cd ~/code/personal/example-repo
devenv allow
devenv shell
```

Do not create an external binding for these repositories.

## Phase 5: Validate Selection and Shell Behavior

| Scenario | Expected result |
| --- | --- |
| Enter a bound work repository | Work environment activates |
| Enter a subdirectory | Same environment remains active |
| Leave the repository | Normal shell environment returns |
| Enter a repository with its own configuration | Repository environment activates |
| Switch between work and personal repositories | Correct tool versions become active |
| Open a tmux pane in the repository | Environment activates without duplicate shells |
| Launch Neovim from the environment | Required executables are available |
| Edit the shared work configuration | Changes apply on subsequent activation |

Useful checks:

```bash
command -v node
command -v pnpm
node --version
pnpm --version
git status --short
```

### Existing Binding Plus New Local Configuration

- [ ] Reproduce this case in a temporary repository.
- [ ] Record actual behavior for the installed devenv version.
- [ ] Verify how to clear its saved external source.
- [ ] Revoke the old activation permission and verify whether this also removes the binding.
- [ ] Allow the local environment and confirm its tool versions are active.
- [ ] Document the verified transition procedure.

Do not rely on undocumented precedence.

## Phase 6: Remove Duplicate Global Runtimes

After the pilot succeeds:

- [ ] Remove migrated project runtimes from Home Manager or other global package lists.
- [ ] Remove obsolete runtime-manager initialization and PATH entries.
- [ ] Preserve executables required by universal tools.
- [ ] Rebuild and repeat the basic work/personal environment checks.
- [ ] Confirm Git, Neovim, tmux, and devenv still work outside projects.

## Maintenance

- Bind each newly cloned work repository explicitly.
- Keep machine-specific directory bindings outside tracked dotfiles.
- Update environment inputs and commit the resulting lock-file changes.
- Validate shared updates against representative repositories.
- Introduce separate environments only when incompatible requirements appear.
- Launch Neovim and coding agents from the selected environment.
- Restart existing processes when they need a changed environment.

## Rollback

- Revert the dotfiles environment changes and lock file.
- Use `devenv revoke` to disable automatic activation for a repository.
- Verify external-binding removal separately before changing configuration sources.
- Restore removed global runtime declarations if required.
- Rebuild and open a fresh shell.

## Completion Criteria

- [ ] Work repositories use centrally managed development tools.
- [ ] Personal repositories use their own devenv configuration.
- [ ] No Nix or activation files need to be committed to company repositories.
- [ ] Environment selection and binding transitions are documented.
- [ ] PATH restores correctly when leaving an environment.
- [ ] Neovim and tmux work with the selected environment.
- [ ] Shared configuration and lock files are tracked in dotfiles.

## References

- [devenv 2.2: persistent out-of-tree environments](https://devenv.sh/blog/2026/07/28/devenv-22-attach-to-running-processes-and-persistent-out-of-tree-environments/)
- [Native shell activation](https://devenv.sh/auto-activation/)
- [Ad-hoc developer environments](https://devenv.sh/ad-hoc-developer-environments/)
