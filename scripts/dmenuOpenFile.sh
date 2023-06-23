#!/bin/bash

DMENU()
{
    dmenu -i -p $1 -nb "#1E2127" -nf "#F8F8F8" -sb "#457eb0" -fn 'courier prime:spacing=1:pixelsize=20' -bw 3 -c -l 15
}

declare -a options=(
    $(echo $MATHWIKI_DIR | sed 's:/home/zhao:~:g')
    $(echo $DOTFILES_DIR | sed 's:/home/zhao:~:g')
    "~/Dropbox/Documents"
    $(echo $MATHLINKS_DIR | sed 's:/home/zhao:~:g')
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

        choice=$(printf '%s\n' "${choices[@]}" | DMENU $mainChoice/)

        if [[ "$choice" ]]; then
            case $choice in
                "$mainChoice/Notes")
                    MathWikiNotesDir="$dir/Notes"
                    file=$(find $MathWikiNotesDir -printf "%T@ %Tc %p\n" | grep ".md" | sort -nr | sed 's:.*/::' | DMENU $(echo "$MathWikiNotesDir/" | sed 's:/home/zhao:~:g'))

                    if [ "$file" ]; then
                        cd $MathWikiNotesDir
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
        dir="$HOME/Dropbox/Documents"
        file=$(find $dir -printf "%T@ %Tc %p\n" | grep ".pdf" | sort -nr | sed 's:.*/::' | DMENU $(echo "$mainChoice/" | sed 's:/home/zhao:~:g'))

        if [ "$file" ]; then
            touch "$dir/$file"
            zathura "$dir/$file"
        fi
    ;;
    $(echo $MATHLINKS_DIR | sed 's:/home/zhao:~:g'))
        dir=$(echo "$mainChoice" | sed 's:~:/home/zhao:g')
        declare -a choices=(
            "$mainChoice/src/main.ts"
            "$mainChoice/src/tools.ts"
            "$mainChoice/src/preview.ts"
            "$mainChoice/src/settings.ts"
            "$mainChoice/README.md"
            "$mainChoice/makefile"
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
