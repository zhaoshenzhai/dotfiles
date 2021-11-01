old_time=$(date -r /home/zhao/.config/scripts/scriptFiles/theme_fixed)

run_variety() {
    if [ $fixed -eq 0 ]; then
        variety -n
    fi
}

run_wal() {
    if [ $fixed -eq 0 ]; then
        wallpaper_path=$(<~/.config/variety/wallpaper/wallpaper.jpg.txt)
    else
        wallpaper_path="/home/zhao/.wallpapers/"
    fi

    wal -i $wallpaper_path -q
}

while true; do
    fixed=$(</home/zhao/.config/scripts/scriptFiles/theme_fixed)
    run_variety
    sleep 2s
    run_wal

    new_time=$old_time
    count=0
    while [ "$new_time" = "$old_time" ]; do
        sleep 1
        echo "$count"
        new_time="$(date -r /home/zhao/.config/scripts/scriptFiles/theme_fixed)"
        ((count=count+1))
        if [ "$count" -ge 18 ]; then
            new_time=0
        fi
    done
    old_time=$(date -r /home/zhao/.config/scripts/scriptFiles/theme_fixed)
done
