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
    `echo $MATHWIKI_DIR | sed 's:/home/zhao:~:g'`
    `echo $DOTFILES_DIR | sed 's:/home/zhao:~:g'`
    "~/Dropbox/Textbooks"
    "~/Dropbox/Papers"
    "~/Dropbox/MathLinks"
    "~/Dropbox/Others/Reminders"
    "~/Dropbox/Others/Highschool/Course_Notes"
)

mainChoice=$(printf '%s\n' "${options[@]}" | DMENU "~/")

case $mainChoice in
    `echo $MATHWIKI_DIR | sed 's:/home/zhao:~:g'`)
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
            "$mainChoice/.gitignore"
            "$mainChoice/.gitattributes"
        )

        choice=$(printf '%s\n' "${choices[@]}" | DMENU $mainChoice/)
        
        if [[ "$choice" ]]; then
            case $choice in
                "$mainChoice/Notes")
                    MathWikiNotesDir="$dir/Notes"
                    file=$(find $MathWikiNotesDir -printf "%T@ %Tc %p\n" | grep ".md" | sort -nr | sed 's:.*/::' | DMENU $(echo "$MathWikiNotesDir/" | sed 's:/home/zhao:~:g'))

                    if [ "$file" ]; then
                        alacritty --class nvim,nvim -e nvim "$MathWikiNotesDir/$file" &
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
    `echo $DOTFILES_DIR | sed 's:/home/zhao:~:g'`)
        declare -a configs=(
            "$mainChoice/config"
            "$mainChoice/scripts"
            "$mainChoice/setup.md"
            "$mainChoice/dotfiles.sh"
        )
        choice=$(printf '%s\n' "${configs[@]}" | DMENU "$mainChoice/")

        if [ "$choice" ]; then
            case $choice in
                "$mainChoice/scripts")
                    scriptsDir=$(echo "$mainChoice/scripts" | sed 's:~:/home/zhao:g')
                    echo -e "${YELLOW}$scriptsDir${NC}"
                    file=$(find $scriptsDir -printf "%T@ %Tc %p\n" | grep ".sh" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU $(echo "$scriptsDir/" | sed 's:/home/zhao:~:g'))

                    if [ "$file" ]; then
                        alacritty --class sys,sys -e nvim $(echo "$file" | sed 's:~:/home/zhao:g')
                    fi
                ;;
                "$mainChoice/config")
                    configDir=$(echo "$mainChoice/config" | sed 's:~:/home/zhao:g')
                    echo -e "${YELLOW}$configDir${NC}"
                    file=$(find $configDir -type f -printf "%T@ %Tc %p\n" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU $(echo "$configDir/" | sed 's:/home/zhao:~:g'))

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
        choice=$(find $dir -printf "\n%A@ %p" | grep ".pdf" | sort -nr | sed 's:.*/::' | DMENU "$mainChoice/")

        if [ "$choice" ]; then
            touch "$dir/$choice"
            zathura "$mainChoice/$choice"
        fi
    ;;
    "~/Dropbox/Papers")
        dir=$(echo "$mainChoice" | sed 's:~:/home/zhao:g')
        choice=$(find $dir -printf "\n%A@ %p" | grep ".pdf" | sort -nr | sed 's:.*/::' | DMENU "$mainChoice/")

        if [ "$choice" ]; then
            touch "$dir/$choice"
            zathura "$mainChoice/$choice"
        fi
    ;;
    "~/Dropbox/MathLinks")
        dir=$(echo "$mainChoice" | sed 's:~:/home/zhao:g')
        declare -a choices=(
            "$mainChoice/src/main.ts"
            "$mainChoice/src/settings.ts"
            "$mainChoice/README.md"
            "$mainChoice/package.json"
            "$mainChoice/manifest.json"
            "$mainChoice/tsconfig.json"
            "$mainChoice/versions.json"
            "$mainChoice/esbuild.config.mjs"
            "$mainChoice/.gitignore"
        )

        choice=$(printf '%s\n' "${choices[@]}" | DMENU $mainChoice/)

        if [[ "$choice" ]]; then
            alacritty -e nvim $(echo "$choice" | sed 's:~:/home/zhao:g')
        fi
    ;;
    "~/Dropbox/Others/Reminders")
        dir="$HOME/Dropbox/Others/Reminders"
        cd $dir
        choice=$(find $dir -type f -printf "%T@ %Tc %p\n" | grep ".md" | sort -nr | sed 's:^.*\ /home:/home:' | DMENU $(echo "$mainChoice/" | sed 's:/home/zhao:~:g'))

        if [ "$choice" ]; then
            alacritty --class reminders,reminders -e nvim $(echo "$choice" | sed 's:~:/home/zhao:g')
        fi
    ;;
    "~/Dropbox/Others/Highschool/Course_Notes")
        dir="$HOME/Dropbox/Others/Highschool/Course_Notes"
        declare -a notes=(
            "$mainChoice/Introduction_to_Linear_Algebra/Introduction_to_Linear_Algebra.pdf"
            "$mainChoice/Introduction_to_Algebra/Introduction_to_Algebra.pdf"
            "$mainChoice/Introduction_to_Topology/Introduction_to_Topology.pdf"
            "$mainChoice/Introduction_to_Set_Theory/Introduction_to_Set_Theory.pdf"
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
            alacritty --class media,media -e nvim $(echo "$choice" | sed 's:~:/home/zhao:g' | sed 's/\.pdf/\.tex/g')
        fi
    ;;
esac
