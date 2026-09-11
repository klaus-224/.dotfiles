{ pkgs, lib, username, system, ... }:

{
  nix.enable = false;

  system.primaryUser = username;

  nixpkgs.hostPlatform = system;

  programs.zsh.enable = true;

  environment.variables = {
    ZSH_AUTOSUGGESTIONS = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";

    ZSH_SYNTAX_HIGHLIGHTING = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";

    ZSH_COMPLETIONS = "${pkgs.zsh-completions}/share/zsh/site-functions";
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "raycast"
      "spotify"
    ];

  homebrew = {
    enable = true;

    casks = [
      "arc"
      "docker"
      "ghostty"
      "docker-desktop" # TODO replace with docker daemon
    ];
  };

  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
    };

    finder = {
      AppleShowAllExtensions = true;
    };
  };

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  system.stateVersion = 6;
}
