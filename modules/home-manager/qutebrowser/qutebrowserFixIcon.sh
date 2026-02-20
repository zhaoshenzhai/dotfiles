cp qutebrowser.icns /Applications/qutebrowser.app/Contents/Resources/qutebrowser.icns
cp qutebrowser.png /Applications/qutebrowser.app/Contents/Resources/qutebrowser.png

find /Applications/qutebrowser.app -type f -name "*.svg" -delete

find /Applications/qutebrowser.app -type f -name "qutebrowser-*.png" | while read -r img; do
    dim=$(basename "$img" .png | cut -d'-' -f2 | cut -d'x' -f1)
    sips -z "$dim" "$dim" qutebrowser.png --out "$img"
done

touch /Applications/qutebrowser.app
