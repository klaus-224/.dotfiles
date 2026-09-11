{
  ...
}:

{
  profiles = {
    base.module = import ./modules/base.nix;

    work = {
      extends = [ "base" ];
      module = import ./modules/work.nix;
    };

    personal = {
      extends = [ "base" ];
      module = import ./modules/personal.nix;
    };

    dotfiles = {
      extends = [ "base" ];
      module = import ./modules/dotfiles.nix;
    };
  };
}
