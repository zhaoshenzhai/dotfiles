{ config, pkgs, ... }: {
    home.packages = [ pkgs.yt-dlp ];
    programs.mpv = {
        enable = true;

        scripts = [
            (pkgs.stdenv.mkDerivation {
                pname = "cycle-commands";
                scriptName = "cycle-commands.lua";
                version = "master";
                src = pkgs.fetchurl {
                    url = "https://raw.githubusercontent.com/CogentRedTester/mpv-scripts/master/cycle-commands.lua";
                    hash = "sha256-v1MvoYZvF6NBJ7vv8Y3csHE+T4wX4ub6f6CNLhKt/00=";
                };
                dontUnpack = true;
                installPhase = ''
                    mkdir -p $out/share/mpv/scripts
                    cp $src $out/share/mpv/scripts/cycle-commands.lua
                '';
            })
        ];

        config = {
            fs = "yes";
            sid = "1";

            ytdl-format = "bestvideo[height>=?1080]+bestaudio/best";
            ytdl-raw-options = ''cookies-from-browser=safari,mark-watched=,write-sub=,write-auto-sub=,sub-langs=en.*'';

            sub-visibility = "yes";
            sub-font = "Courier Prime";
            sub-font-size = 25;
            sub-border-size = 2;
            sub-back-color = "#801e2127";
            sub-file-paths = "subs";

            osd-font = "Courier Prime";
            osd-font-size = 20;
            script-opts = "osc-scalewindowed=0.8,osc-scalefullscreen=0.8,console-font_size=15";
        };

        extraInput = ''
            Ctrl+SPACE cycle pause
            Ctrl+\ script-binding console/enable

            Ctrl+h seek -5
            Ctrl+H seek -10
            Ctrl+l seek 5
            Ctrl+L seek 10

            Ctrl+j multiply speed 1/1.2
            Ctrl+J multiply speed 1/2
            Ctrl+k multiply speed 1.2
            Ctrl+K multiply speed 2
            Ctrl+0 set speed 1

            Ctrl+z add sub-delay -0.1
            Ctrl+x add sub-delay 0.1
            Ctrl+c cycle sub

            Ctrl+[ add audio-delay -0.1
            Ctrl+] add audio-delay 0.1

            Ctrl+- add video-zoom -0.25
            Ctrl+= add video-zoom 0.25

            Ctrl+LEFT add video-pan-x 0.1
            Ctrl+RIGHT add video-pan-x -0.1
            Ctrl+UP add video-pan-y 0.1
            Ctrl+DOWN add video-pan-y -0.1

            Ctrl+1 add contrast -2
            Ctrl+2 add contrast 2
            Ctrl+3 add brightness -2
            Ctrl+4 add brightness 2
            Ctrl+5 add gamma -2
            Ctrl+6 add gamma 2
            Ctrl+7 add saturation -2
            Ctrl+8 add saturation 2

            Ctrl+q quit-watch-later
            q quit-watch-later

            Ctrl+` script-message cycle-commands "script-message osc-visibility always" "set osd-level 1; script-message osc-visibility never"; script-message cycle-commands "set sub-pos 94" "set sub-pos 100"
            Ctrl+s set video-zoom 0; set video-pan-x 0; set video-pan-y 0; set contrast 0; set brightness 0; set gamma 0; set saturation 0
        '';
    };
}
