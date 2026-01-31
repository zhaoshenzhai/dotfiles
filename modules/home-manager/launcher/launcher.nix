{ pkgs, lib, config, ... }:

let
    runtimePath = lib.makeBinPath [
        pkgs.fzf
        pkgs.zathura
        pkgs.neovim
        pkgs.alacritty
    ];

    launcher = pkgs.writeShellScriptBin "launcher" ''
        export PATH="${runtimePath}:/usr/bin:$PATH"
        
        if [ -f "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh" ]; then
            . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
        fi

        ${builtins.readFile ./launcher.sh}
    '';
in
{
    home.packages = [ launcher pkgs.fzf ];
    xdg.configFile."alacritty/launcher.toml".text = ''
        [window]
        decorations = "none"
        startup_mode = "Windowed"
        title = "launcher"
        dimensions = { columns = 120, lines = 15 }
        padding = { x = 20, y = 20 }
        position = { x = 275, y = 400 }
        
        opacity = 0.5
        blur = true

        [font]
        normal = { family = "Courier Prime" }
        size = 20.0
        offset = { x = 0, y = 12 }

        [colors.primary]
        background = "#282c34"
        foreground = "#abb2bf"

        [colors.cursor]
        text = "#282c34"
        cursor = "#61afef"

        [colors.normal]
        red     = "#e06c75"
        green   = "#98c379"
        yellow  = "#d19a66"
        blue    = "#61afef"
        magenta = "#c678dd"
        cyan    = "#56b6c2"
    '';
}
