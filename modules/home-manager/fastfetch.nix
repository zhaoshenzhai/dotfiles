{ config, pkgs, ... }: {
    programs.fastfetch = {
        enable = true;

        settings = {
            display = { separator = " ➜ "; color = { keys = "green"; }; };

            modules = [
                { type = "title"; color = { user = "cyan"; at = "white"; host = "magenta"; }; }
                "break"
                { type = "command"; key = "OS";             text = "cat ~/.cache/fastfetch/myOS       || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Host";           text = "cat ~/.cache/fastfetch/myHost     || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "CPU";            text = "cat ~/.cache/fastfetch/myCPU      || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Kernel";         text = "cat ~/.cache/fastfetch/myKernel   || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Uptime";         text = "cat ~/.cache/fastfetch/myUptime   || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Monitor";        text = "cat ~/.cache/fastfetch/myMonitor  || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Window manager"; text = "cat ~/.cache/fastfetch/myWM       || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Nix packages";   text = "cat ~/.cache/fastfetch/myNix      || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Homebrew";       text = "cat ~/.cache/fastfetch/myBrew     || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Terminal";       text = "cat ~/.cache/fastfetch/myTerminal || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Font";           text = "cat ~/.cache/fastfetch/myFont     || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Shell";          text = "cat ~/.cache/fastfetch/myShell    || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Editor";         text = "cat ~/.cache/fastfetch/myEditor   || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Weather";        text = "cat ~/.cache/fastfetch/myWeather  || printf 'Pending...\\033[K\n'"; }
                { type = "command"; key = "Media";          text = "cat ~/.cache/fastfetch/myMedia    || printf 'Pending...\\033[K\n'"; }
            ];
        };
    };
}
