{
  username,
  ...
}:

{
  imports = [
    ./files.nix
    ./packages.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "26.05";

    # Expose executable helpers to child processes, not just interactive aliases.
    sessionPath = [ "$HOME/.local/bin" ];
  };
}
