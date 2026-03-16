{ config, pkgs, ... }:
let
    ytMpv = pkgs.writeShellScriptBin "yt-mpv" ''
        ID=$(uuidgen)
        TARGET="/tmp/yt_download_$ID"
        TITLE=$(${pkgs.yt-dlp}/bin/yt-dlp --get-title "$1" 2>/dev/null || echo "YouTube Stream")

        ${pkgs.yt-dlp}/bin/yt-dlp \
            --cookies-from-browser safari \
            -f "best" \
            --write-sub --write-auto-sub --sub-langs "en" \
            --mark-watched \
            -o "$TARGET" \
            --no-part \
            "$1" &

        YTPID=$!
        trap "kill $YTPID 2>/dev/null; rm -f $TARGET*; exit" INT TERM EXIT

        while [ ! -s "$TARGET" ]; do
            sleep 0.5
        done

        ${pkgs.mpv}/bin/mpv "$TARGET" \
            --title="$TITLE" \
            --force-media-title="$TITLE" \
            --fs \
            --sid=1 \
            --force-window=yes \
            --hwdec=auto \
            --sub-file-paths="/tmp" \
            --cache=yes \
            --cache-pause=yes \
            --demuxer-max-bytes=2G \
            --demuxer-max-back-bytes=1G \
            --demuxer-readahead-secs=1200 \
            --demuxer-thread=yes
    '';
in {
    home.packages = [ pkgs.yt-dlp pkgs.openssl pkgs.util-linux ytMpv ];

    programs.mpv = {
        enable = true;
        config = {
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

            Ctrl+s set video-zoom 0; set video-pan-x 0; set video-pan-y 0; set contrast 0; set brightness 0; set gamma 0; set saturation 0

            Ctrl+q quit-watch-later
        '';
    };
}
