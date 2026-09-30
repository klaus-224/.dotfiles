{ config, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  xdg.configFile = {
    nvim.source = link "nvim";
    ghostty.source = link "ghostty";
    gh-dash.source = link "git/gh-dash";

    opencode.source = link "opencode";
    mise.source = link "mise";
    aerospace.source = link "aerospace";
    borders.source = link "borders";
    sketchybar.source = link "sketchybar";
    "gh/config.yml".source = link "gh/config.yml";
    # manually link everything till env vars work https://github.com/anomalyco/opencode/issues/36990)
    "opencode/agents".source = link "${dotfiles}/opencode/agents";
    "opencode/commands".source = link "${dotfiles}/opencode/commands";
    "opencode/skills".source = link "${dotfiles}/opencode/skills";
    "opencode/tools".source = link "${dotfiles}/opencode/tools";

    "opencode/opencode.jsonc".source =
      link "${dotfiles}/opencode/personal/opencode.jsonc";
  };

  home.file = {
    ".tmux.conf".source = link "tmux/.tmux.conf";
    ".zshenv".source = link "zsh/.zshenv";
    ".zshrc".source = link "zsh/.zshrc";
    ".zshrc.d".source = link "zsh/.zshrc.d";
    ".gitconfig".source = link "git/.gitconfig";
  };
}
