[[ -f ~/.bashrc ]] && . ~/.bashrc

# XDG paths
export XDG_DATA_HOME=${XDG_DATA_HOME:="$HOME/.local/share"}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:="$HOME/.cache"}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:="$HOME/.config"}

# Environments
export EDITOR=nvim
export TERMINAL="/usr/bin/alacritty"
export XAUTHORITY="$XDG_RUNTIME_DIR/Xauthority"

# Xmonad
export XMONAD_CACHE_DIR="$HOME/.cache"
export XMONAD_CONFIG_DIR="$HOME/.config/xmonad"
export XMONAD_DATA_DIR="$HOME/.config/xmonad"

# Directories
export MATHWIKI_DIR="$HOME/Dropbox/MathWiki"
export DOTFILES_DIR="$HOME/Dropbox/Dotfiles"

# Paths
export PATH="$HOME/.local/bin:$PATH"

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec startx "$DOTFILES_DIR/config/xinitrc"
fi
