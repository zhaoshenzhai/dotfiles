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
export XMONAD_CACHE_DIR="$HOME/.cache/xmonad"
export XMONAD_CONFIG_DIR="$HOME/.config/xmonad"
export XMONAD_DATA_DIR="$HOME/.config/xmonad"

# Java
export _JAVA_AWT_WM_NONREPARENTING=1

# Directories
export MATHWIKI_DIR="$HOME/Dropbox/MathWiki"
export DOTFILES_DIR="$HOME/Dropbox/Dotfiles"

# Paths
export PATH="$HOME/.local/bin:$PATH"
export PATH="$DOTFILES_DIR/scripts:$PATH"
export PATH="$MATHWIKI_DIR/.scripts:$PATH"
export PATH="/home/zhao/.local/share/gem/ruby/3.0.0/bin:$PATH"

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec startx "$DOTFILES_DIR/config/xinitrc"
fi
