{ pkgs, ... }: 

let
    sketchybarCPlugins = pkgs.stdenv.mkDerivation {
        pname = "sketchybar-c-plugins";
        version = "1.0.0";
        src = ./sketchybar/src;
        buildInputs = [ pkgs.clang ];
        
        buildPhase = ''
            clang -std=c99 -O3 time_plugin.c -o time_plugin
            clang -std=c99 -O3 battery_plugin.c -o battery_plugin
            clang -std=c99 -O3 disk_plugin.c -o disk_plugin
            clang -std=c99 -O3 volume_plugin.c -o volume_plugin
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
    home.packages = [ sketchybarCPlugins ];

    xdg.configFile."sketchybar" = {
        source = ./sketchybar;
        recursive = true;
    };
}
