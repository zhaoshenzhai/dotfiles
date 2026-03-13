{ pkgs, ... }: {
    programs.alacritty = {
        enable = true;

        settings = {
            font = {
                size = 20.0;
                normal = {
                    family = "Courier Prime";
                    style = "Regular";
                };
                bold = {
                    family = "Courier Prime";
                    style = "Bold";
                };
                italic = {
                    family = "Courier Prime";
                    style = "Italic";
                };
            };

            window = {
                padding = { x = 10; y = 25; };
                decorations = "transparent";
                dynamic_padding = false;
                opacity = 0.5;
                blur = true;
            };

            selection.save_to_clipboard = true;
            bell.duration = 0;

            colors = {
                primary = {
                    background = "#111111";
                    foreground = "#abb2bf";
                };
                normal = {
                    black   = "#1e2127";
                    red     = "#e06c75";
                    green   = "#98c379";
                    yellow  = "#d19a66";
                    blue    = "#61afef";
                    magenta = "#c678dd";
                    cyan    = "#56b6c2";
                    white   = "#abb2bf";
                };
                bright = {
                    black   = "#5c6370";
                    red     = "#e06c75";
                    green   = "#98c379";
                    yellow  = "#d19a66";
                    blue    = "#61afef";
                    magenta = "#c678dd";
                    cyan    = "#56b6c2";
                    white   = "#abb2bf";
                };
            };
        };
    };

    xdg.configFile."alacritty/btop.toml".text = ''
        general.import = [ "~/.config/alacritty/alacritty.toml" ]

        [[keyboard.bindings]]
        key = "Q"
        command = { program = "sh", args = ["-c", "aerospace close --quit-if-last-window"] }
    '';
}
