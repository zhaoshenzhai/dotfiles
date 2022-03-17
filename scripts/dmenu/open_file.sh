#!/bin/bash

. "$HOME/.config/scripts/dmenu/theme"

declare -a options=(
    "MathWiki"
    "Textbooks"
    "Old Notes"
    "STEP Prep"
    "Config"
    "Scripts"
    "Snippets"
    "Reminders"
)

main_choice=$(printf '%s\n' "${options[@]}" | dmenu -i -p 'Options:' $colors -bw 0 -h 30 -fn 'courier prime:spacing=1:pixelsize=20')

case $main_choice in
    "MathWiki")
        declare -a choices=(
            "Notes"
            "Images"
        )
        choice=$(printf '%s\n' "${choices[@]}" | dmenu -i -p 'Edit:' $colors -bw 0 -h 30 -fn 'courier prime:spacing=1:pixelsize=20')
        
        case $choice in
            "Notes")
                path="$HOME/MathWiki/Notes/"

                file=$(find $path -printf "%T@ %Tc %p\n" | grep ".md" | sort -nr | sed 's:.*/::' | dmenu -i -p 'Open:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

                if [ "$file" ]; then
                    alacritty --class nvim,nvim -e nvim "$path$file"
                else
                    exit 0
                fi
            ;;
            "Images")
                path="$HOME/MathWiki/Images/"

                folder=$(find $path -mindepth 1 -type d | sort -r | cut -c$((${#path}+1))- | dmenu -i -p 'Open:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

                if [ "$folder" ]; then
                    alacritty --class image,image -e nvim "$path$folder/image.tex"
                else
                    exit 0
                fi
            ;;
        esac
    ;;
    "Textbooks")
        root_path="$HOME/Dropbox/Textbooks/"

        choice=$(find $root_path -printf "\n%AD %AT %p" | grep ".pdf" | sort -nr | sed 's:.*/::' | dmenu -i -p 'Open:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            zathura "$root_path$choice"
        else
            exit 0
        fi
    ;;
    "Old Notes")
        declare -a configs=(
            "Introduction to Algebra"
            "Introduction to Topology"
            "Introduction to Set Theory"
            "Introduction to Linear Algebra"
            "Introduction to Classical Mechanics"
            "Introduction to Real Analysis"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Edit:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            course=$(printf '%s\n' "${choice}" | sed 's/\ /_/g')
            zathura "~/Highschool_Course_Notes/$course/$course.pdf"
        else
            exit 0
        fi
    ;;
    "STEP Prep")
        declare -a choices=(
            "Foundations"
            "Papers"
            "Book"
            "Specification"
            "Boundaries"
        )
        choice=$(printf '%s\n' "${choices[@]}" | dmenu -i -p 'Edit:' $colors -bw 0 -h 30 -fn 'courier prime:spacing=1:pixelsize=20')

        case $choice in
            "Foundations")
                path="$HOME/STEP/Foundation/"

                file=$(find $path -printf "%T@ %Tc %p\n" | grep ".pdf" | sort -nr | sed 's:.*/::' | dmenu -i -p 'Open:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

                if [ "$file" ]; then
                    zathura "$path$file"
                else
                    exit 0
                fi
            ;;
            "Papers")
                path="$HOME/STEP/Papers/"

                file=$(find $path | grep ".pdf" | sort -nr | sed 's:.*/::' | dmenu -i -p 'Open:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

                if [ "$file" ]; then
                    zathura "$path$file"
                else
                    exit 0
                fi
            ;;
            "Book")
                zathura "$HOME/STEP/Advanced Problems in Mathematics.pdf"
            ;;
            "Specification")
                zathura "$HOME/STEP/Specification.pdf"
            ;;
            "Boundaries")
                zathura "$HOME/STEP/Boundaries.pdf"
            ;;
        esac
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
            "newJava - $dir/new/newJava.sh"
            "newLaTeX - $dir/new/newLaTeX.sh"
            "javaCompile - $dir/compile/javaCompile.sh"
            "cSharpCompile - $dir/compile/cSharpCompile.sh"
            "volumeControl - $dir/volume/volumeControl.sh"
            "xmobarVolume - $dir/volume/xmobarVolume.sh"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Edit:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty --class sys,sys -e nvim $(printf '%s\n' "${choice}" | awk '{printf $NF}')
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
    "Reminders")
        root_path="$HOME/Dropbox/Reminders/"

        choice=$(find $root_path -type f | cut -c$((${#root_path}+1))- | dmenu -i -p 'Open:' $lines $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty --class reminders,reminders -e nvim "$root_path$choice"
        else
            exit 0
        fi
    ;;
esac
