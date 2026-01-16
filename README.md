# Generating git SSH Keys

## Generate a new SSH key

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

## Start the SSH agent and add the key

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

## Copy the public key to the clipboard

```bash
cat ~/.ssh/id_ed25519.pub
```

## Add the public key to Github

Go to [GitHub SSH Settings](https://github.com/settings/ssh/new) and add the public key

## Test the connection

```bash
ssh -T git@github.com
```

# Installation

## Macos

### Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Install git

```bash
brew install git
```

### Clone dotfiles repo into `$HOME`

```bash
git clone git@github.com:klaus-224/.dotfiles.git ~/.dotfiles
```

### Run the setup script

```bash
cd ~/.dotfiles
chmod +x setup-macos.sh
./setup-macos.sh
```

**What this does:**

- Installs Homebrew if missing
- Installs all your CLI tools (fzf, bat, fd, eza, etc.)
- Installs Ghostty terminal via Homebrew
- Installs and configures:
  - Oh My Zsh
  - Powerlevel10k
  - zsh-autosuggestions
  - zsh-syntax-highlighting
- Symlinks your dotfiles using stow
- Installs tmux plugin manager (TPM)
- Runs the FZF setup

## Windows (wsl)

### Open Powershell as Admin

```bash
wsl --install
```

### Update wsl

```bash
wsl --update
wsl --set-default-version 2
```

### Install Ubuntu

```bash
wsl --install -d Ubuntu-22.04
```

### Update Linux Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### Install git

```bash
sudo apt update && sudo apt install -y git
```

### Clone the dotfile repo into `$HOME`

```bash
cd ~
git clone git@github.com:klaus-224/.dotfiles.git ~/.dotfiles
```

### Run the WSL Setup Script

```bash
cd ~/.dotfiles
chmod +x setup-wsl.sh
./setup-wsl.sh
```

**What this does:**

- Install required CLI tools (tmux, zsh, neovim, etc.)
- Install Alacritty on Windows via winget
- Install and configure Oh My Zsh, Powerlevel10k, and Zsh plugins
- Symlink dotfiles using stow
- Install tmux plugin manager (TPM)

# Tmux Commands

- `ctrl-s + r`: reload tmux
- `ctrl-s + ctrl-I`: install tpm plugins
- need latest version of `bash` for sessionx => `brew install bash`

# TODO

WSL Steps:

- install homebrew

- [ ] add powerlevel10K to .dotfiles
- [ ] command to source neovim after install
- [ ] command to source .zshrc
- [ ] add install for eza
- [ ] remove mcaffee from windows
- [ ] add zen browser install
- [ ] need to install lazygit
- [ ] add some goodies:
      https://sidneyliebrand.io/blog/how-fzf-and-ripgrep-improved-my-workflow
      https://www.youtube.com/watch?v=CbMbGV9GT8I&t=56s

# References

- https://www.youtube.com/watch?v=y6XCebnB9gs&t=166s
- https://www.youtube.com/watch?v=03KsS09YS4E
