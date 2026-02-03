{ config, pkgs, ... }:
let
    dbusSocket = "${config.home.homeDirectory}/.cache/dbus-session-socket";
in {
    manual.json.enable = false;
    home.stateVersion = "22.11";
    home.file = { ".hushlogin".text = ""; };

    home.sessionVariables = {
        EDITOR = "nvim";
        SHELL_SESSIONS_DISABLE = "1";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=${dbusSocket}";
    };

    home.packages = with pkgs; [
        # System
        coreutils
        aerospace
        btop
        neofetch

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
        ./starship.nix
        ./launcher.nix
        ./alacritty.nix
        ./qutebrowser.nix
    ];

    xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

    # launchd.agents.dbus = {
    #     enable = true;
    #     config = {
    #         Label = "org.freedesktop.dbus-session";
    #         ProgramArguments = [
    #             "${pkgs.dbus}/bin/dbus-daemon"
    #             "--nofork"
    #             "--session"
    #             "--address=unix:path=${dbusSocket}"
    #         ];
    #         KeepAlive = true;
    #     };
    # };
}
