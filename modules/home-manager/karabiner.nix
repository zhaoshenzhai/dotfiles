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
                            { # Caps lock -> Esc
                                description = "Change caps_lock to escape";
                                manipulators = [
                                    {
                                        type = "basic";
                                        from = { key_code = "caps_lock"; };
                                        to = [ { key_code = "escape"; } ];
                                    }
                                ];
                            }
                            { # Option <-> Ctrl
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
                            { # Skim
                                description = "Skim Vim-like Navigation";
                                manipulators = [
                                    { # gg
                                        type = "basic";
                                        from = { key_code = "g"; };
                                        conditions = [
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
                                    { # G
                                        type = "basic";
                                        from = { key_code = "g"; modifiers = { mandatory = [ "shift" ]; }; };
                                        to = [ { key_code = "down_arrow"; modifiers = [ "command" ]; } ];
                                        conditions = [
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # j
                                        type = "basic";
                                        from = { key_code = "j"; };
                                        to = { key_code = "down_arrow"; };
                                        conditions = [
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # k
                                        type = "basic";
                                        from = { key_code = "k"; };
                                        to = { key_code = "up_arrow"; };
                                        conditions = [
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # Cmd+j
                                        type = "basic";
                                        from = { key_code = "j"; modifiers = { mandatory = [ "control" ]; }; };
                                        to = [ { mouse_key = { vertical_wheel = 500; }; } ];
                                        conditions = [
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # Cmd+k
                                        type = "basic";
                                        from = { key_code = "k"; modifiers = { mandatory = [ "control" ]; }; };
                                        to = [ { mouse_key = { vertical_wheel = -500; }; } ];
                                        conditions = [
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # Shift+j
                                        type = "basic";
                                        from = { key_code = "j"; modifiers = { mandatory = [ "shift" ]; }; };
                                        to = [ { key_code = "down_arrow"; modifiers = [ "option" ]; } ];
                                        conditions = [
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
                                    }
                                    { # Shift+k
                                        type = "basic";
                                        from = { key_code = "k"; modifiers = { mandatory = [ "shift" ]; }; };
                                        to = [ { key_code = "up_arrow"; modifiers = [ "option" ]; } ];
                                        conditions = [
                                            {
                                                type = "frontmost_application_if";
                                                bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ];
                                            }
                                        ];
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
