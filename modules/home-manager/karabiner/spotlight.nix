{
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
