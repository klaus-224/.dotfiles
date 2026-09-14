{
  config,
  pkgs,
  username,
  profile,
  opencodePkgs,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";

  commonPackages = with pkgs; [
    git
    ripgrep
    just
    gnumake
    tmux
    gh
    glow
    bottom
    tree
    starship
    neovim
    marksman
    tree-sitter

    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions

    awscli2
    duckdb
    # opencode

    yaml-language-server
    vscode-langservers-extracted
    lua-language-server
    nixd
    tombi
    # 2.3.1 broken right now 
    # devenv
  ];

  personalPackages = with pkgs; [
    raycast
    spotify

    # personal development
    nodejs
    pnpm
    bun
    postgres-language-server
  ];

  workPackages = with pkgs; [
    nodejs
    pnpm
    bun
    python3
    rustc
    cargo

    biome
    typescript-language-server
    svelte-language-server
    sqls

    pkg-config
    shellcheck
  ];
in
{
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "26.05";

  home.packages =
    commonPackages
    ++ [opencodePkgs.opencode]
    ++ pkgs.lib.optionals (profile == "personal") personalPackages
    ++ pkgs.lib.optionals (profile == "work") workPackages;

  programs.fzf.enable = true;
  programs.jq.enable = true;
  programs.fd.enable = true;
  programs.eza.enable = true;
  programs.bat.enable = true;

  xdg.configFile = {
    nvim.source = link "nvim";
    ghostty.source = link "ghostty";
    gh-dash.source = link "git/gh-dash";
    opencode.source = link "opencode";
  };

  home.file = {
    ".tmux.conf".source = link "tmux/.tmux.conf";
    ".zshenv".source = link "zsh/.zshenv";
    ".zshrc".source = link "zsh/.zshrc";
    ".zshrc.d".source = link "zsh/.zshrc.d";
    ".gitconfig".source = link "git/.gitconfig";
    ".local/bin".source = link "bin";
  };
}
