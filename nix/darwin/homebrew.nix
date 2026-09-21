{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = true;
      cleanup = "zap";
    };

    global.brewfile = true;

    brews = [
      {
        name = "FelixKratz/formulae/borders";
        trusted = true;
      }
      {
        name = "FelixKratz/formulae/sketchybar";
        trusted = true;
      }
    ];

    casks = [
      {
        name = "nikitabobko/tap/aerospace";
        trusted = true;
      }
      "arc"
      "ghostty"
      "docker-desktop" # TODO replace with docker daemon
      "raycast"
      "spotify"
    ];
  };
}
