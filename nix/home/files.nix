{ config, username, ... }:

let
  opencodeProviders =
    if username == "klaus224" then [ "openai" "opencode" ] else [ "github-copilot" "github-copilot" ];
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  xdg.configFile = {
    nvim.source = link "nvim";
    ghostty.source = link "ghostty";
    gh-dash.source = link "git/gh-dash";

    "opencode/opencode.jsonc".text = builtins.replaceStrings
      [ "@primary-provider@" "@secondary-provider@" ]
      opencodeProviders
      (builtins.readFile ../../opencode/opencode.jsonc);
    "opencode/opencode.schema.json".source = link "opencode/opencode.schema.json";
    "opencode/cli.json".source = link "opencode/cli.json";
    "opencode/AGENTS.md".source = link "opencode/AGENTS.md";
    "opencode/agents".source = link "opencode/agents";
    "opencode/commands".source = link "opencode/commands";
    "opencode/skills".source = link "opencode/skills";
    "opencode/plugins".source = link "opencode/plugins";
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
