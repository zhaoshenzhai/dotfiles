{ pkgs, ... }: {
    home.packages = [ pkgs.jankyborders ];

    xdg.configFile."borders/bordersrc" = {
        executable = true;
        text = ''
            #!/bin/sh
            options=(
                style=round
                width=3.0
                hidpi=off
                order=above
                active_color=0xff56B6C2
                inactive_color=0xff1E2127
                background_color=0x30141A1F
            )
            "${pkgs.jankyborders}/bin/borders" "''${options[@]}"
        '';
    };
}
