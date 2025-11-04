## Requirements

## Installation

First, checkout the dotfiles repo in your $HOME directory using git

```bash
$ git clone git@github.com:klaus-224/.dotfiles.git
$ cd dotfiles
```

Run:

```

chmod +x install.sh
./install.sh

```

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

## Installation

## Tmux Commands

- `ctrl-s + r`: reload tmux
- `ctrl-s + ctrl-I`: install tpm plugins
- need latest version of `bash` for sessionx => `brew install bash`

## TODO

- [ ] create a shell script to setup my configuration
- [ ] add some goodies:
      https://sidneyliebrand.io/blog/how-fzf-and-ripgrep-improved-my-workflow
      https://www.youtube.com/watch?v=CbMbGV9GT8I&t=56s

## References

https://www.youtube.com/watch?v=y6XCebnB9gs&t=166s
https://www.youtube.com/watch?v=03KsS09YS4E

```

```
