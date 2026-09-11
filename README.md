# macOS Dotfiles

This repository contains the nix-darwin and Home Manager configuration for
`klaus-macbook` and `work-macbook`. The personal configuration uses the
`klaus224` user; the work configuration uses `rohineshram`.

## Contents

- [Prerequisites](#prerequisites)
- [Bootstrap](#bootstrap)
- [What Each Layer Manages](#what-each-layer-manages)
- [Config Symlinks](#config-symlinks)
- [Rebuild and Update](#rebuild-and-update)
- [SSH Keys](#ssh-keys)
- [Tmux Commands](#tmux-commands)
- [Opencode Plugins](#opencode-plugins)
- [TODO](#todo)
- [CLI Tool Reference](#cli-tool-reference)
- [References](#references)

## Prerequisites

The configuration targets an Apple Silicon Mac (`aarch64-darwin`). Before
bootstrapping:

1. Install Apple's Xcode Command Line Tools:

   ```sh
   xcode-select --install
   ```

2. Install the Nix package manager using the official installer:

   ```sh
   curl --proto '=https' --tlsv1.2 -L https://install.determinate.systems/nix \
     | sh -s -- install
   ```

3. Restart the terminal, or load the Nix profile as instructed by the
   installer. Confirm that `nix` is available with `nix --version`.

Git and the other workstation tools are installed by the configuration, so no
separate package-manager bootstrap is required.

## Bootstrap

Clone the repository and apply the nix-darwin flake for this machine:

```sh
git clone git@github.com:klaus-224/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles/nix

sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#work-macbook
```

The first run creates the system configuration and activates Home Manager for
the `rohineshram` user. Use `.#klaus-macbook` on the personal laptop. Future
rebuilds can use `darwin-rebuild` directly.

## What Each Layer Manages

- **nix-darwin** manages macOS settings, the system-level zsh setup, allowed
  unfree packages, and GUI applications declared in `nix/darwin.nix`.
- **Home Manager** manages user packages, command-line programs, editor and
  shell configuration, and dotfile links declared in `nix/home.nix`.
- **The flake** pins nixpkgs, nix-darwin, and Home Manager inputs in
  `flake.lock` and exposes both the `klaus-macbook` and `work-macbook` configurations.

## Config Symlinks

Home Manager uses `mkOutOfStoreSymlink` to link configuration files directly
from this checkout. Changes made under `~/.dotfiles` are therefore visible to
the corresponding applications without copying files into the Nix store.

Managed examples include:

- `~/.config/nvim` from `nvim/`
- `~/.config/ghostty` from `ghostty/`
- `~/.config/gh-dash` from `git/gh-dash/`
- `~/.tmux.conf` from `tmux/`
- `~/.zshenv`, `~/.zshrc`, and `~/.zshrc.d` from `zsh/`
- `~/.gitconfig` from `git/`
- `~/.local/bin` from `bin/`

Keep the checkout at `~/.dotfiles`; the symlink definitions use that path.

## Rebuild and Update

After changing Nix files or dotfiles, apply the current configuration with:

```sh
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#work-macbook
```

Use `~/.dotfiles#klaus-macbook` on the personal laptop.

To update flake inputs and activate the result:

```sh
cd ~/.dotfiles
nix flake update
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#work-macbook
```

The equivalent repository shortcuts are `just rebuild-work` and `just update-work`
on the work laptop, or `just rebuild` and `just update` on the personal laptop.
Validate the flake without activating it using `just check`.

## SSH Keys

Generate an SSH key if needed, add it to the SSH agent, and register the
public key with GitHub:

```sh
ssh-keygen -t ed25519 -C "your_email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Add the displayed key at [GitHub SSH settings](https://github.com/settings/ssh/new),
then test the connection:

```sh
ssh -T git@github.com
```

## Tmux Commands

- `ctrl-a + r`: reload tmux

## Opencode Plugins

- [opentmux](https://github.com/AnganSamadder/opentmux): tmux integration for viewing agent execution in real time
- [plannotator](https://github.com/backnotprop/plannotator): annotate agent plans

## TODO

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

This is a reference list, not an installation procedure. The active Nix-managed
tool list is defined in `nix/home.nix`.

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
