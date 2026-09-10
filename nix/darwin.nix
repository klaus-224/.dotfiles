{ pkgs, ... }:

{
  nix.enable = false;

  system.primaryUser = "klaus224";
  nixpkgs.hostPlatform = "aarch64-darwin";

  programs.zsh.enable = true;

  environment.variables = {
    ZSH_AUTOSUGGESTIONS =
      "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";

    ZSH_SYNTAX_HIGHLIGHTING =
      "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";

    ZSH_COMPLETIONS =
      "${pkgs.zsh-completions}/share/zsh/site-functions";
  };

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;

    finder = {
      AppleShowAllExtensions = true;
    };
  };

  users.users.klaus224 = {
    name = "klaus224";
    home = "/Users/klaus224";
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  system.stateVersion = 6;
}
