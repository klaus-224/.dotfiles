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
        start_service = true;
      }
      {
        name = "FelixKratz/formulae/sketchybar";
        trusted = true;
        start_service = true;
      }
      {
        name = "rtk";
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
