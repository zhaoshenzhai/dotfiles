[[ $- != *i* ]] && return

# Alias
alias ls='ls --color=auto'
alias la='LC_ALL=C ls -lhAr --group-directories-first'

# Editor
export EDITOR=nvim
export TERMINAL="/usr/bin/alacritty"

# Xmonad
export XMONAD_CONFIG_DIR="/home/zhao/.config/xmonad"
export XMONAD_CACHE_DIR="/home/zhao/.config/xmonad"
export XMONAD_DATA_DIR="/home/zhao/.config/xmonad"

# Paths
export PATH="/home/zhao/.config/scripts:$PATH"
export PATH="/home/zhao/Dropbox/MathWiki/.scripts:$PATH"

# Host and User Color
export PS1="[\[\e[0;35m\]\u\[\e[0m\]@\[\e[0;36m\]\h\[\e[0m\] \W]\$ "

# Copy bash files to .config/
`cp ~/.bashrc ~/.config/bash/.bashrc`
`cp ~/.bash_profile ~/.config/bash/.bash_profile`
