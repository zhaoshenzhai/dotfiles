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
                            { # Spotlight
                                description = "Spotlight";
                                manipulators = [
                                    { # cmd+shift+enter when spotlight is off -> turn on
                                        type = "basic";
                                        from = { key_code = "return_or_enter"; modifiers = { mandatory = [ "command" "shift" ]; }; };
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                        ];
                                        to = [
                                            { key_code = "return_or_enter"; modifiers = [ "command" "shift" ]; }
                                            { set_variable = { name = "spotlight_mode"; value = 1; }; }
                                        ];
                                    }
                                    { # cmd+shift+enter when spotlight is on -> turn off
                                        type = "basic";
                                        from = { key_code = "return_or_enter"; modifiers = { mandatory = [ "command" "shift" ]; }; };
                                        conditions = [
                                            { type = "variable_if"; name = "spotlight_mode"; value = 1; }
                                        ];
                                        to = [
                                            { key_code = "return_or_enter"; modifiers = [ "command" "shift" ]; }
                                            { set_variable = { name = "spotlight_mode"; value = 0; }; }
                                        ];
                                    }
                                    { # return when spotlight is on -> turn off
                                        type = "basic";
                                        from = { key_code = "return_or_enter"; };
                                        conditions = [
                                            { type = "variable_if"; name = "spotlight_mode"; value = 1; }
                                        ];
                                        to = [
                                            { key_code = "return_or_enter"; }
                                            { set_variable = { name = "spotlight_mode"; value = 0; }; }
                                        ];
                                    }
                                    { # escape when spotlight is on -> turn off
                                        type = "basic";
                                        from = { key_code = "escape"; };
                                        conditions = [
                                            { type = "variable_if"; name = "spotlight_mode"; value = 1; }
                                        ];
                                        to = [
                                            { key_code = "escape"; }
                                            { set_variable = { name = "spotlight_mode"; value = 0; }; }
                                        ];
                                    }
                                    { # caps lock when spotlight is on -> turn off
                                        type = "basic";
                                        from = { key_code = "caps_lock"; };
                                        conditions = [
                                            { type = "variable_if"; name = "spotlight_mode"; value = 1; }
                                        ];
                                        to = [
                                            { key_code = "escape"; }
                                            { set_variable = { name = "spotlight_mode"; value = 0; }; }
                                        ];
                                    }
                                ];
                            }
                            { # Skim
                                description = "Skim";
                                manipulators = [
                                    { # gg -> top
                                        type = "basic";
                                        from = { key_code = "g"; };
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
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
                                            { set_variable = { name = "skim_search_sequence"; value = 0; }; }
                                        ];
                                    }
                                    {
                                        type = "basic";
                                        from = { key_code = "g"; };
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
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
                                        to = [
                                            { key_code = "down_arrow"; modifiers = [ "command" ]; }
                                            { set_variable = { name = "skim_search_sequence"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
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
                                        to = [ { key_code = "down_arrow"; } ];
                                        to_after_key_up = [
                                            { set_variable = { name = "skim_search_sequence"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
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
                                        to = [ { key_code = "up_arrow"; } ];
                                        to_after_key_up = [
                                            { set_variable = { name = "skim_search_sequence"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # shift+j -> page down
                                        type = "basic";
                                        from = { key_code = "j"; modifiers = { mandatory = [ "shift" ]; }; };
                                        to = [ { key_code = "down_arrow"; modifiers = [ "option" ]; } ];
                                        to_after_key_up = [
                                            { set_variable = { name = "skim_search_sequence"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
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
                                        to_after_key_up = [
                                            { set_variable = { name = "skim_search_sequence"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # ctrl+j -> previous tab
                                        type = "basic";
                                        from = { key_code = "j"; modifiers = { mandatory = [ "control" ]; }; };
                                        to = [ { key_code = "open_bracket"; modifiers = [ "command" "shift" ]; } ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # ctrl+k -> next tab
                                        type = "basic";
                                        from = { key_code = "k"; modifiers = { mandatory = [ "control" ]; }; };
                                        to = [ { key_code = "close_bracket"; modifiers = [ "command" "shift" ]; } ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # ctrl+w -> close tab
                                        type = "basic";
                                        from = { key_code = "w"; modifiers = { mandatory = [ "control" ]; }; };
                                        to = [ { key_code = "w"; modifiers = [ "command" "option" ]; } ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # ctrl+h -> jump back
                                        type = "basic";
                                        from = { key_code = "h"; modifiers = { mandatory = [ "control" ]; }; };
                                        to = [ { key_code = "open_bracket"; modifiers = [ "command" ]; } ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # ctrl+l -> jump forward
                                        type = "basic";
                                        from = { key_code = "l"; modifiers = { mandatory = [ "control" ]; }; };
                                        to = [ { key_code = "close_bracket"; modifiers = [ "command" ]; } ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
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
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # ctrl+2 -> open in nvim
                                        type = "basic";
                                        from = { key_code = "2"; modifiers = { mandatory = [ "control" ]; }; };
                                        to = [{ shell_command = "zsh -ic 'skimUtils -o'"; }];
                                        conditions = [
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
                                            {
                                                shell_command = ''
                                                    osascript <<'EOF'
                                                    tell application "Skim"
                                                        try
                                                            tell front document
                                                                set selection to {character 1 of text of current page}
                                                            end tell
                                                        end try
                                                    end tell
                                                    tell application "System Events"
                                                        tell process "Skim"
                                                            keystroke "f" using {command down, option down}
                                                        end tell
                                                    end tell
                                                    EOF
                                                '';
                                            }
                                            { set_variable = { name = "skim_search_mode"; value = 1; }; }
                                            { set_variable = { name = "skim_search_sequence"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
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
                                            { set_variable = { name = "skim_search_sequence"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
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
                                            { set_variable = { name = "skim_search_sequence"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
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
                                            { set_variable = { name = "skim_search_sequence"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # n -> next occurrence
                                        type = "basic";
                                        from = { key_code = "n"; modifiers = { mandatory = [ ]; }; };
                                        to = [
                                            {
                                                shell_command = ''
                                                    osascript <<'EOF'
                                                    tell application "Skim"
                                                        try
                                                            tell front document
                                                                set selection to {character 1 of text of current page}
                                                            end tell
                                                        end try
                                                    end tell
                                                    tell application "System Events"
                                                        tell process "Skim"
                                                            keystroke "g" using {command down, option down}
                                                        end tell
                                                    end tell
                                                    EOF
                                                '';
                                            }
                                            { set_variable = { name = "skim_search_sequence"; value = 1; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            { type = "variable_unless"; name = "skim_search_sequence"; value = 1; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    {
                                        type = "basic";
                                        from = { key_code = "n"; modifiers = { mandatory = [ ]; }; };
                                        to = [ { key_code = "g"; modifiers = [ "command" "option" ]; } ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            { type = "variable_if"; name = "skim_search_sequence"; value = 1; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # N -> previous occurrence
                                        type = "basic";
                                        from = { key_code = "n"; modifiers = { mandatory = [ "shift" ]; }; };
                                        to = [
                                            {
                                                shell_command = ''
                                                    osascript <<'EOF'
                                                    tell application "Skim"
                                                        try
                                                            tell front document
                                                                set selection to {character 1 of text of current page}
                                                            end tell
                                                        end try
                                                    end tell
                                                    tell application "System Events"
                                                        tell process "Skim"
                                                            keystroke "h" using {command down, option down}
                                                        end tell
                                                    end tell
                                                    EOF
                                                '';
                                            }
                                            { set_variable = { name = "skim_search_sequence"; value = 1; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            { type = "variable_unless"; name = "skim_search_sequence"; value = 1; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    {
                                        type = "basic";
                                        from = { key_code = "n"; modifiers = { mandatory = [ "shift" ]; }; };
                                        to = [ { key_code = "h"; modifiers = [ "command" "option" ]; } ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            { type = "variable_if"; name = "skim_search_sequence"; value = 1; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # s -> fit to width
                                        type = "basic";
                                        from = { key_code = "s"; };
                                        to = [
                                            { key_code = "hyphen"; modifiers = [ "command" "shift" ]; }
                                            { set_variable = { name = "skim_fit_to_height"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # a -> fit to height
                                        type = "basic";
                                        from = { key_code = "a"; };
                                        to = [
                                            { key_code = "3"; modifiers = [ "control" "option" "command" ]; }
                                            { key_code = "hyphen"; modifiers = [ "command" "shift" ]; }
                                            { key_code = "2"; modifiers = [ "control" "option" "command" ]; }
                                            { set_variable = { name = "skim_fit_to_height"; value = 1; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            { type = "variable_if"; name = "skim_fit_to_height"; value = 0; }
                                            { type = "variable_if"; name = "skim_double_page_mode"; value = 1; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    {
                                        type = "basic";
                                        from = { key_code = "a"; };
                                        to = [
                                            { key_code = "3"; modifiers = [ "control" "option" "command" ]; }
                                            { key_code = "hyphen"; modifiers = [ "command" "shift" ]; }
                                            { key_code = "1"; modifiers = [ "control" "option" "command" ]; }
                                            { set_variable = { name = "skim_fit_to_height"; value = 1; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            { type = "variable_if"; name = "skim_fit_to_height"; value = 0; }
                                            { type = "variable_if"; name = "skim_double_page_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # d -> toggle double page
                                        type = "basic";
                                        from = { key_code = "d"; modifiers = { mandatory = [ ]; }; };
                                        to = [
                                            { key_code = "2"; modifiers = [ "control" "option" "command" ]; }
                                            { set_variable = { name = "skim_double_page_mode"; value = 1; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            { type = "variable_unless"; name = "skim_double_page_mode"; value = 1; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    {
                                        type = "basic";
                                        from = { key_code = "d"; modifiers = { mandatory = [ ]; }; };
                                        to = [
                                            { key_code = "1"; modifiers = [ "control" "option" "command" ]; }
                                            { set_variable = { name = "skim_double_page_mode"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            { type = "variable_if"; name = "skim_double_page_mode"; value = 1; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # = -> zoom in
                                        type = "basic";
                                        from = { key_code = "equal_sign"; };
                                        to = [
                                            { key_code = "equal_sign"; modifiers = [ "command" ]; }
                                            { set_variable = { name = "skim_fit_to_height"; value = 0; }; }
                                            ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # - -> zoom out
                                        type = "basic";
                                        from = { key_code = "hyphen"; };
                                        to = [
                                            { key_code = "hyphen"; modifiers = [ "command" ]; }
                                            { set_variable = { name = "skim_fit_to_height"; value = 0; }; }
                                        ];
                                        conditions = [
                                            { type = "variable_unless"; name = "spotlight_mode"; value = 1; }
                                            { type = "variable_if"; name = "skim_search_mode"; value = 0; }
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                ];
                            }
                            { # System
                                description = "System";
                                manipulators = [
                                    { # option -> ctrl
                                        type = "basic";
                                        from = { key_code = "left_option"; };
                                        to = [ { key_code = "left_control"; } ];
                                    }
                                    { # ctrl -> option
                                        type = "basic";
                                        from = { key_code = "left_control"; };
                                        to = [ { key_code = "left_option"; } ];
                                    }
                                    { # caps lock -> esc
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
