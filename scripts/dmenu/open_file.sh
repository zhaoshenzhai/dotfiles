#!/bin/bash

YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

source "$HOME/.config/scripts/dmenu/theme.sh"

declare -a options=(
    "MathWiki   ~/Dropbox/MathWiki/"
    "Textbooks  ~/Dropbox/Textbooks/"
    "HS Notes   ~/Dropbox/Highschool/Course_Notes/"
    "Reminders  ~/Dropbox/Others/Reminders/"
    "Configs    ~/.config/"
    "Scripts    ~/.config/scripts/"
    "Shows      ~/Downloads/"
)

mainChoice=$(printf '%s\n' "${options[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')
mainChoiceName=$(echo "$mainChoice" | sed 's/\~.*//g' | sed 's/\ \ \ *//g')

case $mainChoiceName in
    "MathWiki")
        dir="$HOME/Dropbox/MathWiki"
        declare -a choices=(
            "Notes          ./Notes/"
            "Images         ./Images/"
            "Scripts        ./.scripts/"
            "Snippets       ./.obsidian/snippets/"
            "README         ./README.md"
            "preamble       ./preamble.sty"
            "imageConfig    ./imageConfig.tex"
            "imageTemplate  ./imageTemplate.tex"
        )
        choice=$(printf '%s\n' "${choices[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')
        choiceName=$(echo "$choice" | sed 's/\ .*//g')
        
        if [[ "$choice" ]]; then
            case $choiceName in
                "Notes")
                    MathWikiNotesDir="$HOME/Dropbox/MathWiki/Notes/"

                    file=$(find $MathWikiNotesDir -printf "%T@ %Tc %p\n" | grep ".md" | sort -nr | sed 's:.*/::' | dmenu -i -p 'Open:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                    if [ "$file" ]; then
                        alacritty --class nvim,nvim -e nvim "$MathWikiNotesDir$file"
                    fi
                ;;
                "Images")
                    MathWikiImagesDir="$HOME/Dropbox/MathWiki/Images/"

                    folder=$(find $MathWikiImagesDir -mindepth 1 -type d | sort -r | cut -c$((${#MathWikiImagesDir}+1))- | dmenu -i -p 'Open:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                    if [ "$folder" ]; then
                        alacritty --class image,image -e nvim "$MathWikiImagesDir$folder/image.tex"
                    fi
                ;;
                "Scripts")
                    MathWikiScriptsDir="$dir/.scripts"
                    declare -a MathWikiScripts=(
                        "main             ./.scripts/main.sh"
                        "stats            ./.scripts/stats.sh"
                        "ghost            ./.scripts/ghost.sh"
                        "search           ./.scripts/search.sh"
                        "newTikZ          ./.scripts/newTikZ.sh"
                        "mathLinks        ./.scripts/mathLinks.sh"
                        "massEditing      ./.scripts/massEditing.sh"
                        "updateImages     ./.scripts/updateImages.sh"
                        "getCurrentImage  ./.scripts/getCurrentImage.sh"
                    )

                    MathWikiScriptsChoice=$(printf '%s\n' "${MathWikiScripts[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                    if [ "$MathWikiScriptsChoice" ]; then
                        alacritty --class sys,sys -e nvim $(printf '%s\n' "${MathWikiScriptsChoice}" | sed 's,\ \.,'"$dir"',g' | awk '{printf $NF}')
                    fi
                ;;
                "Snippets")
                    MathWikiSnippetsDir="$dir/.obsidian/snippets"
                    declare -a MathWikiSnippets=(
                        "links           ./.obsidian/snippets/links.css"
                        "lists           ./.obsidian/snippets/lists.css"
                        "bgColor         ./.obsidian/snippets/bgColor.css"
                        "centerImages    ./.obsidian/snippets/centerImages.css"
                        "slidingPanes    ./.obsidian/snippets/slidingPanes.css"
                        "listsLineBreak  ./.obsidian/snippets/listsLineBreak.css"
                    )

                    MathWikiSnippetsChoice=$(printf '%s\n' "${MathWikiSnippets[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                    if [ "$MathWikiSnippetsChoice" ]; then
                        alacritty --class sys,sys -e nvim $(printf '%s\n' "${MathWikiSnippetsChoice}" | sed 's,\ \.,'"$dir"',g' | awk '{printf $NF}')
                    fi
                ;;
                *)
                    alacritty --class sys,sys -e nvim $(printf '%s\n' "${choice}" | sed 's,\ \.,'"$dir"',g' | awk '{printf $NF}')
                ;;
            esac
        fi
    ;;
    "Textbooks")
        dir="$HOME/Dropbox/Textbooks/"

        choice=$(find $dir -printf "\n%AD %AT %p" | grep ".pdf" | sort -nr | sed 's:.*/::' | dmenu -i -p 'Open:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            zathura "$dir$choice"
        fi
    ;;
    "HS Notes")
        dir="$HOME/Dropbox/Highschool/Course_Notes"
        declare -a notes=(
            "Introduction to Linear Algebra       ./Introduction_to_Linear_Algebra/Introduction_to_Linear_Algebra.pdf"
            "Introduction to Algebra              ./Introduction_to_Algebra/Introduction_to_Algebra.pdf"
            "Introduction to Topology             ./Introduction_to_Topology/Introduction_to_Topology.pdf"
            "Introduction to Set Theory           ./Introduction_to_Set_Theory/Introduction_to_Set_Theory/"
            "Introduction to Classical Mechanics  ./Introduction_to_Classical_Mechanics/Introduction_to_Classical_Mechanics.pdf"
            "Introduction to Real Analysis        ./Introduction_to_Real_Analysis/Introduction_to_Real_Analysis.pdf"
            "AP Physics C                         ./AP_Physics_C/AP_Physics_C.pdf"
            "AP Calculus BC                       ./AP_Calculus_BC/AP_Calculus_BC.pdf"
            "AP Calculus AB                       ./AP_Calculus_AB/AP_Calculus_AB.pdf"
            "Physics Core                         ./Physics_Core/Physics_Core.pdf"
        )

        choice=$(printf '%s\n' "${notes[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')
        choiceName=$(echo "$choice" | sed 's/\.\/.*//g' | sed 's/\ \ \ *//g')

        if [ "$choice" ]; then
            if [[ "$choiceName" == "Introduction to Set Theory" ]]; then
                declare -a chapters=(
                    "Chapter 1  ./Introduction_to_Set_Theory/exercises/Chapter_1/Chapter_1.pdf"
                    "Chapter 2  ./Introduction_to_Set_Theory/exercises/Chapter_2/Chapter_2.pdf"
                    "Chapter 3  ./Introduction_to_Set_Theory/exercises/Chapter_3/Chapter_3.pdf"
                    "Chapter 4  ./Introduction_to_Set_Theory/exercises/Chapter_4/Chapter_4.pdf"
                    "Chapter 5  ./Introduction_to_Set_Theory/exercises/Chapter_5/Chapter_5.pdf"
                )

                setTheoryExercises=$(printf '%s\n' "${chapters[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                if [[ "$setTheoryExercises" ]]; then
                    zathura $(printf '%s\n' "${setTheoryExercises}" | sed 's,\ \.,'"$dir"',g' | awk '{printf $NF}')
                fi
            else
                zathura $(printf '%s\n' "${choice}" | sed 's,\ \.,'"$dir"',g' | awk '{printf $NF}')
            fi
        fi
    ;;
    "Reminders")
        dir="$HOME/Dropbox/Others/Reminders/"

        choice=$(find $dir -type f | cut -c$((${#dir}+1))- | dmenu -i -p 'Open:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty -e nvim "$dir$choice"
        fi
    ;;
    "Configs")
        dir="$HOME/.config"
        declare -a configs=(
            "mpv           ./mpv/"
            "nvim          ./nvim/"
            "installGuide  ./installGuide.md"
            "xmonad        ./xmonad/xmonad.hs"
            "xmobar        ./xmonad/xmobarrc"
            "alacritty     ./alacritty/alacritty.yml"
            "zathura       ./zathura/zathurarc"
            "qutebrowser   ./qutebrowser/config.py"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')
        choiceName=$(echo "$choice" | sed 's/\.\/.*//g' | sed 's/\ \ \ *//g')

        if [ "$choice" ]; then
            case $choiceName in
                "nvim")
                    nvimDir="$dir/nvim"
                    declare -a nvimConfigs=(
                        "snippets              ./nvim/UltiSnips/"
                        "pluggins              ./nvim/config/pluggins/"
                        "init.vim              ./nvim/init.vim"
                        "theme.vim             ./nvim/config/theme.vim"
                        "mappings.vim          ./nvim/config/mappings.vim"
                        "MathWiki.vim          ./nvim/config/MathWiki.vim"
                        "textObjects.vim       ./nvim/config/textObjects.vim"
                        "compileAndRun.vim     ./nvim/config/compileAndRun.vim"
                        "keyboardMovement.vim  ./nvim/config/keyboardMovement.vim"
                    )

                    nvimChoice=$(printf '%s\n' "${nvimConfigs[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')
                    nvimChoiceName=$(echo "$nvimChoice" | sed 's/\.\/.*//g' | sed 's/\ \ \ *//g')

                    if [[ "$nvimChoice" ]]; then
                        case `$nvimChoice` in
                            "pluggins              ./nvim/config/pluggins/")
                                nvimPlugginsDir="$nvimDir/config/pluggins"
                                declare -a nvimPluggins=(
                                    "ncm2.vim         ./nvim/config/pluggins/ncm2.vim"
                                    "vimtex.vim       ./nvim/config/pluggins/vimtex.vim"
                                    "ultisnips.vim    ./nvim/config/pluggins/ultisnips.vim"
                                    "syntaxRange.vim  ./nvim/config/pluggins/syntaxRange.vim"
                                )

                                nvimPlugginsChoice=$(printf '%s\n' "${nvimPluggins[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                                if [[ "$nvimPlugginsChoice" ]]; then
                                    alacritty --class sys,sys -e nvim $(printf '%s\n' "${nvimPlugginsChoice}" | sed 's,\ \.,'"$dir"',g' | awk '{printf $NF}')
                                fi
                            ;;
                            "snippets              ./nvim/UltiSnips/")
                                nvimSnippetsDir="$nvimDir/UltiSnips"
                                declare -a nvimSnippets=(
                                    "markdown.snippets  ./nvim/UltiSnips/markdown.snippets"
                                    "tex.snippets       ./nvim/UltiSnips/tex.snippets"
                                    "sh.snippets        ./nvim/UltiSnips/sh.snippets"
                                    "cs.snippets        ./nvim/UltiSnips/cs.snippets"
                                )

                                nvimSnippetsChoice=$(printf '%s\n' "${nvimSnippets[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                                if [[ "$nvimSnippetsChoice" ]]; then
                                    alacritty --class sys,sys -e nvim $(printf '%s\n' "${nvimSnippetsChoice}" | sed 's,\ \.,'"$dir"',g' | awk '{printf $NF}')
                                fi
                            ;;
                            *)
                                alacritty --class sys,sys -e nvim $(printf '%s\n' "${nvimChoice}" | sed 's,\ \.,'"$dir"',g' | awk '{printf $NF}')
                            ;;
                        esac
                    fi
                ;;
                "mpv")
                    mpvDir="$dir/mpv"
                    declare -a mpvConfigs=(
                        "mpv    ./mpv/mpv.conf"
                        "input  ./mpv/input.conf"
                    )

                    mpvChoice=$(printf '%s\n' "${mpvConfigs[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')
                    mpvChoiceName=$(echo "$mpvChoice" | sed 's/\.\/.*//g' | sed 's/\ \ \ *//g')

                    if [[ "$mpvChoice" ]]; then
                        alacritty --class sys,sys -e nvim $(printf '%s\n' "${mpvChoice}" | sed 's,\ \.,'"$dir"',g' | awk '{printf $NF}')
                    fi
                ;;
                *)
                    alacritty --class sys,sys -e nvim $(printf '%s\n' "${choice}" | sed 's,\ \.,'"$dir"',g' | awk '{printf $NF}')
                ;;
            esac
        fi
    ;;
    "Scripts")
        dir="$HOME/.config/scripts"
        declare -a configs=(
            "dmenu          ./dmenu/open_file.sh"
            "init           ./init.sh"
            "gitCommit      ./gitCommit.sh"
            "bluetooth      ./bluetooth.sh"
            "diskFree       ./diskFree.sh"
            "volumeControl  ./volume/volumeControl.sh"
            "xmobarVolume   ./volume/xmobarVolume.sh"
            "newJava        ./new/newJava.sh"
            "newLaTeX       ./new/newLaTeX.sh"
            "javaCompile    ./compile/javaCompile.sh"
            "cSharpCompile  ./compile/cSharpCompile.sh"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty --class sys,sys -e nvim $(printf '%s\n' "${choice}" | sed 's,\ \.,'"$dir"',g' | awk '{printf $NF}')
        fi
    ;;
    "Shows")
        dir="$HOME/Downloads"
        declare -a configs=(
            "Dark       ./Dark/"
            "Mr. Robot  ./Mr._Robot/"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')
        choiceName=$(echo "$choice" | sed 's/\.\/.*//g' | sed 's/\ \ \ *//g')

        if [ "$choice" ]; then
            choiceDir="$dir/$(echo "$choice" | sed 's/^.*\.\///g')"

            file=$(find $choiceDir/vids/ -printf "%T@ %Tc %p\n" | grep ".mp4" | sed 's:.*/::' | sort -d | dmenu -i -p 'Open:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

            if [ "$file" ]; then
                sub=$(echo "$file" | sed 's/\.mp4/\.srt/g')
                `mpv $choiceDir/vids/$file --sub-file=$choiceDir/subs/$sub`
            fi
        fi
    ;;
esac
