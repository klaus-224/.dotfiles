{
  ...
}:

{
  profiles = {
    work = {
      module = import ./modules/work.nix;
    };

    dotfiles = {
      module = import ./modules/dotfiles.nix;
    };

  };
}
