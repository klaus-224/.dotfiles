# Nix Migration Plan

Goal: fully migrate the macOS workstation from Homebrew + Stow + custom bootstrap scripts to:

- Determinate Nix for the Nix installation
- nix-darwin for system-level macOS configuration
- Home Manager for user-level packages and symlink placement
- existing dotfiles kept as normal editable config files

## Target Architecture

```text
.dotfiles/
├── flake.nix
├── flake.lock
├── nix/
│   ├── darwin.nix
│   └── home.nix
├── nvim/
├── ghostty/
├── tmux/
├── zsh/
├── git/
├── opencode/
├── glow/
├── bin/
└── README.md
```

Nix installs tools. The dotfiles repo remains the source of truth for application config.

---

## Phase 0 — Baseline and Safety

- [ ] Make sure the current nix-darwin + Home Manager configuration rebuilds successfully.
- [ ] Confirm `flake.nix` and `flake.lock` are committed.
- [ ] Save current Homebrew inventory:
  ```sh
  brew leaves > ~/brew-leaves.txt
  brew list --cask > ~/brew-casks.txt
  brew list --formula > ~/brew-formulae.txt
  ```
- [ ] Confirm the current dotfiles repo is clean before migration work begins.

### Commit checkpoint

```sh
git add -A
git commit -m "chore(nix): establish migration baseline"
```

---

## Phase 1 — Flatten Old Stow Layouts

Flatten directories that currently mirror `$HOME`.

Examples:

```text
nvim/.config/nvim/        -> nvim/
ghostty/.config/ghostty/  -> ghostty/
alacritty/.config/...     -> alacritty/
```

- [x] Flatten Neovim.
- [x] Flatten Ghostty.
- [x] Flatten Alacritty if it is still used.
- [x] Flatten tmux.
- [x] Flatten zsh.
- [x] Flatten git.
- [x] Flatten other Stow-style config directories.
- [x] Remove `.DS_Store` files from tracked config directories.
- [x] Verify application configs still contain all expected files.

### Commit checkpoint

```sh
git add -A
git commit -m "refactor(dotfiles): flatten stow directory layouts"
```

---

## Phase 2 — Replace Stow with Home Manager Symlinks

Use out-of-store symlinks so config edits are immediately visible without rebuilding.

Example:

```nix
{ config, pkgs, ... }:

{
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/klaus224/.dotfiles/nvim";

  xdg.configFile."ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/klaus224/.dotfiles/ghostty";
}
```

- [x] Link Neovim.
- [x] Link Ghostty.
- [x] Link tmux.
- [x] Link zsh.
- [x] Link git config.
- [x] Link OpenCode config.
- [x] Link Glow config.
- [x] Link any remaining managed config files.
- [x] Verify edits in `~/.dotfiles` are immediately reflected in their target locations.
- [x] Stop using Stow for migrated configs.

### Commit checkpoint

```sh
git add -A
git commit -m "feat(home-manager): replace stow with managed symlinks"
```

---

## Phase 3 — Move CLI Packages into Nix

Move intentionally installed CLI tools into `home.packages`.

Current likely candidates include:

```nix
home.packages = with pkgs; [
  aws-cdk
  awscli2
  bat
  bottom
  duckdb
  fd
  gcc
  gh
  glow
  jq
  just
  lazygit
  lua
  lua-language-server
  neovim
  ripgrep
  rustup
  sqlite
  supabase-cli
  terraform
  tmux
  tree
  tree-sitter
  uv
  watchman
  yaml-language-server
];
```

- [ ] Compare `brew leaves` against `home.packages`.
- [ ] Add missing tools that should be globally available.
- [ ] Remove duplicates where a Home Manager module already installs the package.
- [ ] Verify each important binary resolves from Nix:
  ```sh
  command -v fd
  command -v rg
  command -v nvim
  command -v tmux
  command -v gh
  ```
- [ ] Confirm important commands point into `/nix/store` or a Home Manager profile.

### Commit checkpoint

```sh
git add nix/
git commit -m "feat(nix): migrate global cli packages"
```

---

## Phase 4 — Global LSPs and Editor Tooling

Keep only genuinely global tooling in Home Manager.

Good global candidates:

- [ ] `lua-language-server`
- [ ] `yaml-language-server`
- [ ] `vscode-langservers-extracted`
- [ ] shell-related language servers used across many repos
- [ ] generic formatters or linters that are intentionally global

Prefer project-local tooling for version-sensitive packages:

