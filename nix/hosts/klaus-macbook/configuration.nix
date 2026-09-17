{ pkgs, username, ... }:

{
  homebrew.casks = [
    "raycast"
    "spotify"
  ];

  home-manager.users.${username}.home.packages = with pkgs; [
    nodejs
    pnpm
    bun
    postgres-language-server
  ];
}
