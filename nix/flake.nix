{
  description = "Klaus's macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-opencode.url = "github:NixOS/nixpkgs/5dbaca36ed1e5ce78fc33775124a54b3906dd585";

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
            opencodePkgs = import inputs.nixpkgs-opencode {
              inherit system;
            };
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
