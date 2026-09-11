{
  ...
}:

{
  profiles = {
    work = {
      extends = [ "base" ];
      module = import ./modules/work.nix;
    };

    dotfiles = {
      extends = [ "base" ];
      module = import ./modules/dotfiles.nix;
    };

  };
}
