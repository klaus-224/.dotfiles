{ pkgs, ... }:

{
  home.username = "klaus224";
  home.homeDirectory = "/Users/klaus224";
  home.stateVersion = "26.05";
  home.packages = with pkgs; [
    aws-cdk
    awscli2
    bat
    bottom
    duckdb
    fd
    gcc
    gh
    glow
    jq
    just
    lazygit
    lua
    lua-language-server
    neovim
    ripgrep
    rustup
    sqlite
    supabase-cli
    terraform
    tmux
    tree
    tree-sitter
    uv
    watchman
    yaml-language-server
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };
  
  programs.fzf.enable = true;
  programs.starship.enable = true;
  programs.git.enable = true;
  programs.eza.enable = true;

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/klaus224/.dotfiles/nvim";

  xdg.configFile."ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/klaus224/.dotfiles/ghostty";}
