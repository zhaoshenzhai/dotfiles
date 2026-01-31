[[ -f ~/.bashrc ]] && . ~/.bashrc

# XDG paths
export XDG_CACHE_HOME=${XDG_CACHE_HOME:="$HOME/.cache"}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:="$HOME/.config"}
export XDG_DATA_HOME=${XDG_DATA_HOME:="$HOME/.local/share"}

# Environments
export EDITOR=nvim
export TERMINAL="/usr/bin/kitty"

# Xmonad
export XMONAD_CACHE_DIR="$HOME/.config/xmonad"
export XMONAD_DATA_DIR="$HOME/.config/xmonad"
export XMONAD_CONFIG_DIR="$HOME/.config/xmonad"

# Directories
export DOTFILES_DIR="$HOME/Dropbox/Dotfiles"
export UNIVERSITY_DIR="$HOME/Dropbox/University"

# Paths
export PATH="$HOME/.local/bin:$PATH"
export PATH="$DOTFILES_DIR/scripts:$PATH"

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec startx "$DOTFILES_DIR/config/xinitrc"
fi
