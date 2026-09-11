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
    nixpkgs,
    darwin,
    home-manager,
    ...
  }:
    let
      mkDarwinConfiguration =
        {
          username,
          system ? "aarch64-darwin",
        }:
        darwin.lib.darwinSystem {
          inherit system;

          specialArgs = {
            inherit inputs username system;
          };

          modules = [
            ./nix/darwin.nix

            home-manager.darwinModules.home-manager

            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = { inherit username; };
                users.${username} = ./nix/home.nix;
              };
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        klaus-macbook = mkDarwinConfiguration {
          username = "klaus224";
        };

        work-macbook = mkDarwinConfiguration {
          username = "rohineshram";
        };
      };
    };
}
