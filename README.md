# Contents

<!-- mtoc-start -->

* [Generating git SSH Keys](#generating-git-ssh-keys)
  * [Generate a new SSH key](#generate-a-new-ssh-key)
    * [Start the SSH agent and add the key](#start-the-ssh-agent-and-add-the-key)
    * [Copy the public key to the clipboard](#copy-the-public-key-to-the-clipboard)
    * [Add the public key to Github](#add-the-public-key-to-github)
    * [Test the connection](#test-the-connection)
* [Installation](#installation)
  * [Macos](#macos)
    * [Install Homebrew](#install-homebrew)
      * [Install git](#install-git)
      * [Clone dotfiles repo into `$HOME`](#clone-dotfiles-repo-into-home)
      * [Run the setup script](#run-the-setup-script)
    * [Windows (wsl)](#windows-wsl)
      * [Open Powershell as Admin](#open-powershell-as-admin)
      * [Update wsl](#update-wsl)
      * [Install Ubuntu](#install-ubuntu)
      * [Update Linux Packages](#update-linux-packages)
      * [Install git](#install-git-1)
      * [Clone the dotfile repo into `$HOME`](#clone-the-dotfile-repo-into-home)
      * [Run the WSL Setup Script](#run-the-wsl-setup-script)
* [Stow Packages](#stow-packages)
  * [Re-link a single package (useful after changes)](#re-link-a-single-package-useful-after-changes)
* [Cargo Package Management](#cargo-package-management)
* [Optional: Install Coding Agents](#optional-install-coding-agents)
* [Optional: Manual Agent Stow Commands](#optional-manual-agent-stow-commands)
* [Tmux Commands](#tmux-commands)
* [References](#references)

<!-- mtoc-end -->

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

### Add the public key to Github

Go to [GitHub SSH Settings](https://github.com/settings/ssh/new) and add the public key

### Test the connection

```zsh
ssh -T git@github.com
```

---

# Installation

### Macos

#### Install Homebrew

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$(/opt/homebrew/bin/brew shellenv)"
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
- Writes installed Homebrew package versions to `brewfiles/installed-versions/`
- Installs `rustup-init`, bootstraps Rust/Cargo, and syncs cargo packages from `packages/cargo.txt`
- Installs Ghostty terminal via Homebrew
- Installs and configures:
  - Oh My Zsh
  - Powerlevel10k
  - zsh-autosuggestions
  - zsh-syntax-highlighting
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
- Write installed Homebrew package versions to `brewfiles/installed-versions/`
- Install Alacritty on Windows via winget
- Install and configure Oh My Zsh, Powerlevel10k, and Zsh plugins
- Symlink dotfiles using stow
- Install tmux plugin manager (TPM)

---

# Stow Packages

Each top-level directory is a stow package that mirrors `$HOME`:

| Package   | Command        | What it links                                                                 |
| --------- | -------------- | ----------------------------------------------------------------------------- |
| `zsh`     | `stow zsh`     | `.zshrc`, `.zshrc.d/`                                                         |
| `tmux`    | `stow tmux`    | `.tmux.conf`                                                                  |
| `nvim`    | `stow nvimj`   | `.config/nvim/`                                                               |
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

# References

- https://www.youtube.com/watch?v=y6XCebnB9gs&t=166s
- https://www.youtube.com/watch?v=03KsS09YS4E
- https://playbooks.com/skills/jeffallan/claude-skills/atlassian-mcp
- https://github.com/openai/codex/blob/main/codex-rs/core/config.schema.json
- https://www.passwordstore.org/
- https://dyne.org/tomb/
- https://github.com/dlvhdr/gh-dash
