{ pkgs, ... }: {
    programs.sioyek = {
        enable = true;
        
        config = {
            "background_color"         = "#141A1F";
            "ui_background_color"      = "#1A2128";
            "ui_text_color"            = "#A6B5C5";
            "status_bar_color"         = "#1A2128";
            "status_bar_text_color"    = "#A8A8AA";

            "custom_background_color"  = "#1E2127";
            "custom_text_color"        = "#E8E8EE";

            "text_highlight_color"     = "#56B6C2";
            "search_highlight_color"   = "#61AFEF";
    
            "page_separator_width"     = "1";
            "page_separator_height"    = "1";
            "page_separator_color"     = "0.5 0.5 0.5";

            "ui_font"                  = "Courier Prime";
            "font_size"                = "15";

            "inverse_search_command"   = "${pkgs.neovim-remote}/bin/nvr --remote-silent +%2 %1";
            "super_fast_search"        = "1";
            "should_launch_new_window" = "1";
            "startup_commands"         = "fit_to_page_width; toggle_statusbar";
        };

        bindings = {
            "move_down"     = "j";
            "move_up"       = "k";
            "next_page"     = "<C-j>";
            "previous_page" = "<C-k>";
            "prev_state"    = "<C-h>";
            "next_state"    = "<C-l>";

            "fit_to_page_width"    = "<C-w>";
            "fit_to_page_height"   = "<C-e>";
            "toggle_two_page_mode" = "<C-d>";

            "toggle_custom_color" = "<C-r>";
            "reload"              = "<C-R>";
        };
    };
}
