{ pkgs, ... }:
let
    zathuraSync = pkgs.writeShellScriptBin "zathura-sync" ''
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-custom-$(whoami)"
        LINE="$1"
        COL="$2"
        TEX="$3"
        PDF="$4"

        ${pkgs.zathura}/bin/zathura --synctex-forward "$LINE:$COL:$TEX" "$PDF" 2>/dev/null
        if [ $? -ne 0 ]; then
            ${pkgs.zathura}/bin/zathura "$PDF" &
        fi
      '';
in {
    manual.json.enable = false;
    home.stateVersion = "22.11";

    home.sessionVariables = {
        EDITOR = "nvim";
        SHELL_SESSIONS_DISABLE = "1";
    };

    home.packages = with pkgs; [
        coreutils
        dbus
        aerospace
        zathura
        zathuraSync
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
    home.sessionVariables = {
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/tmp/dbus-launch"; 
    };

    xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

    programs = {
        fzf = {
            enable = true;
            enableZshIntegration = true;
        };
    };
}
