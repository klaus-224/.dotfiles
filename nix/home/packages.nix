{
  pkgs,
  # opencodePkgs,
  ...
}:

{
  home.packages = with pkgs; [
    pkg-config
    python3 # SketchyBar notification plists and connectivity status (stdlib only).
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

    # opencode v2 broken 
    # opencodePkgs.opencode
  ];

  programs.fzf.enable = true;
  programs.jq.enable = true;
  programs.fd.enable = true;
  programs.eza.enable = true;
  programs.bat.enable = true;
}
