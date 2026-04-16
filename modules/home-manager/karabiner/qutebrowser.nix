{
    description = "Qutebrowser";
    manipulators = builtins.genList (i:
        let
            key = toString (i + 1);
        in
        {
            type = "basic";
            from = { key_code = key; modifiers = { mandatory = [ "control" "shift" ]; }; };
            to = [ { key_code = "g"; } { key_code = key; } ];
            conditions = [
                {
                    type = "frontmost_application_if";
                    bundle_identifiers = [ "^org\\.qutebrowser\\.qutebrowser$" ];
                }
            ];
        }
    ) 9;
}
