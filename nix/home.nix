{config, pkgs, ... }:

{
  home.username = "klaus224";
  home.homeDirectory = "/Users/klaus224";
  home.stateVersion = "26.05";
    
  # configs managed by me 
  home.packages = with pkgs; [
    # core tooling
    git
    neovim
    ripgrep
    just
    lazygit
    tmux
    gh
    glow
    bottom
    tree
    starship

    # shell support
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions

    # general-purpose CLIs
    awscli2
    duckdb

    # llm
    opencode

    # global editor/LSP fallback
    yaml-language-server
    vscode-langservers-extracted
    tombi
  ];

  # configs managued by home-manager 
  programs.fzf.enable = true;
  programs.jq.enable = true;
  programs.fd.enable = true;
  programs.eza.enable = true;
  programs.bat.enable = true;

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
}
