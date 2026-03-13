{ config, pkgs, lib, ... }: {
    manual.json.enable = false;
    home.stateVersion = "22.11";
    home.file = { ".hushlogin".text = ""; };
    home.sessionVariables = { EDITOR = "nvim"; };

    home.packages = with pkgs; [
        aerospace
        switchaudio-osx
        blueutil

        dosbox-staging
    ];

    imports = [
        ./zsh.nix
        ./mpv.nix
        ./nvim.nix
        ./vifm.nix
        ./skim.nix
        ./borders.nix
        ./starship.nix
        ./launcher.nix
        ./alacritty.nix
        ./karabiner.nix
        ./sketchybar.nix
        ./qutebrowser.nix
    ];

    xdg.configFile = {
        "aerospace/aerospace.toml".source = ./aerospace.toml;
    };
}
