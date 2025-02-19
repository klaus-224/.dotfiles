## Requirements

Ensure you have these installed:

### Git

OSX
```
brew install git
```
Linux
```
pacman -s git
```

### Stow
```
brew install stow
```

```
pacman -S stow
```

## Installation

First, checkout the dotfiles repo in your $HOME directory using git

```bash
$ git clone git@github.com:klaus-224/.dotfiles.git
$ cd dotfiles
```

Use `stow` to symlink the files into the `$HOME` dir

```bas
$ stow .
```

## TODO
-   [ ] create a shell script to setup my configuration

## References
https://www.youtube.com/watch?v=y6XCebnB9gs&t=166s
https://www.youtube.com/watch?v=03KsS09YS4E


