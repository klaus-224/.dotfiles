# macOS Dotfiles

This repository manages two macOS hosts with nix-darwin and Home Manager:

- `klaus-macbook`: personal, using `klaus224`
- `work-macbook`: work, using `rohineshram`

## Contents

- [Prerequisites](#prerequisites)
- [Bootstrap](#bootstrap)
- [What Each Layer Manages](#what-each-layer-manages)
- [Config Symlinks](#config-symlinks)
- [Homebrew Migration Safety](#homebrew-migration-safety)
- [Rebuild and Update](#rebuild-and-update)
- [Window Management](#window-management)
- [SSH Keys](#ssh-keys)
- [Tmux Commands](#tmux-commands)
- [Opencode Plugins](#opencode-plugins)
- [TODO](#todo)
- [CLI Tool Reference](#cli-tool-reference)
- [References](#references)

## Prerequisites

The configuration targets Apple Silicon (`aarch64-darwin`).

1. Install Apple's Xcode Command Line Tools:

   ```sh
   xcode-select --install
   ```

2. Install Nix using the Determinate Systems installer (this configuration sets
   `nix.enable = false` so Determinate continues managing the daemon):

   ```sh
   curl --proto '=https' --tlsv1.2 -L https://install.determinate.systems/nix \
     | sh -s -- install
   ```

3. Restart the terminal or load the Nix profile. Check it with `nix --version`.

4. Homebrew does not need a separate bootstrap. `nix-homebrew` installs it at
   the native Apple Silicon prefix (`/opt/homebrew`) or migrates an existing
   official installation during the first activation.

5. Choose a clone method:
   - HTTPS needs no SSH key for this public repository.
   - SSH requires [SSH Keys](#ssh-keys) and verified GitHub access first.
   - The Command Line Tools provide Git for the initial clone.

## Bootstrap

1. Complete the inventory and backup steps in
   [Homebrew migration safety](#homebrew-migration-safety).
2. Clone the repository and apply the flake:

   ```sh
   git clone https://github.com/klaus-224/.dotfiles.git ~/.dotfiles
   # With SSH configured, use git@github.com:klaus-224/.dotfiles.git instead.

   sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.dotfiles/nix#work-macbook
   ```

- The command above configures `work-macbook` for `rohineshram`.
- On the personal laptop, use `~/.dotfiles/nix#klaus-macbook`.
- Future rebuilds can use `darwin-rebuild` directly.

## What Each Layer Manages

### Nix: machine configuration and baseline tools

- **nix-darwin** manages:
  - macOS settings
  - system packages such as Git, mise, Starship, and Zsh plugins
  - Homebrew integration
- **Home Manager** manages:
  - baseline tools such as Neovim, tmux, ripgrep, GitHub CLI, AWS CLI, DuckDB,
    and OpenCode
  - links to application, Git, mise, and shell configuration in this checkout
- **The flake**:
  - exposes `klaus-macbook` and `work-macbook`
  - records input revisions in `nix/flake.lock`
  - uses a separate pinned nixpkgs input for OpenCode
- **Host modules** are extension points for personal and work differences. Both
  are currently empty.
- Configuration lives in `nix/darwin/`, `nix/home/`, and `nix/hosts/`.
- Nix installs mise; mise installs the development tools listed below.

### Homebrew through Nix: macOS applications and services

- **nix-homebrew** installs Homebrew and migrates an existing installation.
- **nix-darwin's Homebrew module** declares packages and activation behavior.
- Applications: AeroSpace, Arc, Ghostty, Docker Desktop, Raycast, and Spotify.
- Desktop services: JankyBorders and SketchyBar.
- Utilities: Lua and rtk.
- Package declarations: `nix/darwin/homebrew.nix`.
- Homebrew setup: `nix/darwin/default.nix`.
- Formula and cask versions are not pinned by `nix/flake.lock`.

### mise: developer tooling

- Runtimes and toolchains: Node.js, Python, and Rust.
- Project package managers: pnpm and uv.
- Language tools: tombi, YAML Language Server, vscode-langservers-extracted,
  Marksman, Tree-sitter, and ShellCheck.
- Most tools use explicit versions; Rust tracks `nightly`.
- Configuration lives in `mise/config.toml`.

### Where should a new tool go?

- **Nix:** machine settings, configuration links, and baseline shell, editor,
  or CLI tools.
- **Homebrew:** macOS applications, desktop services, and tools best supplied
  by Homebrew.
- **mise:** language runtimes, package managers, and development tools.
- Use one manager per tool to avoid duplicate binaries and PATH conflicts.

## Config Symlinks

- Home Manager uses `mkOutOfStoreSymlink` to link files from this checkout.
- Changes under `~/.dotfiles` are visible without copying files to the Nix store.
- Managed examples:

- `~/.config/nvim` from `nvim/`
- `~/.config/ghostty` from `ghostty/`
- `~/.config/gh-dash` from `git/gh-dash/`
- `~/.tmux.conf` from `tmux/`
- `~/.zshenv`, `~/.zshrc`, and `~/.zshrc.d` from `zsh/`
- `~/.gitconfig` from `git/`
- Individual `~/.local/bin/<helper>` links from `bin/`; unmanaged names remain yours.

- Keep the checkout at `~/.dotfiles`; the links use that path.

## Homebrew migration safety

Activation has destructive cleanup settings:

- Declared packages are upgraded.
- Cleanup runs with `zap`.
- Undeclared formulae, casks, and taps may be removed.
- Data for undeclared casks may also be deleted.

Before the first switch on **each machine**:

1. Inventory packages with `brew leaves`, `brew list --cask`, and `brew tap`.
2. Compare the inventory with the generated Brewfile.
3. Declare everything that must survive.
4. Back up important application data.
5. Check existing Raycast and Spotify installations for conflicts.

Safety notes:

- Building and evaluating are safe; do not switch until the review is complete.
- `flake.lock` pins the Homebrew source, not formula or cask versions.
- Reverting a Nix generation cannot restore data removed by
  `brew bundle cleanup --zap`.

## Rebuild and Update

- Apply changes on the work laptop:

```sh
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#work-macbook
```

- On the personal laptop, use `~/.dotfiles/nix#klaus-macbook`.

- Update flake inputs and activate the result:

```sh
nix flake update --flake ~/.dotfiles/nix
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#work-macbook
```

- Work shortcuts: `just rebuild-work` and `just update-work`.
- Personal shortcuts: `just rebuild` and `just update`.
- Offline checks: `just check`.
- Evaluate both hosts without activation: `just validate-nix-eval`.
- See the [validation and migration guide](docs/config-audit.md) before migrating
  an existing `~/.local/bin` directory symlink.

## Window Management

- AeroSpace manages tiled windows and workspaces.
- JankyBorders highlights the focused window.
- SketchyBar displays workspace buttons and a clock.

<<<<<<< HEAD
Named workspace groups include `code`, `browse`, `music`, `slack`, `discord`,
and `teams`. Use `option-c/b/m/s/t` to switch to the corresponding group, and
`option-tab` to change monitors. Group buttons perform the same actions through
`scripts/aerospace-groups.sh`; both routes intentionally require two connected
displays.

Configuration lives in `aerospace/aerospace.toml`, `borders/bordersrc`, and
`sketchybar/`. Home Manager links these directories into `~/.config`. See the
[SketchyBar guide](sketchybar/README.md) for its module layout and shared style
settings. After a configuration change, reload AeroSpace or restart the
Homebrew services:
=======
Workspace assignments:

- `1`: Ghostty
- `2`: Arc
- `3`: development
- `4`: communication
- `5`: Spotify

- Move focus: `option-h/j/k/l`.
- Move the focused window: `option-shift-h/j/k/l`.
- Switch workspaces: `option-1` through `option-5`.
- Move a window to a workspace: add `shift` to its workspace shortcut.

- `scripts/aerospace-home.sh` switches to an app's home workspace and opens or
  focuses the app.
- Repair a misplaced window with:

```sh
~/.dotfiles/scripts/aerospace-home.sh --repair 1 com.mitchellh.ghostty
```

- Configuration: `aerospace/aerospace.toml`, `borders/bordersrc`, and
  `sketchybar/`.
- Home Manager links these paths into `~/.config`.
- After a change, reload AeroSpace or restart the services:
>>>>>>> main

```sh
aerospace reload-config
brew services restart borders
brew services restart sketchybar
```

## SSH Keys

1. Generate a key and add it to the SSH agent:

   ```sh
   ssh-keygen -t ed25519 -C "your_email@example.com"
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   cat ~/.ssh/id_ed25519.pub
   ```

2. Add the key at [GitHub SSH settings](https://github.com/settings/ssh/new).
3. Test the connection:

   ```sh
   ssh -T git@github.com
   ```

## Tmux Commands

- `ctrl-a + r`: reload tmux

## Opencode Plugins

- Work intentionally has no plugins.
- Personal uses [plannotator](https://github.com/backnotprop/plannotator) for
  user-managed plans.
- See [profile configuration and safe checks](opencode/README.md).
- OpenCode updates are Nix-managed, not application-managed.

## TODO
- [ ] configure plannotator [plannotator config](https://docs.plannotator.ai/open-source/reference/configuration)
- [ ] setup devenv and direnv
- [ ] tools to look at
    - [age](https://github.com/FiloSottile/age): file encryption/decryption
    - [e1s](https://github.com/keidarcy/e1s): TUI to manage ECS
    - [book of secret knowledge](https://github.com/trimstray/the-book-of-secret-knowledge)
    - [zshkit](https://github.com/bkerley/zshkit): example zsh config
    - croc
    - ttyd
    - zsh suffix alias
    - hammerspoon
    - aerospace
    - [phlmn/nix-darwin-config: My config for nix-darwin with home-manager](https://github.com/phlmn/nix-darwin-config)
    - [evermeer/CodingAgentOrchestration: Quick start for using an AI Coding Agent - OpenCode Setup Guide / Orchestration](https://github.com/evermeer/CodingAgentOrchestration)
    - [arnavpisces/opencode-sidebar: A sidebar for opencode. Multiple sessions in the terminal powered by tmux](https://github.com/arnavpisces/opencode-sidebar)
    - [saqibameen/agent-dotfiles: Write AI coding rules once, sync to every agent. Claude, CommandCode, Cursor, Copilot, Codex. https://x.com/saqibameen](https://github.com/saqibameen/agent-dotfiles)
    - [Ainsley0917/opencode-token-monitor: OpenCode plugin for monitoring token usage, estimating costs, and tracking analytics across AI coding sessions](https://github.com/Ainsley0917/opencode-token-monitor)
    - [numman-ali/openskills: Universal skills loader for AI coding agents - npm i -g openskills](https://github.com/numman-ali/openskills)
    - [sun-praise/opencode-review: OpenCode automatic review agent plugin](https://github.com/sun-praise/opencode-review)
    - [malhashemi/opencode-sessions: Session management plugin for OpenCode with multi-agent collaboration support](https://github.com/malhashemi/opencode-sessions)
    - [tickernelz/opencode-mem: OpenCode plugin that gives coding agents persistent memory using local vector database](https://github.com/tickernelz/opencode-mem)
    - [AnganSamadder/opentmux](https://github.com/AnganSamadder/opentmux)
    - [Mark1708/opencode-agents-sidebar: Universal OpenCode TUI sidebar for browsing provider agents and subagents](https://github.com/Mark1708/opencode-agents-sidebar)
    - [Randroids-Dojo/ManageSkills](https://github.com/Randroids-Dojo/ManageSkills)
    - [Opencode-DCP/opencode-dynamic-context-pruning: Dynamic context pruning plugin for OpenCode - intelligently manages conversation context to optimize token usage](https://github.com/Opencode-DCP/opencode-dynamic-context-pruning)
    - [simonwjackson/opencode-direnv: OpenCode plugin that automatically loads direnv environment variables at session start](https://github.com/simonwjackson/opencode-direnv)
    - [abhixdd/ghgrab: A simple, pretty terminal tool that lets you browse and download files from GitHub, GitLab, Codeberg, Gitea, and Forgejo without leaving your CLI.](https://github.com/abhixdd/ghgrab)
    - [mksglu/context-mode: Context window optimization for AI coding agents. Sandboxes tool output (98% reduction), persists session memory, and enforces routing across 17 platforms via MCP + hooks.](https://github.com/mksglu/context-mode)
    - [darrenhinde/OpenAgentsControl: AI agent framework for plan-first development workflows with approval-based execution. Multi-language support (TypeScript, Python, Go, Rust) with automatic testing, code review, and validation built for OpenCode](https://github.com/darrenhinde/OpenAgentsControl)
    - [nektos/act: Run your GitHub Actions locally 🚀](https://github.com/nektos/act)
    - [whyisdifficult/jiratui: A Textual User Interface for interacting with Atlassian Jira from your shell](https://github.com/whyisdifficult/jiratui)
    - [modem-dev/hunk: Review-first terminal diff viewer for agentic coders](https://github.com/modem-dev/hunk)

## CLI Tool Reference

- This is a reference list, not an installation procedure.
- Nix tools: `nix/darwin/default.nix` and `nix/home/packages.nix`.
- Homebrew packages: `nix/darwin/homebrew.nix`.
- mise development tools: `mise/config.toml`.
- Host-specific overrides: `nix/hosts/`.

- [book of secret knowledge](https://github.com/trimstray/the-book-of-secret-knowledge)
- [gh-dash](https://www.gh-dash.dev/getting-started): TUI dashboard for GitHub PRs and issues
- [age](https://github.com/FiloSottile/age): file encryption/decryption
- [e1s](https://github.com/keidarcy/e1s): TUI to manage ECS
- [jsongrep](https://github.com/micahkepe/jsongrep): search JSON, YAML, and TOML
- [dasel](https://github.com/tomwright/dasel): query and modify JSON, YAML, TOML, and XML
- [just](https://github.com/casey/just)
- [m-cli](https://github.com/rgcr/m-cli): macOS commands
- [RustScan](https://github.com/bee-san/RustScan): port scanner
- [zshkit](https://github.com/bkerley/zshkit): example zsh config
- [diss](https://github.com/yazgoo/diss): dissociates a program from the current terminal
- [xleak](https://github.com/bgreenwell/xleak): XLSX viewer
- [csvlens](https://github.com/YS-L/csvlens): CSV viewer


## References

- [mintlify-wiki](https://mintlify.wiki/explore)
- [awesome-modern-cli](https://github.com/thegdsks/awesome-modern-cli)
- [getdesign.md](https://getdesign.md/)
- [stitch](https://stitch.withgoogle.com/)
- [awesome-opencode](https://github.com/awesome-opencode/awesome-opencode)
- [useful-scripts-adamchainz](https://github.com/adamchainz/scripts)
- [GitHub cheat sheet](https://github.com/tiimgreen/github-cheat-sheet)
