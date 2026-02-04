{ config, pkgs, lib, ... }: {
    manual.json.enable = false;
    home.stateVersion = "22.11";
    home.file = { ".hushlogin".text = ""; };

    home.sessionVariables = {
        EDITOR = "nvim";
        SHELL_SESSIONS_DISABLE = "1";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=${config.home.homeDirectory}/.cache/dbus-session-socket";
    };

    home.packages = with pkgs; [
        # System
        coreutils
        aerospace
        alacritty
        dbus

        # Ricing
        jankyborders
        sketchybar
        neofetch
        btop
        jq

        # TeX and pdfs
        texlive.combined.scheme-full
        ocamlPackages.cpdf
        pdftk
        zathura
        neovim-remote
        poppler-utils

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
        ./sketchybar.nix
        ./qutebrowser.nix
    ];

    xdg.configFile = {
        "aerospace/aerospace.toml".source = ./aerospace.toml;
    };

    launchd.agents.dbus = {
        enable = true;
        config = {
            Label = "org.nix-community.home.dbus";
            ProgramArguments = [
                "${pkgs.dbus}/bin/dbus-daemon"
                "--nofork"
                "--config-file=${pkgs.dbus}/share/dbus-1/session.conf"
                "--address=unix:path=${config.home.homeDirectory}/.cache/dbus-session-socket"
            ];
            KeepAlive = true;
            ProcessType = "Interactive";
            StandardOutPath = "${config.home.homeDirectory}/.cache/dbus.log";
            StandardErrorPath = "${config.home.homeDirectory}/.cache/dbus.err";
        };
    };

    home.activation.initDbus = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.cache"
        $DRY_RUN_CMD ${pkgs.dbus}/bin/dbus-uuidgen --ensure
    '';
}
