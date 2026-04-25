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
                {
                    type = "command";
                    key = "Window manager";
                    text = "cat ~/.cache/fastfetch/myWM 2>/dev/null | grep -o 'AeroSpace [^)]*' || echo 'Pending...'";
                }
                {
                    type = "command";
                    key = "Nix packages";
                    text = "cat ~/.cache/fastfetch/myPackages 2>/dev/null | \
                            grep -o '[0-9]* (nix-default)' | \
                            cut -d' ' -f1 || echo 'Pending...'";
                }
                { type = "command"; key = "Terminal"; text = "cat ~/.cache/fastfetch/myTerminal 2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Shell";    text = "cat ~/.cache/fastfetch/myShell    2>/dev/null || echo 'Pending...'"; }
                { type = "command"; key = "Editor";   text = "cat ~/.cache/fastfetch/myEditor   2>/dev/null || echo 'Pending...'"; }
            ];
        };
    };
}
