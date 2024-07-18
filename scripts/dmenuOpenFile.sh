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
    "~/Movies_Shows"
)

mainChoice=$(printf '%s\n' "${options[@]}" | DMENU "~/")

case $mainChoice in
    $(echo $MATHWIKI_DIR | sed 's:/home/zhao:~:g'))
        dir="$MATHWIKI_DIR/Notes"
        file=$(find $dir -printf "%T@ %Tc %p\n" | grep ".md" | sort -nr | sed 's:.*/::' | DMENU $(echo "$dir/" | sed 's:/home/zhao:~:g'))

        cd $dir
        echo -e "${YELLOW}$file${NC}"
        if [[ -f "$dir/$file" ]]; then
            touch "$file"
            kitty --class nvim,nvim -e nvim "$file" &
        elif [[ ! -z "$file" ]]; then
            if [[ ! $(echo "$file" | grep ".md") ]]; then
                file=$file.md
            fi

            cd ..
            hugo new content "$file"
            cd "Notes"

            kitty --class nvim,nvim -e nvim "$file" &
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

                    if [[ -f $(echo "$file" | sed 's:~:/home/zhao:g') ]]; then
                        kitty --class sys,sys -e nvim $(echo "$file" | sed 's:~:/home/zhao:g')
                    fi
                ;;
                "$mainChoice/config")
                    configDir=$(echo "$mainChoice/config" | sed 's:~:/home/zhao:g')
                    file=$(find $configDir -type f -printf "%T@ %Tc %p\n" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU $(echo "$configDir/" | sed 's:/home/zhao:~:g'))

                    if [[ -f $(echo "$file" | sed 's:~:/home/zhao:g') ]]; then
                        kitty --class sys,sys -e nvim $(echo "$file" | sed 's:~:/home/zhao:g')
                    fi
                ;;
                *)
                    if [[ -f $(echo "$choice" | sed 's:~:/home/zhao:g') ]]; then
                        kitty --class sys,sys -e nvim $(echo "$choice" | sed 's:~:/home/zhao:g')
                    fi
                ;;
            esac
        fi
    ;;
    "~/Dropbox/Documents")
        dir="$HOME/Dropbox/Documents"
        file=$(find $dir -printf "%T@ %Tc %p\n" | grep ".pdf" | sort -nr | sed 's:.*/::' | DMENU $(echo "$mainChoice/" | sed 's:/home/zhao:~:g'))

        if [[ -f "$dir/$file" ]]; then
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

        if [[ -f $(echo "$choice" | sed 's:~:/home/zhao:g') ]]; then
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
