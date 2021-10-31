[[ $- != *i* ]] && return
alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# Alias
alias la='ls -la'
alias vi='nvim'
alias vim='nvim'

# Editor
EDITOR=nvim

# Paths
export PATH="$PATH:$HOME/bin"
export PATH="/home/zhao/.local/bin:$PATH"
export PATH="/home/zhao/.config/scripts:$PATH"

# Wal
(cat ~/.cache/wal/sequences &)

# Host and User Color
export PS1="[\[\e[0;35m\]\u\[\e[0m\]@\[\e[0;36m\]\h\[\e[0m\] \W]\$ "

# Copy bash files to .config/bash
`cp ~/.bashrc ~/.config/bash/.bashrc`
`cp ~/.bash_profile ~/.config/bash/.bash_profile`
