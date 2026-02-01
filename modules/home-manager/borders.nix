{ pkgs, ... }: {
    home.packages = [ pkgs.jankyborders ];

    xdg.configFile."borders/bordersrc" = {
        executable = true;
        text = ''
            #!/bin/sh
            options=(
                style=round
                width=6.0
                hidpi=off
                active_color=0xff${builtins.substring 1 6 "56B6C2"}
                inactive_color=0xff${builtins.substring 1 6 "1E2127"}
                background_color=0x30${builtins.substring 1 6 "141A1F"}
            )
            borders "''${options[@]}"
        '';
    };
}
