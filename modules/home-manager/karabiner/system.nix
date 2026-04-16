{
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
