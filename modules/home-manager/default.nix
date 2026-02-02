{ config, pkgs, ... }:
let
    dbusSocket = "${config.home.homeDirectory}/.cache/dbus-session-socket";
in {
    manual.json.enable = false;
    home.stateVersion = "22.11";

    home.sessionVariables = {
        EDITOR = "nvim";
        SHELL_SESSIONS_DISABLE = "1";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=${dbusSocket}";
    };

    home.packages = with pkgs; [
        coreutils
        dbus
        htop
        aerospace
        zathura
        pdftk
        ocamlPackages.cpdf
        neofetch
        courier-prime
        texlive.combined.scheme-full
        neovim-remote
        nerd-fonts.symbols-only
        nerd-fonts.jetbrains-mono
    ];

    imports = [
        ./zsh.nix
        ./nvim.nix
        ./vifm.nix
        ./zathura.nix
        ./starship.nix
        ./alacritty.nix
        ./launcher.nix
        ./qutebrowser.nix
    ];

    home.file = { ".hushlogin".text = ""; };
    xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

    programs = {
        fzf = {
            enable = true;
            enableZshIntegration = true;
        };
    };

    launchd.agents.dbus = {
        enable = true;
        config = {
            Label = "org.freedesktop.dbus-session";
            ProgramArguments = [
                "${pkgs.dbus}/bin/dbus-daemon"
                "--nofork"
                "--session"
                "--address=unix:path=${dbusSocket}"
            ];
            KeepAlive = true;
        };
    };
}
