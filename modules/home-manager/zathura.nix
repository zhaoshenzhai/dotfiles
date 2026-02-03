{ pkgs, ... }: {
    programs.zathura = {
        enable = true;

        options = {
            default-fg              = "#1E2127";
            default-bg              = "#141A1F";

            statusbar-bg            = "#1E2127";
            statusbar-fg            = "#A8A8AA";
            notification-bg         = "#1E2127";
            notification-fg         = "#F8F8FF";

            inputbar-bg             = "#1E2127";
            inputbar-fg             = "#A6B5C5";

            highlight-active-color  = "rgba(97, 175, 239, 0.5)";
            highlight-color         = "rgba(86, 182, 194, 0.5)";
            highlight-fg            = "#00FF00";

            font                    = "Courier Prime normal 20";

            recolor                 = "true";
            recolor-keephue         = "true";
            recolor-lightcolor      = "#1E2127";
            recolor-darkcolor       = "#D8D8DD";

            first-page-column       = "1:1";
            guioptions              = "none";
            window-title-basename   = "true";
            adjust-open             = "width";

            scroll-step             = "1";
            scroll-hstep            = "1";
            scroll-full-overlap     = "0.75";

            dbus-service            = "true";
            synctex                 = "true";
            synctex-editor-command  = "nvr --remote-silent +%{line} %{input}";
            selection-clipboard     = "clipboard";
            selection-notification  = "false";
        };

        mappings = {
            "j" = "scroll full-down";
            "k" = "scroll full-up";

            "<C-j>" = "zoom out";
            "<C-k>" = "zoom in";

            "D" = "set \"first-page-column 1:1\"";
        };
    };
}
