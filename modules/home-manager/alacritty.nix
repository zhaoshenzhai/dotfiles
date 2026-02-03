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
                padding = { x = 10; y = 10; };
                decorations = "buttonless";
                dynamic_title = true;
                opacity = 0.5;
                blur = true;
            };

            selection.save_to_clipboard = true;
            bell.duration = 0;

            colors = {
                primary = {
                    background = "#1e2127";
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
}
