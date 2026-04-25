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
                    text = ''cat ~/.cache/fastfetch/myPackages 2>/dev/null | sed -E 's/nix-//g; s/, [0-9]+ \(brew[^)]*\)//g' | sed 's/default/user/g' || echo 'Pending...' '';
                }
                {
                    type = "command";
                    key = "Homebrew";
                    text = ''cat ~/.cache/fastfetch/myPackages 2>/dev/null | sed -E 's/.*, ([0-9]+ \(brew\)), ([0-9]+) \(brew-cask\)/\1, \2 (cask)/' || echo 'Pending...' '';
                }
                {
                    type = "command";
                    key = "Terminal";
                    text = "cat ~/.cache/fastfetch/myTerminal 2>/dev/null || echo 'Pending...'";
                }
                {
                    type = "command";
                    key = "Shell";
                    text = "cat ~/.cache/fastfetch/myShell 2>/dev/null || echo 'Pending...'";
                }
                {
                    type = "command";
                    key = "Editor";
                    text = "cat ~/.cache/fastfetch/myEditor 2>/dev/null || echo 'Pending...'";
                }
                {
                    type = "command";
                    key = "Weather";
                    text = "cat ~/.cache/fastfetch/myWeather 2>/dev/null | sed 's/ (.*)//g' || echo 'Pending...'";
                }
                {
                    type = "command";
                    key = "Media";
                    text = "cat ~/.cache/fastfetch/myMedia 2>/dev/null | awk '{ if (length($0) > 35) print substr($0, 1, 32) \"...\"; else print $0 }' || echo 'Pending...'";
                }
            ];
        };
    };
}
