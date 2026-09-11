{ pkgs, ... }:
{
  languages.rust = {
    languages.rust = {
      enable = true;
      channel = "stable";
    };
  };

  packages = with pkgs; [
    node
    pnpm
    python
    uv
    awscli2
    duckdb

    # shell stuff i think?
    shellcheck
    pkg-config

    # rust
    rust
    bacon

    # formatter, linter
    biome
  ];

}
