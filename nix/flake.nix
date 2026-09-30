{
  description = "Klaus's macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # opencode.url = "github:anomalyco/opencode/v2.0.18";

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{
    self,
    nixpkgs,
    darwin,
    ...
  }:
    let
      mkDarwinConfiguration =
        {
          username,
          hostModule,
          system ? "aarch64-darwin",
        }:
        darwin.lib.darwinSystem {
          inherit system;

          specialArgs = {
            inherit inputs username system;
            # opencodePkgs = inputs.opencode.packages.${system};
          };

          modules = [
            ./darwin
            hostModule
          ];
        };
    in
    {
      darwinConfigurations = {
        klaus-macbook = mkDarwinConfiguration {
          username = "klaus224";
          hostModule = ./hosts/klaus-macbook/configuration.nix;
        };

        work-macbook = mkDarwinConfiguration {
          username = "rohineshram";
          hostModule = ./hosts/work-macbook/configuration.nix;
        };
      };
    };
}
