{pkgs, ... }: {
    manual.json.enable = false;
    home.stateVersion = "22.11";
    home.sessionVariables = { EDITOR = "nvim"; };
    home.packages = with pkgs; [
        coreutils
        zathura
        aerospace
        tree
        neofetch
        courier-prime
        nerd-fonts.symbols-only
        nerd-fonts.jetbrains-mono
    ];

    imports = [
        ./zsh.nix
        ./vifm.nix
        ./zathura.nix
        ./starship.nix
        ./nvim/nvim.nix
        ./alacritty.nix
        ./launcher/launcher.nix
        ./qutebrowser/qutebrowser.nix
    ];

    home.file = {
        ".hushlogin".text = "";
        ".aerospace.toml".source = ./aerospace.toml;
    };

    programs = {
        fzf = {
            enable = true;
            enableZshIntegration = true;
        };
    };
}
