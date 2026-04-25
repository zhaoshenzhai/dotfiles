{ pkgs, lib, ... }: {
    home.packages = with pkgs; [
        coreutils
        btop
    ];

    programs.zsh = {
        enable = true;
        enableCompletion = false;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        dotDir = "/Users/zhao/.config/zsh";
        history.path = "/Users/zhao/.config/zsh/.zsh_history";

        shellAliases = {
            ls = "ls --color=auto -F";
            la = "ls -lhAr --color=auto -F";
            exit = "aerospace close";

            nixs = "sudo darwin-rebuild switch --flake ~/iCloud/Dotfiles#puppy; aerospace reload-config; sketchybar --reload";
            nixu = "pushd ~/iCloud/Dotfiles; nix flake update; nixs; popd";
            nixd = "sudo nix-env -p /nix/var/nix/profiles/system --delete-generations old; nix-collect-garbage -d; nixs";

            zoom = "open -a zoom.us";
            skim = "open -a Skim";
        };

        initContent = lib.mkBefore ''
            if [[ -t 0 ]]; then
                stty -echo 2>/dev/null
            fi

            fastfetch

            autoload -Uz compinit
            ZCOMP="/Users/zhao/.config/zsh/.zcompdump"

            if [[ -f "$ZCOMP" ]]; then
                compinit -C -d "$ZCOMP"
            else
                compinit -d "$ZCOMP"
            fi

            bindkey '^[[Z' autosuggest-accept
            bindkey '^k' up-line-or-history
            bindkey '^j' down-line-or-history
            bindkey '^h' backward-char
            bindkey '^l' forward-char
            bindkey '^x' delete-char

            export YELLOW='\033[0;33m'
            export PURPLE='\033[0;35m'
            export GREEN='\033[0;32m'
            export CYAN='\033[0;36m'
            export BLUE='\033[0;34m'
            export RED='\033[0;31m'
            export NC='\033[0m'

            (
                update_cache() {
                    local module=$1
                    local file=~/.cache/fastfetch/$2
                    fastfetch --config none --structure "$module" --logo none | sed 's/^[^:]*: //' > "$file.tmp"
                    mv "$file.tmp" "$file"
                }

                update_cache wm myWM
                update_cache packages myPackages
                update_cache terminal myTerminal
                update_cache shell myShell
                update_cache editor myEditor
            ) &!

            autoload -Uz add-zle-hook-widget
            function _restore_tty_echo() {
                if [[ -t 0 ]]; then
                    stty echo 2>/dev/null
                fi
                add-zle-hook-widget -d line-init _restore_tty_echo
            }
            add-zle-hook-widget line-init _restore_tty_echo
        '';
    };

    home.activation = {
        zcompileCache = lib.hm.dag.entryAfter ["writeBoundary"] ''
            $DRY_RUN_CMD ${pkgs.zsh}/bin/zsh -c '
                ZDIR="/Users/zhao/.config/zsh"

                if [[ -f "$ZDIR/.zshenv" ]]; then
                    zcompile -M "$ZDIR/.zshenv"
                fi

                if [[ -f "$ZDIR/.zshrc" ]]; then
                    zcompile -M "$ZDIR/.zshrc"
                fi

                if [[ -f "$ZDIR/.zcompdump" ]]; then
                    zcompile -M "$ZDIR/.zcompdump"
                fi
            '
        '';
    };
}