- TypeScript
- `typescript-language-server`
- Biome
- oxlint
- oxfmt
- Prisma
- Python project tooling
- Rust project toolchains

- [ ] Confirm Neovim can still discover each global LSP.
- [ ] Confirm project-local binaries override global fallbacks where intended.

### Commit checkpoint

```sh
git add nix/
git commit -m "feat(nix): migrate global editor tooling"
```

---

## Phase 5 — Custom `bin/` Scripts

Keep scripts editable in the repo and expose them through Home Manager.

Example:

```nix
home.file.".local/bin" = {
  source = config.lib.file.mkOutOfStoreSymlink "/Users/klaus224/.dotfiles/bin";
};
```

- [ ] Link `bin/` into `~/.local/bin`.
- [ ] Ensure `~/.local/bin` is on `PATH`.
- [ ] Test each important custom script.
- [ ] Identify scripts that rely on Homebrew paths.
- [ ] Replace hard-coded `/opt/homebrew/...` references.
- [ ] Optionally migrate suitable scripts to `pkgs.writeShellApplication` later.

### Commit checkpoint

```sh
git add -A
git commit -m "feat(home-manager): manage custom scripts"
```

---

## Phase 6 — Replace Cargo-Managed Global Tools

- [ ] Review `packages/cargo.txt`.
- [ ] Search nixpkgs for each globally installed Cargo tool.
- [ ] Move available tools into `home.packages`.
- [ ] Keep Cargo installation only for packages unavailable or unsuitable in nixpkgs.
- [ ] Decide whether `rustup` remains global or Rust becomes project-managed through Nix.
- [ ] Remove Cargo sync logic once no longer needed.

### Commit checkpoint

```sh
git add -A
git commit -m "refactor(nix): replace cargo-managed global tools"
```

---

## Phase 7 — Migrate Remaining Homebrew Formulae

Use:

```sh
brew leaves
```

Only explicitly migrate packages you actually chose to install.

Do not manually migrate transitive libraries such as:

- OpenSSL
- libpng
- xz
- zstd
- brotli
- gettext
- sqlite dependencies
- image libraries
- AWS native dependencies
- Arrow dependencies

Nix will install those transitively.

- [ ] Map every remaining `brew leaves` entry to nixpkgs or another explicit Nix source.
- [ ] Test each replacement before uninstalling the Brew version.
- [ ] Remove any shell configuration referring to Homebrew paths.
- [ ] Remove `brew shellenv` from zsh config.

### Commit checkpoint

```sh
git add -A
git commit -m "feat(nix): migrate remaining homebrew formulae"
```

---

## Phase 8 — GUI Applications

Current GUI/cask inventory:

- [ ] Arc
- [ ] Docker Desktop
- [ ] Ghostty
- [ ] Nibble
- [ ] Raycast
- [ ] Spotify

For each app:

- [ ] Check for a usable Darwin package in nixpkgs.
- [ ] Verify the package launches correctly on macOS.
- [ ] Confirm updates behave acceptably.
- [ ] Decide explicitly what to do if nixpkgs does not provide a practical package.
- [ ] Avoid removing the Brew cask until the replacement is confirmed.

### Commit checkpoint

```sh
git add -A
git commit -m "feat(nix): migrate macos applications"
```

---

## Phase 9 — Clean Up nix-darwin Responsibilities

Keep `darwin.nix` system-focused.

Expected responsibilities:

```nix
{
  nix.enable = false;

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "klaus224";

  programs.zsh.enable = true;

  users.users.klaus224 = {
    name = "klaus224";
    home = "/Users/klaus224";
  };

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.stateVersion = 6;
}
```

- [ ] Keep user CLI packages out of `environment.systemPackages` unless they truly need to be system-wide.
- [ ] Keep personal app config out of `darwin.nix`.
- [ ] Keep macOS defaults, users, security settings, and system services in `darwin.nix`.

### Commit checkpoint

```sh
git add nix/
git commit -m "refactor(nix): separate system and user configuration"
```

---

## Phase 10 — Remove Homebrew Packages

Only do this after all required replacements are verified.

Back up package lists first if not already done.

Then:

```sh
brew uninstall --force $(brew list --formula)
brew uninstall --cask --force $(brew list --cask)

brew autoremove
brew cleanup --prune=all
```

Verify:

```sh
brew list
brew list --cask
```

