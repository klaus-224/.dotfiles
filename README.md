# Contents

<!-- mtoc-start -->

- [Generating git SSH Keys](#generating-git-ssh-keys)
  - [Generate a new SSH key](#generate-a-new-ssh-key)
    - [Start the SSH agent and add the key](#start-the-ssh-agent-and-add-the-key)
    - [Copy the public key to the clipboard](#copy-the-public-key-to-the-clipboard)
    - [Add the public key to GitHub](#add-the-public-key-to-github)
    - [Test the connection](#test-the-connection)
- [Installation](#installation)
  - [Macos](#macos)
    - [Install Homebrew](#install-homebrew)
      - [Install git](#install-git)
      - [Clone dotfiles repo into `$HOME`](#clone-dotfiles-repo-into-home)
      - [Run the setup script](#run-the-setup-script)
    - [Windows (wsl)](#windows-wsl)
      - [Open Powershell as Admin](#open-powershell-as-admin)
      - [Update wsl](#update-wsl)
      - [Install Ubuntu](#install-ubuntu)
      - [Update Linux Packages](#update-linux-packages)
      - [Install git](#install-git-1)
      - [Clone the dotfile repo into `$HOME`](#clone-the-dotfile-repo-into-home)
      - [Run the WSL Setup Script](#run-the-wsl-setup-script)
- [Stow Packages](#stow-packages)
  - [Re-link a single package (useful after changes)](#re-link-a-single-package-useful-after-changes)
- [Cargo Package Management](#cargo-package-management)
- [Optional: Install Coding Agents](#optional-install-coding-agents)
- [Optional: Manual Agent Stow Commands](#optional-manual-agent-stow-commands)
- [Tmux Commands](#tmux-commands)
- [Opencode plugins](#opencode-plugins)
- [TODO](#todo)
- [CLI Tool Reference](#cli-tool-reference)
- [References](#references)

<!-- mtoc-end -->
---
# TODO

- [ ] transform zsh tools binaries
- [ ] consolidate everything into 1 `setup.sh` script
- [ ] look into dev containers [devpod](https://devpod.sh/)
- [ ] look into [ tpipeline ](https://github.com/vimpostor/vim-tpipeline)
---

# CLI Tool Reference

- [ gh-dash ](https://www.gh-dash.dev/getting-started) - TUI dashboard for GH PRs and issues

  ```zsh
    gh extension install dlvhdr/gh-dash
  ```

- [jsongrep](https://github.com/micahkepe/jsongrep) - search tool for JSON, YAML, and TOML with path query syntax
- [dasel](https://github.com/tomwright/dasel) - Query and modify JSON, YAML, TOML, and XML from the command line.
- [just](https://github.com/casey/just)
- [worktrunk](https://worktrunk.dev/worktrunk/#context-git-worktrees) - makes working with git worktrees easier
- [superpower](https://github.com/obra/superpowers) - plugins and stuff for ai
- [m-cli](https://github.com/rgcr/m-cli) - macos commands 
- [RustScan](https://github.com/bee-san/RustScan) - port scanner
- [book of secret knowledge](https://github.com/trimstray/the-book-of-secret-knowledge) 
- [useful scripts adamchainz](https://github.com/adamchainz/scripts) 
- [zshkit](https://github.com/bkerley/zshkit) - example zsh config
- [thread deck](https://github.com/gripebomb/ThreatDeck)
- [gh cheat sheet](https://github.com/tiimgreen/github-cheat-sheet)
- [diss](https://github.com/yazgoo/diss) - dissociates a program from the current terminal, like `dtach`
- [xleak](https://github.com/bgreenwell/xleak) - xlsx viewer
- [csvlens](https://github.com/YS-L/csvlens) - csv viewer


- **NOT ADDED** [qsv](https://github.com/andmarti1424/sc-im) - terminal spreadsheet calculator
- **NOT ADDED** [tomb](https://dyne.org/tomb/) - encryption
- **NOT ADDED** [pass](https://www.passwordstore.org/) - password manager
- **NOT ADDED** [rage](https://github.com/str4d/rage) - file encryption

---
# References
- [mintlify-wiki](https://mintlify.wiki/explore)
- [awesome-modern-cli](https://github.com/thegdsks/awesome-modern-cli)
- [getdesign.md](https://getdesign.md/)
- [stich](https://stitch.withgoogle.com/)
- [stow](https://www.youtube.com/watch?v=y6XCebnB9gs&t=166s)
- [awesome-opencode](https://github.com/awesome-opencode/awesome-opencode)
---

# Generating git SSH Keys

### Generate a new SSH key

```zsh
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### Start the SSH agent and add the key

```zsh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### Copy the public key to the clipboard

```zsh
cat ~/.ssh/id_ed25519.pub
```

### Add the public key to GitHub

Go to [GitHub SSH Settings](https://github.com/settings/ssh/new) and add the public key

### Test the connection

```zsh
ssh -T git@github.com
```

---

# Using multiple git accounts with ssh
- start ssh agent with `eval`
- load ssh key

```bash
    eval $(ssh-agent -s)
    ssh-add ~/PATH_TO_PRIVATE_KEY
```
## useful ssh commands
```
ssh-add -l # list active keys
ssh-add -d ~/,ssh/id_ed25519 # remove specific key
ssh-add -D # flush all keys
```
--- 

# Installation

### Macos

#### Install Homebrew

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$($(command -v brew) shellenv)"
```

#### Install git

```zsh
brew install git
```

#### Clone dotfiles repo into `$HOME`

```zsh
git clone git@github.com:klaus-224/.dotfiles.git ~/.dotfiles
```

#### Run the setup script

```zsh
cd ~/.dotfiles
chmod +x setup-macos.sh
./setup-macos.sh
```

**What this does:**

- Installs Homebrew if missing
- Installs all your CLI tools (fzf, bat, fd, eza, etc.)
- Writes installed Homebrew package versions to `packages/installed-versions/`
- Installs `rustup-init`, bootstraps Rust/Cargo, and syncs cargo packages from `packages/cargo.txt`
- Installs Ghostty terminal via Homebrew
- Installs and configures zsh/tmux/nvim/ghostty stow-managed dotfiles.
- Symlinks your core dotfiles using stow (`zsh`, `tmux`, `nvim`, `ghostty`)
- Installs tmux plugin manager (TPM)
- Runs the FZF setup

---

### Windows (wsl)

#### Open Powershell as Admin

```zsh
wsl --install
```

#### Update wsl

```zsh
wsl --update
wsl --set-default-version 2
```

#### Install Ubuntu

```zsh
wsl --install -d Ubuntu-22.04
```

#### Update Linux Packages

```zsh
sudo apt update && sudo apt upgrade -y
```

#### Install git

```zsh
sudo apt update && sudo apt install -y git
```

#### Clone the dotfile repo into `$HOME`

```zsh
cd ~
git clone git@github.com:klaus-224/.dotfiles.git ~/.dotfiles
```

#### Run the WSL Setup Script

```zsh
cd ~/.dotfiles
chmod +x setup-wsl.sh
./setup-wsl.sh
```

**What this does:**

- Install required CLI tools (tmux, zsh, neovim, etc.)
- Write installed Homebrew package versions to `packages/installed-versions/`
- Install Alacritty on Windows via winget
- Symlink stow packages for zsh/tmux/nvim, including any optional shell plugins.
- Symlink dotfiles using stow
- Install tmux plugin manager (TPM)

---

# Stow Packages

Each top-level directory is a stow package that mirrors `$HOME`:

| Package   | Command        | What it links                                                                 |
| --------- | -------------- | ----------------------------------------------------------------------------- |
| `zsh`     | `stow zsh`     | `.zshrc`, `.zshrc.d/`                                                         |
| `tmux`    | `stow tmux`    | `.tmux.conf`                                                                  |
| `nvim`    | `stow nvim`    | `.config/nvim/`                                                               |
| `ghostty` | `stow ghostty` | `.config/ghostty/`                                                            |
| `agents`  |                | optional coding-agent config packages (`.codex`, `.codex-skills`, `.copilot`) |

Global agent env vars are defined in `zsh/.zshenv`:

- `DOTFILES_HOME`
- `CODEX_HOME`, `CODEX_CONFIG_FILE`
- `COPILOT_HOME`, `COPILOT_CONFIG_FILE`, `COPILOT_MCP_CONFIG_FILE`

**Notes:**

- Use `--adopt` on first link so existing files in `~/.codex` / `~/.copilot` are safely moved under `~/.dotfiles/agents/*` and replaced by symlinks
- Codex system skills (`~/.codex/skills/.system`) are intentionally not managed here
- To add a custom Codex skill:
  - create `agents/.codex-skills/<skill-name>/SKILL.md`
  - run:
  ```zsh
  stow --restow --adopt --dir agents --target "${CODEX_HOME:-$HOME/.codex}/skills" .codex-skills
  ```

### Re-link a single package (useful after changes)

```zsh
stow -R zsh tmux nvim ghostty
```

---

# Cargo Package Management

Cargo-managed CLI tools live in `packages/cargo.txt` (one crate name per line).

```zsh
# install/update all listed cargo packages
./scripts/sync-cargo-packages.sh

# force reinstall all listed packages
./scripts/sync-cargo-packages.sh reinstall

# show configured package list
./scripts/sync-cargo-packages.sh list
```

The setup scripts (`setup-macos.sh`, `setup-linux.sh`) call this automatically when `cargo` is available.

---

# Optional: Install Coding Agents

```zsh
# Codex CLI + config/skill symlinks
./scripts/setup-codex-cli.sh

# Copilot CLI + config/skill symlinks
./scripts/setup-copilot-cli.sh
```

---

# Optional: Manual Agent Stow Commands

```zsh
# Codex config.toml -> ~/.codex/config.toml
stow --restow --adopt --dir agents --target "${CODEX_HOME:-$HOME/.codex}" .codex

# Custom Codex skills only -> ~/.codex/skills/*
stow --restow --adopt --dir agents --target "${CODEX_HOME:-$HOME/.codex}/skills" .codex-skills

# Copilot config/skills -> ~/.copilot/*
stow --restow --adopt --dir agents --target "${COPILOT_HOME:-$HOME/.copilot}" .copilot
```

---

# Tmux Commands

- `ctrl-z + r`: reload tmux
- `ctrl-z + ctrl-I`: install tpm plugins
- need latest version of `bash` for sessionx => `brew install bash`

---

# Opencode plugins

- [opentmux](https://github.com/AnganSamadder/opentmux) - tmux integration for viewing agent execution in real-time
- [plannotator](https://github.com/backnotprop/plannotator) - annotate agents plans

---

