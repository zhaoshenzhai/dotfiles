{ config, pkgs, lib, ... }: {
    manual.json.enable = false;
    home.stateVersion = "22.11";
    home.file = { ".hushlogin".text = ""; };
    home.sessionVariables = { EDITOR = "nvim"; };

    home.packages = with pkgs; [
        # System
        coreutils
        aerospace
        alacritty

        # Ricing
        jankyborders
        sketchybar
        neofetch
        btop
        jq

        # Bluetooth
        switchaudio-osx
        blueutil

        # pdfs
        texlive.combined.scheme-full
        ocamlPackages.cpdf
        pdftk
        neovim-remote
        poppler-utils

        # COMP308
        dosbox-staging
    ];

    imports = [
        ./zsh.nix
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
