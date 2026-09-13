{ pkgs, ... }:
{
  packages = with pkgs; [
    pnpm
    lua-language-server
    shellcheck
    nixd
    nixfmt
    oxfmt
  ];

}
