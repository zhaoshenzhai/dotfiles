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
    $(echo $MATHWIKI_DIR | sed 's:/home/zhao:~:g')
    $(echo $DOTFILES_DIR | sed 's:/home/zhao:~:g')
    "~/Dropbox/Documents"
    "~/Dropbox/MathLinks"
    "~/Dropbox/Others/Reminders"
)

mainChoice=$(printf '%s\n' "${options[@]}" | DMENU "~/")

case $mainChoice in
    $(echo $MATHWIKI_DIR | sed 's:/home/zhao:~:g'))
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

        if [[ $(ls "$dir/Lectures" | wc -l) != 0 ]]; then
            choices=$(echo -e "${choices[@]}" | sed 's:Images:Images\n'"$mainChoice"'/Lectures:g' | sed 's/\ /\n/g')
            choice=$(printf '%s\n' "${choices}" | DMENU $mainChoice/)
        else
            choice=$(printf '%s\n' "${choices[@]}" | DMENU $mainChoice/)
        fi

        if [[ "$choice" ]]; then
            case $choice in
                "$mainChoice/Lectures")
                    MathWikiLecturesDir="$dir/Lectures"

                    folder=$(find $MathWikiLecturesDir -type d -printf "%T@ %Tc %p\n" | tail -n +2 | sort -nr | sed 's:.*/home/zhao:~:' | DMENU $(echo "$MathWikiLecturesDir/" | sed 's:/home/zhao:~:g'))
                    folderAbs=$(echo "$folder" | sed 's:~:/home/zhao:g')

                    if [[ "$folder" ]]; then
                        touch "$folderAbs"
                        choice=$(find $folderAbs -printf "\n%A@ %p" | grep ".md" | sort -nr | sed 's:.*/::' | DMENU "$folder")
                        choice=$(basename "$choice")

                        if [ "$choice" ]; then
                            file="$folderAbs/$choice"
                            touch "$file"
                            alacritty --class nvim,nvim -e nvim "$file" &
                        fi
                    fi
                ;;
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
    $(echo $DOTFILES_DIR | sed 's:/home/zhao:~:g'))
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
                    file=$(find $scriptsDir -printf "%T@ %Tc %p\n" | grep ".sh" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU $(echo "$scriptsDir/" | sed 's:/home/zhao:~:g'))

                    if [ "$file" ]; then
                        alacritty --class sys,sys -e nvim $(echo "$file" | sed 's:~:/home/zhao:g')
                    fi
                ;;
                "$mainChoice/config")
                    configDir=$(echo "$mainChoice/config" | sed 's:~:/home/zhao:g')
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
    "~/Dropbox/Documents")
        dir=$(echo "$mainChoice" | sed 's:~:/home/zhao:g')
        folder=$(find $dir -type d -printf "%T@ %Tc %p\n" | tail -n +2 | sort -nr | sed 's:.*/home/zhao:~:' | DMENU "$mainChoice/")
        folderAbs=$(echo "$folder" | sed 's:~:/home/zhao:g')
        if [[ "$folder" ]]; then
            touch "$folderAbs"
            choice=
            if [[ $(basename "$folder") != "LaTeX" ]]; then
                choice=$(find $folderAbs -printf "\n%A@ %p" | grep ".pdf" | sort -nr | sed 's:.*/::' | DMENU "$folder")
            else
                choice=$(find $folderAbs -printf "\n%A@ %p" | grep ".pdf" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU "$folder")
            fi
            choice=$(basename "$choice")

            if [ "$choice" ]; then
                file="$folderAbs/$choice"
                touch "$file"
                zathura "$file"
            fi
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
        choice=$(find $dir -type f -printf "%T@ %Tc %p\n" | grep ".md" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU "$mainChoice/")

        if [ "$choice" ]; then
            alacritty --class reminders,reminders -e nvim $(echo "$choice" | sed 's:~:/home/zhao:g')
        fi
    ;;
esac
