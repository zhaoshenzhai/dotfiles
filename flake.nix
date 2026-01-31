{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

        darwin.url = "github:nix-darwin/nix-darwin/master";
        darwin.inputs.nixpkgs.follows = "nixpkgs";

        home-manager.url = "github:nix-community/home-manager/master";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";

        nixvim.url = "github:nix-community/nixvim";
        nixvim.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = inputs@{ nixpkgs, home-manager, darwin, nixvim, ... }: {
        darwinConfigurations.puppy = darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            pkgs = import nixpkgs { system = "aarch64-darwin"; };

            modules = [
                ./modules/darwin
                home-manager.darwinModules.home-manager {
                    home-manager = {
                        useGlobalPkgs = true;
                        useUserPackages = true;           
                        users.zhao = {
                            imports = [
                                ./modules/home-manager
                                nixvim.homeModules.nixvim
                            ];
                        };
                    };
                }
            ];
        }; 
    };
}
