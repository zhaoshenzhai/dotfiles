{ config, pkgs, ... }:

{
    programs.fastfetch = {
        enable = true;

        settings = {
            display = {
                separator = " ➜ ";
                color = {
                    keys = "green";
                };
            };

            modules = [
                { type = "title"; color = { user = "cyan"; at = "white"; host = "magenta"; }; }
                "break"
                "os"
                "host"
                "cpu"
                "kernel"
                "uptime"
                { type = "command"; key = "Monitor";        text = "cat ~/.cache/fastfetch/myMonitor  2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Window manager"; text = "cat ~/.cache/fastfetch/myWM       2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Nix packages";   text = "cat ~/.cache/fastfetch/myNix      2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Homebrew";       text = "cat ~/.cache/fastfetch/myBrew     2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Terminal";       text = "cat ~/.cache/fastfetch/myTerminal 2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Font";           text = "cat ~/.cache/fastfetch/myFont     2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Shell";          text = "cat ~/.cache/fastfetch/myShell    2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Editor";         text = "cat ~/.cache/fastfetch/myEditor   2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Weather";        text = "cat ~/.cache/fastfetch/myWeather  2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Media";          text = "cat ~/.cache/fastfetch/myMedia    2>/dev/null || echo 'Pending...'"; }
            ];
        };
    };
}
