{ pkgs, ... }: {
    xdg.configFile."sketchybar/sketchybarrc" = {
        source = ./sketchybar/sketchybarrc;
        executable = true;
  };
}
