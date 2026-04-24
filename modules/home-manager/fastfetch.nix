{ config, pkgs, ... }:

{
    programs.fastfetch = {
        enable = true;

        settings = {
            display = {
                separator = " ➜ ";
                color = {
                    keys = "magenta";
                    title = "cyan";
                };
            };

            modules = [
                "title"
                "separator"
                "os"
                "host"
                "kernel"
                "cpu"
                "uptime"
                "processes"
                { type = "command"; key = "Packages"; text = "cat ~/.cache/fastfetch/myPackages 2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Shell";    text = "cat ~/.cache/fastfetch/myShell    2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Editor";   text = "cat ~/.cache/fastfetch/myEditor   2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "WM";       text = "cat ~/.cache/fastfetch/myWM       2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Weather";  text = "cat ~/.cache/fastfetch/myWeather  2>/dev/null || echo 'Pending...'"; }
                "break"
                "colors"
            ];
        };
    };
}
