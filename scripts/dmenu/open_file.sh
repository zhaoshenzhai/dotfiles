#!/bin/bash

. "$HOME/.config/scripts/dmenu/theme"

declare -a options=(
    "Course Notes"
    "Textbooks"
    "Reminders"
    "Config"
)

main_choice=$(printf '%s\n' "${options[@]}" | dmenu -i -p 'Options:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

case $main_choice in
    "Course Notes")
        declare -a configs=(
            "Topology"
            "Set Theory"
            "Real Analysis"
            "Classical Mechanics"
            "Linear Algebra"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Edit:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        case $choice in
            "Topology")
                alacritty --class nvim,nvim -e nvim "$HOME/Study/Highschool_Course_Notes/Introduction_to_Topology/content/Chapter_1/Topological_Spaces_and_Continuity.tex"
            ;;
            "Set Theory")
                alacritty --class nvim,nvim -e nvim "$HOME/Study/Highschool_Course_Notes/Introduction_to_Set_Theory/Introduction_to_Set_Theory.tex"
            ;;
            "Real Analysis")
                alacritty --class nvim,nvim -e nvim "$HOME/Study/Highschool_Course_Notes/Introduction_to_Real_Analysis/Introduction_to_Real_Analysis.tex"
            ;;
            "Classical Mechanics")
                alacritty --class nvim,nvim -e nvim "$HOME/Study/Highschool_Course_Notes/Introduction_to_Classical_Mechanics/Introduction_to_Classical_Mechanics.tex"
            ;;
            "Linear Algebra")
                alacritty --class nvim,nvim -e nvim "$HOME/Study/Highschool_Course_Notes/Introduction_to_Linear_Algebra/Introduction_To_Linear_Algebra.tex"
            ;;
        esac
    ;;
    "Textbooks")
        root_path="$HOME/Dropbox/Textbooks/Math/"

        choice=$(find $root_path -type f \( ! -regex '.*/\..*' \) | cut -c$((${#root_path}+1))- | dmenu -i -p 'Open:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            zathura "$root_path$choice"
        else
            exit 0
        fi
    ;;
    "Reminders")
        root_path="$HOME/.config/notes/"

        choice=$(find $root_path -type f | cut -c$((${#root_path}+1))- | dmenu -i -p 'Open:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty --class reminders,reminders -e nvim "$root_path$choice"
        else
            exit 0
        fi
    ;;
    "Config")
        declare -a configs=(
            "nvim - $HOME/.config/nvim/init.vim"
            "xmonad - $HOME/.config/xmonad/xmonad.hs"
            "xmobar - $HOME/.config/xmonad/xmobarrc"
            "zathura - $HOME/.config/zathura/zathurarc"
            "dmenu - $HOME/.config/scripts/dmenu/open_file.sh"
            "alacritty - $HOME/.config/alacritty/alacritty.yml"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Edit:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty --class sys,sys -e nvim $(printf '%s\n' "${choice}" | awk '{printf $NF}')
        else
            exit 0
        fi
    ;;
esac
