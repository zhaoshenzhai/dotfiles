{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

        darwin.url = "github:nix-darwin/nix-darwin/master";
        darwin.inputs.nixpkgs.follows = "nixpkgs";

        home-manager.url = "github:nix-community/home-manager/master";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";

        nixvim.url = "github:nix-community/nixvim";
        nixvim.inputs.nixpkgs.follows = "nixpkgs";

        yt-dlp-master = { url = "github:yt-dlp/yt-dlp"; flake = false; };
    };

    outputs = inputs@{ nixpkgs, home-manager, darwin, nixvim, ... }: {
        darwinConfigurations.puppy = darwin.lib.darwinSystem {
            pkgs = import nixpkgs {
                system = "aarch64-darwin";
                overlays = [
                    (final: prev: {
                        yt-dlp = prev.yt-dlp.overrideAttrs (oldAttrs: {
                            version = "nightly-${inputs.yt-dlp-master.shortRev or "dirty"}";
                            src = inputs.yt-dlp-master;
                        });
                    })
                ];
            };

            system = "aarch64-darwin";
            specialArgs = { inherit inputs; };

            modules = [
                ./modules/darwin
                home-manager.darwinModules.home-manager {
                    home-manager = {
                        useGlobalPkgs = true;
                        useUserPackages = true;
                        extraSpecialArgs = { inherit inputs; };

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
