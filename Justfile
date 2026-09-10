default:
  just --list

rebuild:
    sudo darwin-rebuild switch --flake ~/.dotfiles#klaus-macbook

update:
    nix flake update
    sudo darwin-rebuild switch --flake ~/.dotfiles#klaus-macbook
check:
    nix flake check
