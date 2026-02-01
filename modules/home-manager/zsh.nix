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
            la = "ls -lhAr --color=auto -F --group-directories-first";
            tree = "tree -C";
            nixs = "sudo darwin-rebuild switch --flake ~/iCloud/Dotfiles#puppy; aerospace reload-config";
            nixu = "pushd ~/iCloud/Dotfiles; nix flake update; nixs; popd";
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

            export DBUS_SESSION_BUS_ADDRESS="unix:path=/tmp/dbus-custom-$(whoami)"
            if [ ! -f $HOME/.config/dbus/machine-id ]; then
                mkdir -p $HOME/.config/dbus
                ${pkgs.dbus}/bin/dbus-uuidgen > $HOME/.config/dbus/machine-id
            fi
            export DBUS_MACHINE_ID_MACHINE_ID_FILE=$HOME/.config/dbus/machine-id

            if [ ! -S "/tmp/dbus-custom-$(whoami)" ] || ! pgrep -f "$DBUS_SESSION_BUS_ADDRESS" > /dev/null; then
                rm -f "/tmp/dbus-custom-$(whoami)"
                ${pkgs.dbus}/bin/dbus-daemon --session --address="$DBUS_SESSION_BUS_ADDRESS" --fork --print-address > /dev/null
            fi
        '';
    };
}
