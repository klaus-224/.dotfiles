{
  inputs,
  pkgs,
  username,
  system,
  opencodePkgs,
  ...
}:

{
  imports = [
    ./homebrew.nix
    ./settings.nix
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix.enable = false;

  nixpkgs.hostPlatform = system;

  programs.zsh.enable = true;

  environment = {
    systemPackages = with pkgs; [
      git
      mise
      starship
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-completions
    ];

    systemPath = [ "/opt/homebrew/bin" ];

    variables = {
      ZSH_AUTOSUGGESTIONS = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      ZSH_SYNTAX_HIGHLIGHTING = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      ZSH_COMPLETIONS = "${pkgs.zsh-completions}/share/zsh/site-functions";
    };
  };

  nix-homebrew = {
    enable = true;
    autoMigrate = true;
    user = username;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit username opencodePkgs;
    };
    users.${username} = {
      imports = [ ../home ];
    };
  };

  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  system.stateVersion = 6;
}
