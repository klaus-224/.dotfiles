{config, pkgs, ... }:

{
  home.username = "klaus224";
  home.homeDirectory = "/Users/klaus224";
  home.stateVersion = "26.05";
  home.packages = with pkgs; [
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    # aws-cdk
    # awscli2
    # bat
    # bottom
    # duckdb
    # fd
    # gcc
    # gh
    # glow
    # jq
    # just
    # lazygit
    # lua
    # lua-language-server
    # neovim
    # ripgrep
    # rustup
    # sqlite
    # supabase-cli
    # terraform
    # tmux
    # tree
    # tree-sitter
    # uv
    # watchman
    # yaml-language-server
  ];

  programs.fzf.enable = true;
  # programs.git.enable = true;
  programs.eza.enable = true;

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/nvim";
  
  xdg.configFile."ghostty".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/ghostty";

  xdg.configFile."gh-dash".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/git/gh-dash";

  home.file.".tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/tmux/.tmux.conf";

  home.file.".zshenv".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/zsh/.zshenv";
  
  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/zsh/.zshrc";
  
  home.file.".zshrc.d".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/zsh/.zshrc.d";

  home.file.".gitconfig".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/git/.gitconfig";

  home.file.".gitconfig.local".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/git/.gitconfig.local";

  home.file.".gitignore.global".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.dotfiles/git/.gitignore.global";
}
