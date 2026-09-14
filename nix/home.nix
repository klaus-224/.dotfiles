{
  config,
  pkgs,
  username,
  profile,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # guis
    raycast
    spotify

    # core tooling
    git
    ripgrep
    just
    tmux
    gh
    glow
    bottom
    tree
    starship
    neovim
    marksman
    tree-sitter

    devenv

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
    "devenv/config.yaml".source = link "devenv/config.yaml";
  };

  home.file = {
    ".dotfiles/opencode/opencode.jsonc".source = link "opencode/opencode.${profile}.jsonc";
    ".tmux.conf".source = link "tmux/.tmux.conf";
    ".zshenv".source = link "zsh/.zshenv";
    ".zshrc".source = link "zsh/.zshrc";
    ".zshrc.d".source = link "zsh/.zshrc.d";
    ".gitconfig".source = link "git/.gitconfig";
    ".local/bin".source = link "bin";
  };
}
