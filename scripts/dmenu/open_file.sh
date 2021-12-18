#!/bin/bash

. "$HOME/.config/scripts/dmenu/theme"

declare -a options=(
    "Courses"
    "Textbooks"
    "Config"
    "Scripts"
    "Snippets"
    "Reminders"
)

main_choice=$(printf '%s\n' "${options[@]}" | dmenu -i -p 'Options:' $colors -bw 0 -h 30 -fn 'courier prime:spacing=1:pixelsize=20')

case $main_choice in
    "Courses")
        declare -a configs=(
            "Introduction to Algebra"
            "Introduction to Topology"
            "Introduction to Set Theory"
            "Introduction to Linear Algebra"
            "Introduction to Classical Mechanics"
            "Introduction to Real Analysis"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Edit:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        case $choice in
            "Introduction to Algebra")
                alacritty --class nvim,nvim -e nvim "$HOME/Study/Highschool_Course_Notes/Introduction_to_Algebra/content/Chapter_1/Basic_Category_Theory.tex"
            ;;
            "Introduction to Topology")
                alacritty --class nvim,nvim -e nvim "$HOME/Study/Highschool_Course_Notes/Introduction_to_Topology/content/Chapter_1/Topological_Spaces_and_Continuity.tex"
            ;;
            "Introduction to Set Theory")
                alacritty --class nvim,nvim -e nvim "$HOME/Study/Highschool_Course_Notes/Introduction_to_Set_Theory/Introduction_to_Set_Theory.tex"
            ;;
            "Introduction to Real Analysis")
                alacritty --class nvim,nvim -e nvim "$HOME/Study/Highschool_Course_Notes/Introduction_to_Real_Analysis/Introduction_to_Real_Analysis.tex"
            ;;
            "Introduction to Classical Mechanics")
                alacritty --class nvim,nvim -e nvim "$HOME/Study/Highschool_Course_Notes/Introduction_to_Classical_Mechanics/Introduction_to_Classical_Mechanics.tex"
            ;;
            "Introduction to Linear Algebra")
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
        root_path="$HOME/Reminders/"

        choice=$(find $root_path -type f | cut -c$((${#root_path}+1))- | dmenu -i -p 'Open:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty --class reminders,reminders -e nvim "$root_path$choice"
        else
            exit 0
        fi
    ;;
    "Snippets")
        root_path="$HOME/.config/nvim/UltiSnips/"

        choice=$(find $root_path -type f | cut -c$((${#root_path}+1))- | dmenu -i -p 'Open:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty --class sys,sys -e nvim "$root_path$choice"
        else
            exit 0
        fi
    ;;
    "Config")
        dir="$HOME/.config"
        declare -a configs=(
            "nvim - $dir/nvim/init.vim"
            "xmonad - $dir/xmonad/xmonad.hs"
            "xmobar - $dir/xmonad/xmobarrc"
            "zathura - $dir/zathura/zathurarc"
            "alacritty - $dir/alacritty/alacritty.yml"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Edit:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty --class sys,sys -e nvim $(printf '%s\n' "${choice}" | awk '{printf $NF}')
        else
            exit 0
        fi
    ;;
    "Scripts")
        dir="$HOME/.config/scripts"
        declare -a configs=(
            "dmenu - $dir/dmenu/open_file.sh"
            "init - $dir/init.sh"
            "newJava - $dir/newJava.sh"
            "newLaTeX - $dir/newLaTeX.sh"
            "javaCompile - $dir/javaCompile.sh"
            "cSharpCompile - $dir/cSharpCompile.sh"
            "volumeControl - $dir/volumeControl.sh"
            "xmobarVolume - $dir/xmobarVolume.sh"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Edit:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty --class sys,sys -e nvim $(printf '%s\n' "${choice}" | awk '{printf $NF}')
        else
            exit 0
        fi
    ;;
esac
