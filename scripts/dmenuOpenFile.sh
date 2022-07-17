#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

DMENU()
{
    dmenu -i -p $1 -nb "#1E2127" -nf "#F8F8F8" -sb "#457eb0" -fn 'courier prime:spacing=1:pixelsize=20' -bw 3 -c -l 15
}

declare -a options=(
    "~/Dropbox/MathWiki"
    "~/Dropbox/Textbooks"
    "~/Dropbox/Highschool/Course_Notes"
    "~/Dropbox/Others/Reminders"
    "~/.config"
)

mainChoice=$(printf '%s\n' "${options[@]}" | DMENU "~/")

case $mainChoice in
    "~/Dropbox/MathWiki")
        dir=$(echo "$mainChoice" | sed 's:~:/home/zhao:g')
        declare -a choices=(
            "$mainChoice/Notes"
            "$mainChoice/Images"
            "$mainChoice/.scripts"
            "$mainChoice/.obsidian/snippets"
            "$mainChoice/README.md"
            "$mainChoice/preamble.sty"
            "$mainChoice/imageConfig.tex"
            "$mainChoice/imageTemplate.tex"
        )

        choice=$(printf '%s\n' "${choices[@]}" | DMENU $mainChoice/)
        
        if [[ "$choice" ]]; then
            case $choice in
                "$mainChoice/Notes")
                    MathWikiNotesDir="$dir/Notes"
                    file=$(find $MathWikiNotesDir -printf "%T@ %Tc %p\n" | grep ".md" | sort -nr | sed 's:.*/::' | DMENU $(echo "$MathWikiNotesDir/" | sed 's:/home/zhao:~:g'))

                    if [ "$file" ]; then
                        alacritty --class nvim,nvim -e nvim "$MathWikiNotesDir/$file"
                    fi
                ;;
                "$mainChoice/Images")
                    MathWikiImagesDir="$dir/Images"
                    folder=$(find $MathWikiImagesDir -mindepth 1 -type d | sort -r | sed 's:/home/zhao:~:g' | DMENU $(echo "$MathWikiImagesDir/" | sed 's:/home/zhao:~:g'))

                    if [ "$folder" ]; then
                        alacritty --class media,media -e nvim $(echo "$folder/image.tex" | sed 's:~:/home/zhao:g')
                    fi
                ;;
                "$mainChoice/.scripts")
                    MathWikiScriptsDir="$dir/.scripts"
                    file=$(find $MathWikiScriptsDir -printf "%T@ %Tc %p\n" | grep ".sh" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU $(echo "$MathWikiScriptsDir/" | sed 's:/home/zhao:~:g'))

                    if [ "$file" ]; then
                        alacritty --class sys,sys -e nvim $(echo "$file" | sed 's:~:/home/zhao:g')
                    fi
                ;;
                "$mainChoice/.obsidian/snippets")
                    MathWikiSnippetsDir="$dir/.obsidian/snippets"
                    file=$(find $MathWikiSnippetsDir -printf "%T@ %Tc %p\n" | grep ".css" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU $(echo "$MathWikiSnippetsDir/" | sed 's:/home/zhao:~:g'))

                    if [ "$file" ]; then
                        alacritty --class sys,sys -e nvim $(echo "$file" | sed 's:~:/home/zhao:g')
                    fi
                ;;
                *)
                    alacritty --class sys,sys -e nvim $(echo "$choice" | sed 's:~:/home/zhao:g')
                ;;
            esac
        fi
    ;;
    "~/Dropbox/Textbooks")
        dir=$(echo "$mainChoice" | sed 's:~:/home/zhao:g')
        choice=$(find $dir -printf "\n%AD %AT %p" | grep ".pdf" | sort -nr | sed 's:.*/::' | DMENU "$mainChoice/")

        if [ "$choice" ]; then
            zathura "$mainChoice/$choice"
        fi
    ;;
    "~/Dropbox/Highschool/Course_Notes")
        dir="$HOME/Dropbox/Highschool/Course_Notes"
        declare -a notes=(
            "$mainChoice/Introduction_to_Linear_Algebra/Introduction_to_Linear_Algebra.pdf"
            "$mainChoice/Introduction_to_Algebra/Introduction_to_Algebra.pdf"
            "$mainChoice/Introduction_to_Topology/Introduction_to_Topology.pdf"
            "$mainChoice/Introduction_to_Set_Theory/Introduction_to_Set_Theory"
            "$mainChoice/Introduction_to_Set_Theory/exercises/Chapter_1/Chapter_1.pdf"
            "$mainChoice/Introduction_to_Set_Theory/exercises/Chapter_2/Chapter_2.pdf"
            "$mainChoice/Introduction_to_Set_Theory/exercises/Chapter_3/Chapter_3.pdf"
            "$mainChoice/Introduction_to_Set_Theory/exercises/Chapter_4/Chapter_4.pdf"
            "$mainChoice/Introduction_to_Set_Theory/exercises/Chapter_5/Chapter_5.pdf"
            "$mainChoice/Introduction_to_Classical_Mechanics/Introduction_to_Classical_Mechanics.pdf"
            "$mainChoice/Introduction_to_Real_Analysis/Introduction_to_Real_Analysis.pdf"
            "$mainChoice/AP_Physics_C/AP_Physics_C.pdf"
            "$mainChoice/AP_Calculus_BC/AP_Calculus_BC.pdf"
            "$mainChoice/AP_Calculus_AB/AP_Calculus_AB.pdf"
            "$mainChoice/Physics_Core/Physics_Core.pdf"
        )
        choice=$(printf '%s\n' "${notes[@]}" | DMENU "$mainChoice/")

        if [ "$choice" ]; then
            zathura $choice
        fi
    ;;
    "~/Dropbox/Others/Reminders")
        dir="$HOME/Dropbox/Others/Reminders"
        choice=$(find $dir -type f | sed 's:/home/zhao:~:g' | DMENU "$mainChoice/")

        if [ "$choice" ]; then
            alacritty -e nvim $(echo "$choice" | sed 's:~:/home/zhao:g')
        fi
    ;;
    "~/.config")
        dir="$HOME/.config"
        declare -a configs=(
            "$mainChoice/nvim"
            "$mainChoice/scripts"
            "$mainChoice/setup.md"
            "$mainChoice/mpv/mpv.conf"
            "$mainChoice/mpv/input.conf"
            "$mainChoice/xmonad/xmonad.hs"
            "$mainChoice/xmonad/xmobarrc"
            "$mainChoice/zathura/zathurarc"
            "$mainChoice/qutebrowser/config.py"
            "$mainChoice/alacritty/alacritty.yml"
        )
        choice=$(printf '%s\n' "${configs[@]}" | DMENU "$mainChoice/")

        if [ "$choice" ]; then
            case $choice in
                "$mainChoice/scripts")
                    scriptsDir="$HOME/.config/scripts"
                    file=$(find $scriptsDir -printf "%T@ %Tc %p\n" | grep ".sh" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU $(echo "$scriptsDir/" | sed 's:/home/zhao:~:g'))

                    if [ "$file" ]; then
                        alacritty --class sys,sys -e nvim $(echo "$file" | sed 's:~:/home/zhao:g')
                    fi
                ;;
                "$mainChoice/nvim")
                    nvimDir="$dir/nvim"
                    declare -a nvimConfigs=(
                        "$mainChoice/nvim/UltiSnips"
                        "$mainChoice/nvim/config/pluggins"
                        "$mainChoice/nvim/init.vim"
                        "$mainChoice/nvim/config/theme.vim"
                        "$mainChoice/nvim/config/mappings.vim"
                        "$mainChoice/nvim/config/MathWiki.vim"
                        "$mainChoice/nvim/config/textObjects.vim"
                        "$mainChoice/nvim/config/compileAndRun.vim"
                        "$mainChoice/nvim/config/keyboardMovement.vim"
                    )
                    nvimChoice=$(printf '%s\n' "${nvimConfigs[@]}" | DMENU "$mainChoice/nvim/")

                    if [[ "$nvimChoice" ]]; then
                        case $nvimChoice in
                            "$mainChoice/nvim/config/pluggins")
                                nvimPlugginsDir="$nvimDir/config/pluggins"
                                declare -a nvimPluggins=(
                                    "$mainChoice/nvim/config/pluggins/ncm2.vim"
                                    "$mainChoice/nvim/config/pluggins/vimtex.vim"
                                    "$mainChoice/nvim/config/pluggins/ultisnips.vim"
                                    "$mainChoice/nvim/config/pluggins/syntaxRange.vim"
                                )
                                nvimPlugginsChoice=$(printf '%s\n' "${nvimPluggins[@]}" | DMENU "$mainChoice/nvim/config/pluggins/")

                                if [[ "$nvimPlugginsChoice" ]]; then
                                    alacritty --class sys,sys -e nvim $(echo "$nvimPlugginsChoice" | sed 's:~:/home/zhao:g')
                                fi
                            ;;
                            "$mainChoice/nvim/UltiSnips")
                                nvimSnippetsDir="$nvimDir/UltiSnips"
                                declare -a nvimSnippets=(
                                    "$mainChoice/nvim/UltiSnips/markdown.snippets"
                                    "$mainChoice/nvim/UltiSnips/tex.snippets"
                                    "$mainChoice/nvim/UltiSnips/sh.snippets"
                                    "$mainChoice/nvim/UltiSnips/cs.snippets"
                                )
                                nvimSnippetsChoice=$(printf '%s\n' "${nvimSnippets[@]}" | DMENU "$mainChoice/nvim/UltiSnips/")

                                if [[ "$nvimSnippetsChoice" ]]; then
                                    alacritty --class sys,sys -e nvim $(echo "$nvimSnippetsChoice" | sed 's:~:/home/zhao:g')
                                fi
                            ;;
                            *)
                                alacritty --class sys,sys -e nvim $(echo "$nvimChoice" | sed 's:~:/home/zhao:g')
                            ;;
                        esac
                    fi
                ;;
                *)
                    alacritty --class sys,sys -e nvim $(echo "$choice" | sed 's:~:/home/zhao:g')
                ;;
            esac
        fi
    ;;
esac
