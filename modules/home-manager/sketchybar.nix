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
        '';
        
        installPhase = ''
            mkdir -p $out/bin
            cp time_plugin $out/bin/
            cp battery_plugin $out/bin/
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
