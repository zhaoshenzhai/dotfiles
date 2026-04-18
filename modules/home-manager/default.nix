{ config, pkgs, lib, ... }: {
    manual.json.enable = false;
    manual.manpages.enable = false;
    manual.html.enable = false;

    home.stateVersion = "22.11";
    home.file = { ".hushlogin".text = ""; };
    programs.swaylock.enable = false;

    home.sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        TERMINAL = "alacritty";
    };

    home.packages = with pkgs; [
        aerospace
        (texlive.combine { inherit (texlive) scheme-full latexmk; })
    ];

    imports = [
        ./zsh.nix
        ./mpv.nix
        ./nvim.nix
        ./vifm.nix
        ./skim.nix
        ./borders.nix
        ./starship.nix
        ./alacritty.nix
        ./karabiner.nix
        ./sketchybar.nix
        ./qutebrowser.nix
    ];

    xdg.configFile = { "aerospace/aerospace.toml".source = ./aerospace.toml; };
}
