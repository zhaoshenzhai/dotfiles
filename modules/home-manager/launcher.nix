{ pkgs, lib, config, ... }:

let
    runtimePath = lib.makeBinPath [
        pkgs.fzf
        pkgs.neovim
        pkgs.alacritty
    ];

    launcher = pkgs.writeShellScriptBin "launcher" ''
        export PATH="${runtimePath}:/usr/bin:$PATH"

        if [ -f "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh" ]; then
            . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
        fi

        export FZF_DEFAULT_OPTS="--color='bg+:-1,gutter:-1,pointer:#98c379'"

        ${builtins.readFile ./launcher.sh}
    '';
in
{
    home.packages = [ launcher pkgs.fzf ];
    xdg.configFile."alacritty/launcher.toml".text = ''
        [window]
        decorations = "transparent"
        startup_mode = "Windowed"
        title = "launcher"
        dimensions = { columns = 120, lines = 15 }
        padding = { x = 20, y = 25 }
        position = { x = 275, y = 400 }
        
        opacity = 0.5
        blur = true

        [font]
        normal = { family = "Courier Prime" }
        size = 20.0
        offset = { x = 0, y = 12 }

        [cursor]
        style = { shape = "Beam", blinking = "On" }

        [colors.primary]
        background = "#111111"
        foreground = "#abb2bf"

        [colors.cursor]
        cursor = "#abb2bf"

        [colors.normal]
        red     = "#e06c75"
        green   = "#98c379"
        yellow  = "#d19a66"
        blue    = "#61afef"
        magenta = "#c678dd"
        cyan    = "#56b6c2"
    '';
}
