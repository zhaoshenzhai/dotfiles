{ pkgs, ... }: {
    programs.zathura = {
        enable = true;

        options = {
            default-fg              = "#A6B5C5";
            default-bg              = "#141A1F";

            statusbar-bg            = "#1A2128";
            statusbar-fg            = "#A8A8AA";
            notification-bg         = "#1A2128";
            notification-fg         = "#F8F8FF";

            inputbar-bg             = "#141A1F";
            inputbar-fg             = "#A6B5C5";

            highlight-active-color  = "rgba(97, 175, 239, 0.5)";
            highlight-color         = "rgba(86, 182, 194, 0.5)";
            highlight-fg            = "#00FF00";

            font                    = "Courier Prime normal 15";

            recolor-keephue         = "true";
            recolor-lightcolor      = "#1E2127";
            recolor-darkcolor       = "#E8E8EE";

            first-page-column       = "1:1";
            guioptions              = "none";
            window-title-basename   = "true";
            adjust-open             = "width";

            dbus-service            = "true";
            synctex                 = "true";
            selection-clipboard     = "clipboard";
            selection-notification  = "false";
        };

        mappings = {
            "=" = "feedkeys \"+\"";
            "`" = "toggle_statusbar";
            "D" = "set \"first-page-column 1:1\"";
        };
    };
}
