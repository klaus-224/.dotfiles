{ pkgs, username, ... }:

{
  home-manager.users.${username}.home.packages = with pkgs; [
    rustc
    cargo
    biome
    sqls
    pkg-config
  ];
}
