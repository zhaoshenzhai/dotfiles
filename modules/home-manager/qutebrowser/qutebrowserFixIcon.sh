# 1. Replace the macOS app bundle icon
cp qutebrowser.icns /Applications/qutebrowser.app/Contents/Resources/qutebrowser.icns

# 2. Delete the internal Qt SVGs so it falls back to PNGs
find /Applications/qutebrowser.app -type f -name "*.svg" -delete

# 3. Replace all internal PNGs with correctly sized versions of your gray icon
find /Applications/qutebrowser.app -type f -name "qutebrowser-*.png" | while read -r img; do
    # Extract the dimension from the filename (e.g., 64 from "qutebrowser-64x64.png")
    dim=$(basename "$img" .png | cut -d'-' -f2 | cut -d'x' -f1)
    
    # Use macOS sips to dynamically resize and overwrite the file
    sips -z "$dim" "$dim" qutebrowser.png --out "$img"
done

# 4. Touch the app bundle to force macOS to register the modification
touch /Applications/qutebrowser.app
