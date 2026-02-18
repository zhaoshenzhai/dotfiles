{ pkgs, ... }: {
    programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        dotDir = "/Users/zhao/.config/zsh";
        history.path = "/Users/zhao/.config/zsh/.zsh_history";
        
        shellAliases = {
            ls = "ls --color=auto -F";
            la = "ls -lhAr --color=auto -F";
            tree = "tree -C";
            nixs = "sudo darwin-rebuild switch --flake ~/iCloud/Dotfiles#puppy; aerospace reload-config; sketchybar --reload";
            nixu = "pushd ~/iCloud/Dotfiles; nix flake update; nixs; popd";
            zoom = "open -a zoom.us";
            skim = "open -a Skim";
        };

        initContent = ''
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
        '';
    };
}
