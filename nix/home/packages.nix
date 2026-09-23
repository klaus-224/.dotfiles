{
  pkgs,
  opencodePkgs,
  ...
}:

{
  home.packages = with pkgs; [
    ripgrep
    just
    python3
    shellcheck
    gnumake
    tmux
    gh
    glow
    bottom
    tree
    neovim
    marksman
    tree-sitter
    awscli2
    duckdb

    # 2.3.1 broken right now
    # devenv

    opencodePkgs.opencode
  ];

  programs.fzf.enable = true;
  programs.jq.enable = true;
  programs.fd.enable = true;
  programs.eza.enable = true;
  programs.bat.enable = true;
}
