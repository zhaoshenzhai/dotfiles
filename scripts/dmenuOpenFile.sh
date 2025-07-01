#!/bin/bash

DMENU()
{
    dmenu -i -p $1 -nb "#1E2127" -nf "#F8F8F8" -sb "#457eb0" -fn 'courier prime:spacing=1:pixelsize=20' -bw 3 -c -l 15
}

declare -a options=(
    "~/Dropbox/Documents"
    $(echo $DOTFILES_DIR | sed 's:/home/zhao:~:g')
    "~/Dropbox/Others/Reminders"
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
    "~/Dropbox/Others/Reminders")
        dir="$HOME/Dropbox/Others/Reminders"
        choice=$(find $dir -type f -printf "%T@ %Tc %p\n" | grep ".md" | sort -nr | sed 's:.*/home/zhao:~:' | DMENU "$mainChoice/")

        if [[ -f $(echo "$choice" | sed 's:~:/home/zhao:g') ]]; then
            cd "$dir"
            kitty --class reminders,reminders -e nvim $(echo "$choice" | sed 's:~:/home/zhao:g')
        fi
    ;;
esac
