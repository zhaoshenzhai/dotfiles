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
                    key = "Monitor";
                    text = "cat ~/.cache/fastfetch/myMonitor 2>/dev/null | sed 's/ -.*//g' || echo 'Pending...'";
                }
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
                    key = "Font";
                    text = "cat ~/.cache/fastfetch/myFont 2>/dev/null | sed 's/Menlo/Courier Prime/g' || echo 'Pending...'";
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
                    text = "cat ~/.cache/fastfetch/myMedia 2>/dev/null | sed 's/ ([^)]*)$//' | awk -F ' - ' '{ a=$1; t=$2; if(length(a)>15) a=substr(a,1,12)\"...\"; if(length(t)>17) t=substr(t,1,14)\"...\"; if(NF>1) print a \" - \" t; else print substr($0,1,32)\"...\" }' || echo 'Pending...'";
                }
            ];
        };
    };
}
