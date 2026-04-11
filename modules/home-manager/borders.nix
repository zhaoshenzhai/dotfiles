{ pkgs, ... }: {
    home.packages = [ pkgs.jankyborders ];
    xdg.configFile."borders/bordersrc" = {
        executable = true;
        text = ''
            #!/bin/bash
            killall borders 2>/dev/null
            options=(
                style=round
                width=1
                hidpi=on
                ax_focus=on
                order=above
                active_color=0xff777777
                inactive_color=0xff444444
                background_color=0x00000000
            )
            "${pkgs.jankyborders}/bin/borders" "''${options[@]}"
        '';
    };
}
