[[ $- != *i* ]] && return

# Alias
alias ls='ls --color=auto'
alias la='LC_ALL=C ls -lhAr --group-directories-first'

# Declutter
export LESSHISTFILE=-
export HISTFILE="$HOME/.local/state/bash/history"

# Host and User Color
export PS1="[\[\e[0;35m\]\u\[\e[0m\]@\[\e[0;36m\]\h\[\e[0m\] \W]\$ "

# Terminal Colors
export YELLOW='\033[0;33m'
export PURPLE='\033[0;35m'
export GREEN='\033[0;32m'
export CYAN='\033[0;36m'
export BLUE='\033[0;34m'
export RED='\033[0;31m'
export NC='\033[0m'
