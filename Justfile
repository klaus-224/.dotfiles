default:
  just --list

rebuild:
    sudo darwin-rebuild switch --flake ~/.dotfiles#klaus-macbook

rebuild-work:
    sudo darwin-rebuild switch --flake ~/.dotfiles#work-macbook

update:
    nix flake update
    sudo darwin-rebuild switch --flake ~/.dotfiles#klaus-macbook

update-work:
    nix flake update
    sudo darwin-rebuild switch --flake ~/.dotfiles#work-macbook

check:
    nix flake check
