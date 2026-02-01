{ pkgs, ... }: {
    home.packages = [ pkgs.jankyborders ];

    xdg.configFile."borders/bordersrc" = {
        executable = true;
        text = ''
            #!/bin/bash
            options=(
                style=round
                width=2
                hidpi=off
                order=above
                active_color=0xff56B6C2
                inactive_color=0x00000000
                background_color=0x00000000
            )
            "${pkgs.jankyborders}/bin/borders" "''${options[@]}"
        '';
    };
}
