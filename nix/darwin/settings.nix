{ ... }:

{
  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
      show-recents = false;
    };

    finder.AppleShowAllExtensions = true;
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
