{
  pkgs,
  opencodePkgs,
  ...
}:

{
  home.packages = with pkgs; [
    pkg-config
    ripgrep
    just
    gnumake
    tmux
    gh
    glow
    bottom
    tree
    neovim
    awscli2
    duckdb

    opencodePkgs.opencode
    # 2.3.1 broken right now
    # devenv
  ];

  programs.fzf.enable = true;
  programs.jq.enable = true;
  programs.fd.enable = true;
  programs.eza.enable = true;
  programs.bat.enable = true;
}
