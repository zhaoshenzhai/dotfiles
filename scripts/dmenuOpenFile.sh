#!/bin/bash

DMENU()
{
    dmenu -i -p $1 -nb "#1E2127" -nf "#F8F8F8" -sb "#457eb0" -fn 'courier prime:spacing=1:pixelsize=20' -bw 3 -c -l 15
}

declare -a options=(
    "~/Dropbox/Documents"
    "~/Dropbox/Dotfiles"
    "~/Dropbox/Others/Reminders"
    "~/Movies_Shows"
)

mainChoice=$(printf '%s\n' "${options[@]}" | DMENU "~/")

case $mainChoice in
    "~/Dropbox/Documents")
        dir="$HOME/Dropbox/Documents"
        file=$(find $dir -printf "%T@ %Tc %p\n" | grep ".pdf" | sort -nr | sed 's:.*/::' | DMENU $(echo "$mainChoice/" | sed 's:/home/zhao:~:g'))

        if [[ -f "$dir/$file" ]]; then
            touch "$dir/$file"
            zathura "$dir/$file"
        fi
    ;;
    "~/Dropbox/Dotfiles")
        dir="$HOME/Dropbox/Dotfiles"
        choice=$(find $dir -type f -printf "%T@ %Tc %p\n" | grep -v ".git\|dmenu/" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU "$mainChoice/")

        if [[ -f $(echo "$choice" | sed 's:~:/home/zhao:g') ]]; then
            cd "$dir"
            kitty -e nvim $(echo "$choice" | sed 's:~:/home/zhao:g')
        fi
    ;;
    "~/Dropbox/Others/Reminders")
        dir="$HOME/Dropbox/Others/Reminders"
        choice=$(find $dir -type f -printf "%T@ %Tc %p\n" | grep ".md" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU "$mainChoice/")

        if [[ -f $(echo "$choice" | sed 's:~:/home/zhao:g') ]]; then
            cd "$dir"
            kitty --class reminders,reminders -e nvim $(echo "$choice" | sed 's:~:/home/zhao:g')
        fi
    ;;
    "~/Movies_Shows")
        dir="$HOME/Movies_Shows"
        file=$(find $dir -type f -printf "%T@ %Tc %p\n" | grep -e ".mp4" -e ".webm" -e ".mkv" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU "$mainChoice/")
        fileFull=$(echo "$file" | sed 's:~:/home/zhao:g')

        if [[ -f "$fileFull" ]]; then
            touch $fileFull
            mpv "$fileFull" --sub-file="$(echo "$fileFull" | sed 's/\.mp4/\.srt/g' | sed 's/\.webm/\.srt/g')"
        fi
    ;;
esac
