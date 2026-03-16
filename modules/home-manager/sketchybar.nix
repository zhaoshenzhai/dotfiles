{ pkgs, ... }: let
    colors = {
        BLACK        = "0xff111111";
        BLACK_       = "0xaa111111";
        WHITE        = "0xffdddddd";
        WHITE_       = "0x55dddddd";
        RED          = "0xffe06c75";
        RED_         = "0x55e06c75";
        GREEN        = "0xff98c379";
        GREEN_       = "0x5598c379";
        BLUE         = "0xff61afef";
        BLUE_        = "0x5561afef";
        YELLOW       = "0xffd19a66";
        YELLOW_      = "0x55d19a66";
        ORANGE       = "0xfff5a97f";
        ORANGE_      = "0x55f5a97f";
        MAGENTA      = "0xffc678dd";
        MAGENTA_     = "0x55c678dd";
        GRAY         = "0xff939ab7";
        TRANSPARENT  = "0x00000000";
        BAR_COLOR    = "0xaa111111"; # BLACK_
        ICON_COLOR   = "0xffdddddd"; # WHITE
        LABEL_COLOR  = "0xffdddddd"; # WHITE
        BORDER_COLOR = "0xff666666";
    };

    colorsSh = pkgs.writeText "colors.sh" ''
        #!/usr/bin/env sh
        ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "${name}=${value}") colors)}
    '';

    colorsH = pkgs.writeText "colors.h" ''
        #ifndef COLORS_H
        #define COLORS_H
        ${builtins.concatStringsSep "\n" (pkgs.lib.mapAttrsToList (name: value: "#define ${name} \"${value}\"") colors)}
        #endif
    '';

    sketchybarCPlugins = pkgs.stdenv.mkDerivation {
        pname = "sketchybar-c-plugins";
        version = "1.0.0";
        src = ./sketchybar/src;
        buildInputs = [ pkgs.clang ];

        buildPhase = ''
            cp ${colorsH} ./colors.h
            clang -std=c99 -O3 time_plugin.c -o time_plugin
            clang -std=c99 -O3 -framework CoreFoundation -framework IOKit battery_plugin.c -o battery_plugin
            clang -std=c99 -O3 disk_plugin.c -o disk_plugin
            clang -std=c99 -O3 -framework CoreFoundation -framework CoreAudio volume_plugin.c -o volume_plugin
            clang -std=c99 -O3 cpu_plugin.c -o cpu_plugin
            clang -std=c99 -O3 openApp_plugin.c -o openApp_plugin
            clang -std=c99 -O3 aerospace_plugin.c -o aerospace_plugin
        '';

        installPhase = ''
            mkdir -p $out/bin
            cp time_plugin battery_plugin disk_plugin volume_plugin cpu_plugin openApp_plugin aerospace_plugin $out/bin/
        '';
    };
in
{
    home.packages = with pkgs; [
        sketchybarCPlugins
        sketchybar
        jq
    ];

    xdg.configFile."sketchybar" = {
        source = ./sketchybar;
        recursive = true;
    };

    xdg.configFile."sketchybar/colors.sh".source = colorsSh;
    xdg.configFile."sketchybar/src/colors.h".source = colorsH;
}
