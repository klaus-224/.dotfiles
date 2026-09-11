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

- [ ] Inspect the current Home Manager and zsh configuration.
- [ ] Confirm `devenv --version` reports version 2.2 or newer.
- [ ] Install or update devenv through the existing Nix configuration if needed.
- [ ] Inventory globally installed project runtimes and package managers.
- [ ] Identify the Node and pnpm versions required by the first work repository.
- [ ] Check for existing direnv or devenv activation hooks.

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
