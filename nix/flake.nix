{
  description = "Klaus's macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    self,
    nixpkgs,
    darwin,
    home-manager,
    ...
  }:
    let
      mkDarwinConfiguration =
        {
          username,
          profile,
          system ? "aarch64-darwin",
        }:
        darwin.lib.darwinSystem {
          inherit system;

          specialArgs = {
            inherit inputs username profile system;
          };

          modules = [
            ./darwin.nix

            home-manager.darwinModules.home-manager

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { 
                  inherit  username profile;
                };
                users.${username} = ./home.nix;
              };
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        klaus-macbook = mkDarwinConfiguration {
          username = "klaus224";
          profile = "personal";
        };

        work-macbook = mkDarwinConfiguration {
          username = "rohineshram";
          profile = "work";
        };
      };
    };
}
