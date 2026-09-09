{ pkgs, ... }:

{
  home.username = "klaus224";
  home.homeDirectory = "/Users/klaus224";
  home.stateVersion = "26.05";
  home.packages = with pkgs; [

  ];

  xdg.configFile."nvim".source = ../nvim;
  xdg.configFile."ghostty".source = ../ghostty;
}
