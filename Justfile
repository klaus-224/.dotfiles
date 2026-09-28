repo := justfile_directory()

default:
  @just --justfile {{quote(justfile())}} --list

rebuild:
    sudo darwin-rebuild switch --flake ~/.dotfiles/nix#klaus-macbook

rebuild-work:
    sudo darwin-rebuild switch --flake ~/.dotfiles/nix#work-macbook

update:
    cd nix && nix flake update
    sudo darwin-rebuild switch --flake ~/.dotfiles/nix#klaus-macbook

update-work:
    cd nix && nix flake update
    sudo darwin-rebuild switch --flake ~/.dotfiles/nix#work-macbook

clean:
    nix-collect-garbage -d
    sudo nix-collect-garbage -d
    nix store optimise
