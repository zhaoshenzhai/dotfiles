{ ... }: {
    xdg.configFile."karabiner/karabiner.json" = {
        force = true;
        text = builtins.toJSON {
            profiles = [
                {
                    name = "Default profile";
                    selected = true;
                    complex_modifications = {
                        rules = [
                            { # Skim
                                description = "Skim";
                                manipulators = [
                                    { # gg -> top
                                        type = "basic";
                                        from = { key_code = "g"; };
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            { type = "variable_if"; name = "skim_g_pressed"; value = 1; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                        to = [
                                            { key_code = "up_arrow"; modifiers = [ "command" ]; }
                                            { set_variable = { name = "skim_g_pressed"; value = 0; }; }
                                        ];
                                    }
                                    {
                                        type = "basic";
                                        from = { key_code = "g"; };
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                        to = [ { set_variable = { name = "skim_g_pressed"; value = 1; }; } ];
                                        to_delayed_action = {
                                            to_if_invoked = [ { set_variable = { name = "skim_g_pressed"; value = 0; }; } ];
                                            to_if_canceled = [ { set_variable = { name = "skim_g_pressed"; value = 0; }; } ];
                                        };
                                    }
                                    { # G -> bottom
                                        type = "basic";
                                        from = { key_code = "g"; modifiers = { mandatory = [ "shift" ]; }; };
                                        to = [ { key_code = "down_arrow"; modifiers = [ "command" ]; } ];
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # j -> down
                                        type = "basic";
                                        from = { key_code = "j"; };
                                        to = { key_code = "down_arrow"; };
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # k -> up
                                        type = "basic";
                                        from = { key_code = "k"; };
                                        to = { key_code = "up_arrow"; };
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # cmd + j -> scroll down
                                        type = "basic";
                                        from = { key_code = "j"; modifiers = { mandatory = [ "control" ]; }; };
                                        to = [ { mouse_key = { vertical_wheel = 500; }; } ];
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # cmd + k -> scroll up
                                        type = "basic";
                                        from = { key_code = "k"; modifiers = { mandatory = [ "control" ]; }; };
                                        to = [ { mouse_key = { vertical_wheel = -500; }; } ];
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # shift + j -> page down
                                        type = "basic";
                                        from = { key_code = "j"; modifiers = { mandatory = [ "shift" ]; }; };
                                        to = [ { key_code = "down_arrow"; modifiers = [ "option" ]; } ];
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # shift+k -> page up
                                        type = "basic";
                                        from = { key_code = "k"; modifiers = { mandatory = [ "shift" ]; }; };
                                        to = [ { key_code = "up_arrow"; modifiers = [ "option" ]; } ];
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # / -> search
                                        type = "basic";
                                        from = { key_code = "slash"; };
                                        to = [
                                            { key_code = "f"; modifiers = [ "command" "option" ]; }
                                            { set_variable = { name = "skim_search_mode"; value = 1; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # enter -> search & exit search mode
                                        type = "basic";
                                        from = { key_code = "return_or_enter"; };
                                        to = [
                                            { key_code = "return_or_enter"; }
                                            { key_code = "escape"; }
                                            { set_variable = { name = "skim_search_mode"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 1; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # escape -> exit search mode and deselect
                                        type = "basic";
                                        from = { key_code = "escape"; };
                                        to = [
                                            { key_code = "escape"; }
                                            { set_variable = { name = "skim_search_mode"; value = 0; }; }
                                            { key_code = "a"; modifiers = [ "command" "shift" ]; }
                                        ];
                                        conditions = [
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # caps lock -> exit search mode and deselect
                                        type = "basic";
                                        from = { key_code = "caps_lock"; };
                                        to = [
                                            { key_code = "escape"; }
                                            { set_variable = { name = "skim_search_mode"; value = 0; }; }
                                            { key_code = "a"; modifiers = [ "command" "shift" ]; }
                                        ];
                                        conditions = [
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # n -> next occurrence
                                        type = "basic";
                                        from = { key_code = "n"; modifiers = { mandatory = [ ]; }; };
                                        to = [ { key_code = "g"; modifiers = [ "command" "option" ]; } ];
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # N -> previous occurrence
                                        type = "basic";
                                        from = { key_code = "n"; modifiers = { mandatory = [ "shift" ]; }; };
                                        to = [ { key_code = "h"; modifiers = [ "command" "option" ]; } ];
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # ctrl+r -> recolor
                                        type = "basic";
                                        from = {
                                            key_code = "r";
                                            modifiers = { mandatory = [ "control" ]; };
                                        };
                                        to = [
                                            {
                                                shell_command = ''
                                                    CURRENT=$(defaults read net.sourceforge.skim-app.skim SKInvertColorsInDarkMode 2>/dev/null || echo 0); \
                                                    if [ \"$CURRENT\" = \"1\" ]; then \
                                                        defaults write net.sourceforge.skim-app.skim SKInvertColorsInDarkMode -bool false; \
                                                    else \
                                                        defaults write net.sourceforge.skim-app.skim SKInvertColorsInDarkMode -bool true; \
                                                    fi
                                                '';
                                            }
                                        ];
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # s -> fit to width
                                        type = "basic";
                                        from = { key_code = "s"; };
                                        to = [ { key_code = "r"; modifiers = [ "command" "shift" ]; } ];
                                        conditions = [
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                ];
                            }
                            { # option <-> ctrl
                                description = "Swap Left Option and Left Control";
                                manipulators = [
                                    {
                                        type = "basic";
                                        from = { key_code = "left_option"; };
                                        to = [ { key_code = "left_control"; } ];
                                    }
                                    {
                                        type = "basic";
                                        from = { key_code = "left_control"; };
                                        to = [ { key_code = "left_option"; } ];
                                    }
                                ];
                            }
                            { # caps lock -> esc
                                description = "Change caps_lock to escape";
                                manipulators = [
                                    {
                                        type = "basic";
                                        from = { key_code = "caps_lock"; };
                                        to = [ { key_code = "escape"; } ];
                                    }
                                ];
                            }
                        ];
                    };
                }
            ];
        };
    };
}