- [ ] Confirm important CLI tools still work.
- [ ] Confirm GUI apps still launch.
- [ ] Confirm Neovim + LSPs work.
- [ ] Confirm tmux works.
- [ ] Confirm Git + SSH work.
- [ ] Confirm custom scripts work.

### Commit checkpoint

```sh
git add -A
git commit -m "chore: remove homebrew package dependencies"
```

---

## Phase 11 — Remove Homebrew Itself

Only after the machine is confirmed Brew-independent.

- [ ] Uninstall Homebrew.
- [ ] Remove Homebrew directories left behind if appropriate.
- [ ] Remove Homebrew-specific PATH setup.
- [ ] Remove Homebrew-related config files from the repo.
- [ ] Open a fresh shell and confirm there are no broken references.

### Commit checkpoint

```sh
git add -A
git commit -m "chore: remove homebrew"
```

---

## Phase 12 — Remove Stow and Old Bootstrap Logic

- [ ] Remove `stow` from package lists.
- [ ] Delete `.stowrc`.
- [ ] Delete `.stow-local-ignore`.
- [ ] Delete obsolete Stow commands from scripts.
- [ ] Remove old macOS setup scripts replaced by nix-darwin.
- [ ] Remove obsolete Homebrew installation logic.
- [ ] Remove obsolete Cargo sync logic.
- [ ] Remove old package-version manifests no longer needed.

### Commit checkpoint

```sh
git add -A
git commit -m "chore(dotfiles): remove stow and legacy bootstrap"
```

---

## Phase 13 — Add Rebuild and Update Commands

Add simple commands to the `Justfile`.

Example:

```make
rebuild:
    sudo darwin-rebuild switch --flake ~/.dotfiles#klaus-macbook

update:
    nix flake update
    sudo darwin-rebuild switch --flake ~/.dotfiles#klaus-macbook
```

- [ ] Add `rebuild`.
- [ ] Add `update`.
- [ ] Optionally add `check`:
  ```sh
  nix flake check
  ```
- [ ] Verify commands from a fresh shell.

### Commit checkpoint

```sh
git add Justfile nix/
git commit -m "feat(nix): add rebuild and update workflows"
```

---

## Phase 14 — Rewrite Documentation

Update the README around the new bootstrap flow.

Target installation flow:

```sh
git clone git@github.com:klaus-224/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

sudo nix run nix-darwin/master#darwin-rebuild --   switch --flake .#klaus-macbook
```

Normal rebuild:

```sh
sudo darwin-rebuild switch --flake ~/.dotfiles#klaus-macbook
```

- [ ] Document Nix installation prerequisites.
- [ ] Document nix-darwin bootstrap.
- [ ] Document Home Manager responsibilities.
- [ ] Document config symlink strategy.
- [ ] Document rebuild/update workflow.
- [ ] Remove Stow instructions.
- [ ] Remove Homebrew instructions.
- [ ] Remove obsolete Cargo bootstrap instructions.

### Commit checkpoint

```sh
git add README.md
git commit -m "docs: document nix-based workstation setup"
```

---

## Final Verification

After Homebrew and Stow are gone:

- [ ] Restart the Mac.
- [ ] Open a fresh Ghostty session.
- [ ] Confirm `darwin-rebuild` is available.
- [ ] Confirm zsh starts cleanly.
- [ ] Confirm PATH has no stale Homebrew paths.
- [ ] Confirm Neovim starts.
- [ ] Confirm Neovim LSPs attach.
- [ ] Confirm tmux starts.
- [ ] Confirm Git + SSH work.
- [ ] Confirm AWS CLI works.
- [ ] Confirm Supabase CLI works.
- [ ] Confirm Terraform works.
- [ ] Confirm custom `bin/` scripts work.
- [ ] Confirm GUI apps launch.
- [ ] Run:
  ```sh
  nix flake check
  ```
- [ ] Rebuild one final time:
  ```sh
  sudo darwin-rebuild switch --flake ~/.dotfiles#klaus-macbook
  ```
- [ ] Confirm `git status` is clean.

### Final commit checkpoint

```sh
git add -A
git commit -m "chore(nix): complete workstation migration"
```

---

## Desired End State

```text
Determinate Nix
  -> owns Nix itself

nix-darwin
  -> owns macOS system configuration

Home Manager
  -> installs user tools
  -> creates config symlinks

~/.dotfiles
  -> owns editable application configs

flake.lock
  -> pins package and module revisions
```

There should be no dependency on Homebrew or Stow for the normal workstation setup.
