[[ $- != *i* ]] && return

# Alias
alias ls='ls --color=auto'
alias la='LC_ALL=C ls -lhAr --group-directories-first'

# Declutter
export LESSHISTFILE=-
export HISTFILE="$XDG_STATE_HOME/bash/history"

# Host and User Color
export PS1="[\[\e[0;35m\]\u\[\e[0m\]@\[\e[0;36m\]\h\[\e[0m\] \W]\$ "

# Copy bash files to ~/.config/bash
`cp ~/.bashrc ~/.config/bash/.bashrc`
`cp ~/.bash_profile ~/.config/bash/.bash_profile`
