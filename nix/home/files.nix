{ config, username, ... }:

let
  opencodeProfile = if username == "klaus224" then "personal" else "work";
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  xdg.configFile = {
    nvim.source = link "nvim";
    ghostty.source = link "ghostty";
    gh-dash.source = link "git/gh-dash";

    opencode.source = link "opencode/${opencodeProfile}";
    mise.source = link "mise";
    aerospace.source = link "aerospace";
    sketchybar.source = link "sketchybar";
    borders.source = link "borders";
    "gh/config.yml".source = link "gh/config.yml";
  };

  home.file = {
    ".tmux.conf".source = link "tmux/.tmux.conf";
    ".zshenv".source = link "zsh/.zshenv";
    ".zshrc".source = link "zsh/.zshrc";
    ".zshrc.d".source = link "zsh/.zshrc.d";
    ".gitconfig".source = link "git/.gitconfig";
  };
}
