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
    # Offline configuration validation is available on both hosts.
    python3
    shellcheck
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
    rustc
    cargo

    biome
    typescript-language-server
    svelte-language-server
    sqls

    pkg-config
  ];
in
{
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "26.05";
  # Expose executable helpers to child processes, not just interactive aliases.
  home.sessionPath = [ "$HOME/.local/bin" ];

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
    # Own only these names, not the directory. Preserve unmanaged executables.
    # Keep source executable modes; do not chmod through live links on activation.
    ".local/bin/awv".source = link "bin/awv";
    ".local/bin/ctx".source = link "bin/ctx";
    ".local/bin/envv".source = link "bin/envv";
    ".local/bin/gfd".source = link "bin/gfd";
    ".local/bin/journal".source = link "bin/journal";
    ".local/bin/pathv".source = link "bin/pathv";
    ".local/bin/personal-journal".source = link "bin/personal-journal";
    ".local/bin/pjs".source = link "bin/pjs";
    ".local/bin/playwright_docs".source = link "bin/playwright_docs";
    ".local/bin/secrets".source = link "bin/secrets";
    ".local/bin/sparse-get".source = link "bin/sparse-get";
    ".local/bin/sqb".source = link "bin/sqb";
  };
}
