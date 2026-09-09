{ pkgs, ... }:

{
  nix.enable = false;

  system.primaryUser = "klaus224";
  nixpkgs.hostPlatform = "aarch64-darwin";

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    git
  ];

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
