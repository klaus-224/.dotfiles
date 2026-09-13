{ pkgs, ... }:
{
  languages.rust = {
    enable = true;
    channel = "stable";
  };

  packages = with pkgs; [
    nodejs
    pnpm
    python3
    awscli2
    duckdb
    biome
    sleek
    typescript-language-server
    svelte-language-server
    sql-language-server
    tree-sitter
    gnumake
    pkg-config
    shellcheck
  ];

}
