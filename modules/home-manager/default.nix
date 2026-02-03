{ config, pkgs, ... }: {
    home.stateVersion = "22.11";
    home.file = { ".hushlogin".text = ""; };

    home.sessionVariables = {
        EDITOR = "nvim";
        SHELL_SESSIONS_DISABLE = "1";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/Users/zhao/.cache/dbus-session-socket";
    };

    home.packages = with pkgs; [
        # System
        coreutils
        btop
        neofetch
        aerospace
        alacritty
        jankyborders
        # sketchybar
        # sketchybar-app-font

        # TeX and pdfs
        texlive.combined.scheme-full
        ocamlPackages.cpdf
        pdftk
        zathura
        neovim-remote
        dbus

        #Fonts
        courier-prime
        nerd-fonts.symbols-only
        nerd-fonts.jetbrains-mono

        # COMP308
        dosbox-staging
    ];

    imports = [
        ./zsh.nix
        ./nvim.nix
        ./vifm.nix
        ./zathura.nix
        ./borders.nix
        ./starship.nix
        ./launcher.nix
        ./alacritty.nix
        # ./sketchybar.nix
        ./qutebrowser.nix
    ];

    xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

    launchd.agents.dbus = {
        enable = true;
        config = {
            ProgramArguments = [
                "${pkgs.dbus}/bin/dbus-daemon"
                "--session"
                "--address=unix:path=${config.home.homeDirectory}/.cache/dbus-session-socket"
                "--nofork"
            ];
            KeepAlive = true;
            ProcessType = "Interactive";
        };
    };
}
