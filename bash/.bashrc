[[ $- != *i* ]] && return
alias ls='ls --color=auto'

# Alias
alias la='LC_ALL=C ls -lhAr --group-directories-first'

# Editor
EDITOR=nvim

# Paths
export PATH="$PATH:$HOME/bin"
export PATH="/home/zhao/.local/bin:$PATH"
export PATH="/home/zhao/.config/scripts:$PATH"
export PATH="/home/zhao/MathWiki/.scripts:$PATH"
export PATH="/home/zhao/.local/share/gem/ruby/3.0.0/bin:$PATH"

# Host and User Color
export PS1="[\[\e[0;35m\]\u\[\e[0m\]@\[\e[0;36m\]\h\[\e[0m\] \W]\$ "

# Terminal
export TERMINAL="/usr/bin/alacritty"

# Copy bash files to .config/
`cp ~/.bashrc ~/.config/bash/.bashrc`
`cp ~/.bash_profile ~/.config/bash/.bash_profile`
