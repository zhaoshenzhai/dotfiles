{ pkgs, ... }: {
    xdg.configFile."sketchybar/sketchybarrc" = {
        executable = true;
        text = ''
            #!/usr/bin/env bash

            # --- Colors ---
            export BACKGROUND=0xff282c34
            export FOREGROUND=0xffabb2bf
            export BLUE=0xff61afef
            export MAGENTA=0xffc678dd
            export YELLOW=0xffd19a66

            # --- Bar Settings ---
            sketchybar --bar \
                height=32 \
                color=$BACKGROUND \
                border_width=0 \
                position=top \
                sticky=on \
                padding_left=10 \
                padding_right=10 \
                topmost=window

            # --- Defaults ---
            sketchybar --default \
                icon.font="SketchyBar App Font:Regular:16.0" \
                label.font="Courier Prime:Bold:14.0" \
                icon.color=$FOREGROUND \
                label.color=$FOREGROUND \
                background.corner_radius=5 \
                background.height=24

            # --- Items ---
            
            # 1. Front App
            # Note the backslash before $NAME and $INFO:
            sketchybar --add item front_app left \
                --set front_app \
                icon.drawing=off \
                label.color=$BACKGROUND \
                background.color=$BLUE \
                associated_display=active \
                script="${pkgs.sketchybar}/bin/sketchybar --set \$NAME label=\"\$INFO\"" \
                --subscribe front_app front_app_switched

            # 2. Clock
            sketchybar --add item clock right \
                --set clock \
                update_freq=10 \
                icon= \
                icon.color=$MAGENTA \
                script="date '+%H:%M' | xargs sketchybar --set \$NAME label"

            sketchybar --update
            echo "Sketchybar configuration loaded"
        '';
    };
}
