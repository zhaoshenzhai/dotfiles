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
                            {
                                description = "Change caps_lock to escape";
                                manipulators = [
                                    {
                                        type = "basic";
                                        from = { key_code = "caps_lock"; };
                                        to = [ { key_code = "escape"; } ];
                                    }
                                ];
                            }
                            {
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
                            {
                                description = "Skim Vim-like Navigation";
                                manipulators = [
                                    {
                                        type = "basic";
                                        from = { key_code = "g"; };
                                        to = [ { key_code = "up_arrow"; modifiers = [ "command" ]; } ];
                                        conditions = [
                                            { type = "frontmost_application_if"; bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ]; }
                                        ];
                                    }
                                    {
                                        type = "basic";
                                        from = { key_code = "g"; modifiers = { mandatory = [ "shift" ]; }; };
                                        to = [ { key_code = "down_arrow"; modifiers = [ "command" ]; } ];
                                        conditions = [
                                            { type = "frontmost_application_if"; bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ]; }
                                        ];
                                    }
                                    {
                                        type = "basic";
                                        from = { key_code = "j"; };
                                        to = [ { mouse_wheel = { vertical_wheel = -256; }; } ]; # Moderated for smoothness
                                        conditions = [ { type = "frontmost_application_if"; bundle_identifiers = [ "^net\\.sourceforge\\.skim-app\\.skim$" ]; } ];
                                    }
                                    {
                                        type = "basic";
                                        from = { key_code = "k"; };
                                        to = [
                                            { key_code = "up_arrow"; }
                                            { key_code = "up_arrow"; }
                                            { key_code = "up_arrow"; }
                                        ];
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
