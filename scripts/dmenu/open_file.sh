#!/bin/bash

source "$HOME/.config/scripts/dmenu/theme.sh"

declare -a options=(
    "MathWiki"
    "Textbooks"
    "HS Notes"
    "Reminders"
    "Configs"
    "Scripts"
)

main_choice=$(printf '%s\n' "${options[@]}" | dmenu -i -p 'Options:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

case $main_choice in
    "MathWiki")
        dir="$HOME/Dropbox/MathWiki"
        declare -a choices=(
            "Notes          $dir/Notes/"
            "Images         $dir/Images/"
            "Scripts        $dir/.scripts/"
            "Snippets       $dir/.obsidian/snippets/"
            "README         $dir/README.md"
            "preamble       $dir/preamble.sty"
            "imageConfig    $dir/imageConfig.tex"
            "imageTemplate  $dir/imageTemplate.tex"
        )
        choice=$(printf '%s\n' "${choices[@]}" | dmenu -i -p 'Edit:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')
        
        if [[ "$choice" ]]; then
            case $choice in
                "Notes          $dir/Notes/")
                    MathWikiNotesDir="$HOME/Dropbox/MathWiki/Notes/"

                    file=$(find $MathWikiNotesDir -printf "%T@ %Tc %p\n" | grep ".md" | sort -nr | sed 's:.*/::' | dmenu -i -p 'Open:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                    if [ "$file" ]; then
                        alacritty --class nvim,nvim -e nvim "$MathWikiNotesDir$file"
                    fi
                ;;
                "Images         $dir/Images/")
                    MathWikiImagesDir="$HOME/Dropbox/MathWiki/Images/"

                    folder=$(find $MathWikiImagesDir -mindepth 1 -type d | sort -r | cut -c$((${#MathWikiImagesDir}+1))- | dmenu -i -p 'Open:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                    if [ "$folder" ]; then
                        alacritty --class image,image -e nvim "$MathWikiImagesDir$folder/image.tex"
                    fi
                ;;
                "Scripts        $dir/.scripts/")
                    MathWikiScriptsDir="$dir/.scripts"
                    declare -a MathWikiScripts=(
                        "main             $MathWikiScriptsDir/main.sh"
                        "stats            $MathWikiScriptsDir/stats.sh"
                        "ghost            $MathWikiScriptsDir/ghost.sh"
                        "search           $MathWikiScriptsDir/search.sh"
                        "newTikZ          $MathWikiScriptsDir/newTikZ.sh"
                        "mathLinks        $MathWikiScriptsDir/mathLinks.sh"
                        "massEditing      $MathWikiScriptsDir/massEditing.sh"
                        "updateImages     $MathWikiScriptsDir/updateImages.sh"
                        "getCurrentImage  $MathWikiScriptsDir/getCurrentImage.sh"
                    )

                    MathWikiScriptsChoice=$(printf '%s\n' "${MathWikiScripts[@]}" | dmenu -i -p 'Edit:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                    if [ "$MathWikiScriptsChoice" ]; then
                        alacritty --class sys,sys -e nvim $(printf '%s\n' "${MathWikiScriptsChoice}" | awk '{printf $NF}')
                    fi
                ;;
                "Snippets       $dir/.obsidian/snippets/")
                    MathWikiSnippetsDir="$dir/.obsidian/snippets"
                    declare -a MathWikiSnippets=(
                        "links           $MathWikiSnippetsDir/links.css"
                        "lists           $MathWikiSnippetsDir/lists.css"
                        "centerImages    $MathWikiSnippetsDir/centerImages.css"
                        "slidingPanes    $MathWikiSnippetsDir/slidingPanes.css"
                        "listsLineBreak  $MathWikiSnippetsDir/listsLineBreak.css"
                    )

                    MathWikiSnippetsChoice=$(printf '%s\n' "${MathWikiSnippets[@]}" | dmenu -i -p 'Edit:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                    if [ "$MathWikiSnippetsChoice" ]; then
                        alacritty --class sys,sys -e nvim $(printf '%s\n' "${MathWikiSnippetsChoice}" | awk '{printf $NF}')
                    fi
                ;;
                *)
                    alacritty --class sys,sys -e nvim $(printf '%s\n' "${choice}" | awk '{printf $NF}')
                ;;
            esac
        fi
    ;;
    "Textbooks")
        root_path="$HOME/Dropbox/Textbooks/"

        choice=$(find $root_path -printf "\n%AD %AT %p" | grep ".pdf" | sort -nr | sed 's:.*/::' | dmenu -i -p 'Open:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            zathura "$root_path$choice"
        fi
    ;;
    "HS Notes")
        root_path="$HOME/Dropbox/Highschool/Course_Notes/"

        choice=$(find $root_path -maxdepth 2 -printf "\n%A+ %p" | grep ".pdf" | sort -nr | sed 's:.*/::' | dmenu -i -p 'Open:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            course=$(printf '%s\n' "${choice}" | sed 's/.pdf//g')
            zathura "$root_path$course/$course.pdf"
        fi
    ;;
    "Reminders")
        root_path="$HOME/Dropbox/Misc/Reminders/"

        choice=$(find $root_path -type f | cut -c$((${#root_path}+1))- | dmenu -i -p 'Open:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty -e nvim "$root_path$choice"
        fi
    ;;
    "Configs")
        dir="$HOME/.config"
        declare -a configs=(
            "nvim       $dir/nvim/"
            "xmonad     $dir/xmonad/xmonad.hs"
            "xmobar     $dir/xmonad/xmobarrc"
            "zathura    $dir/zathura/zathurarc"
            "alacritty  $dir/alacritty/alacritty.yml"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Edit:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            if [[ "$choice" == "nvim       $dir/nvim/" ]]; then
                nvimDir="$dir/nvim"
                declare -a nvimConfigs=(
                    "snippets              $nvimDir/UltiSnips/"
                    "pluggins              $nvimDir/config/pluggins/"
                    "init.vim              $nvimDir/init.vim"
                    "compileAndRun.vim     $nvimDir/config/compileAndRun.vim"
                    "keyboardMovement.vim  $nvimDir/config/keyboardMovement.vim"
                    "mappings.vim          $nvimDir/config/mappings.vim"
                    "MathWiki.vim          $nvimDir/config/MathWiki.vim"
                    "textObjects.vim       $nvimDir/config/textObjects.vim"
                    "theme.vim             $nvimDir/config/theme.vim"
                )

                nvimChoice=$(printf '%s\n' "${nvimConfigs[@]}" | dmenu -i -p 'Edit:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                if [[ "$nvimChoice" ]]; then
                    case $nvimChoice in
                        "pluggins              $nvimDir/config/pluggins/")
                            nvimPlugginsDir="$nvimDir/config/pluggins"
                            declare -a nvimPluggins=(
                                "ncm2.vim         $nvimPlugginsDir/ncm2.vim"
                                "syntaxRange.vim  $nvimPlugginsDir/syntaxRange.vim"
                                "ultisnips.vim    $nvimPlugginsDir/ultisnips.vim"
                                "vimtex.vim       $nvimPlugginsDir/vimtex.vim"
                            )

                            nvimPlugginsChoice=$(printf '%s\n' "${nvimPluggins[@]}" | dmenu -i -p 'Edit:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                            if [[ "$nvimPlugginsChoice" ]]; then
                                alacritty --class sys,sys -e nvim $(printf '%s\n' "${nvimPlugginsChoice}" | awk '{printf $NF}')
                            fi
                        ;;
                        "snippets              $nvimDir/UltiSnips/")
                            nvimSnippetsDir="$nvimDir/UltiSnips"
                            declare -a nvimSnippets=(
                                "markdown.snippets  $nvimSnippetsDir/markdown.snippets"
                                "tex.snippets       $nvimSnippetsDir/tex.snippets"
                                "sh.snippets        $nvimSnippetsDir/sh.snippets"
                                "cs.snippets        $nvimSnippetsDir/cs.snippets"
                            )

                            nvimSnippetsChoice=$(printf '%s\n' "${nvimSnippets[@]}" | dmenu -i -p 'Edit:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

                            if [[ "$nvimSnippetsChoice" ]]; then
                                alacritty --class sys,sys -e nvim $(printf '%s\n' "${nvimSnippetsChoice}" | awk '{printf $NF}')
                            fi
                        ;;
                        *)
                            alacritty --class sys,sys -e nvim $(printf '%s\n' "${nvimChoice}" | awk '{printf $NF}')
                        ;;
                    esac
                fi
            else
                alacritty --class sys,sys -e nvim $(printf '%s\n' "${choice}" | awk '{printf $NF}')
            fi
        fi
    ;;
    "Scripts")
        dir="$HOME/.config/scripts"
        declare -a configs=(
            "dmenu          $dir/dmenu/open_file.sh"
            "init           $dir/init.sh"
            "gitCommit      $dir/gitCommit.sh"
            "bluetooth      $dir/bluetooth.sh"
            "volumeControl  $dir/volume/volumeControl.sh"
            "xmobarVolume   $dir/volume/xmobarVolume.sh"
            "diskFree       $dir/diskFree.sh"
            "newJava        $dir/new/newJava.sh"
            "newLaTeX       $dir/new/newLaTeX.sh"
            "javaCompile    $dir/compile/javaCompile.sh"
            "cSharpCompile  $dir/compile/cSharpCompile.sh"
        )

        choice=$(printf '%s\n' "${configs[@]}" | dmenu -i -p 'Edit:' $flags $colors -fn 'courier prime:spacing=1:pixelsize=20')

        if [ "$choice" ]; then
            alacritty --class sys,sys -e nvim $(printf '%s\n' "${choice}" | awk '{printf $NF}')
        fi
    ;;
esac
