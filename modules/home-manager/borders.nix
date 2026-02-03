{ pkgs, ... }: {
    xdg.configFile."borders/bordersrc" = {
        executable = true;
        text = ''
            #!/bin/bash
            options=(
                style=round
                width=1
                hidpi=off
                order=above
                active_color=0xff777777
                inactive_color=0xff444444
                background_color=0x00000000
            )
            "${pkgs.jankyborders}/bin/borders" "''${options[@]}"
        '';
    };
}
