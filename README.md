## Requirements

Ensure you have these installed:

### Git

OSX

```
brew install git
```

### Stow

osX
```
brew install stow
```

### tmux

```
brew install tmux
```

### neovim

```
brew install neovim
```

### lazygit

```
brew install lazygit
```

## Installation

First, checkout the dotfiles repo in your $HOME directory using git

```bash
$ git clone git@github.com:klaus-224/.dotfiles.git
$ cd dotfiles
```

Use `stow` to symlink the files into the `$HOME` dir

```bash
$ stow .
```

## Tmux
-   `ctrl-s + r`: reload tmux
-   `ctrl-s + ctrl-I`: install tpm plugins
-   need latest version of `bash` for sessionx => `brew install bash`

## TODO

- [ ] create a shell script to setup my configuration

## References

https://www.youtube.com/watch?v=y6XCebnB9gs&t=166s
https://www.youtube.com/watch?v=03KsS09YS4E
