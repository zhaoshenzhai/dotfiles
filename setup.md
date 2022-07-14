# Base packages:
    - linux linux-firmware base base-devel grub efibootmgr vim networkmanager xterm git

# Wifi
    - Touch `/etc/wpa_supplicant/wpa_supplicant-wlp1s0.conf` with contents
        `ctrl_interface=/run/wpa_supplicant
        bg_scan=""

        network={
            ssid="Z-5GHz"
            psk=_______________
        }`
    - Psk is generated via `wpa_passphrase Z 'password'`. Need to `su` first. Cat it.
    - Touch `/etc/systemd/network/10-wireless.network` with contents
        `[Match]
        Name=wl*

        [Network]
        DHCP=ipv4`
    - Need to `sudo systemctl enable ______`. Reboot.

# Boot is something with grub.efi

# Yay:
    - git clone https://aur.archlinux.org/yay-git and makepkg -si

# More Packages:
    - Xmonad:
        xorg xorg-xinit xmonad xmobar-contrib xmobar dmenu alacritty vifm pipewire pipewire-pulse pipewire-jack pamixer playerctl bluez bluez-utils nitrogen ttf-courier-prime ttf-font-awesome ttf-anonymous-pro ttf-cmu-serif nerd-fonts-mononoki neofetch
    - Tools:
        neovim python python-pip htop tree unzip ghostscript pdf2svg bc scrot colorpicker texlive-core texlive-latexextra texlive-science texlive-pictures xclip
    - Programs:
        zathura zathura-pdf-mupdf obsidian dropbox spotify qutebrowser qutebrowser-profile-git yt-dlp mpv
    - Pip stuff:
        pynvim

# Clone dotfiles:
    - git clone https://github.com/zhaoshenzhai/dotfiles.git

# Nvim pluggins:
    - sh -c 'curl -fL0 "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Natural scrolling: 
    - Add `Option "NaturalScrolling" "true"` to `/usr/share/X11/xorg.conf.d/40-libinput.conf`

# Pacman colors:
    - Uncomment `Color` in `/etc/pacman.conf`

# Qutebrowser profiles:
    - Z for primary and P for secondary
    - Use `--new` flag instead of `--load`; should be fixed
    - To change from `qute [Z] - Title` to `Z - Title`, modify line containing `window.title_format` in `/usr/bin/qutebrowser-profile`

# Qutebrowser mpv youtube --mark-watched
    - Install chromium and setup profiles
    - Install Open cookie.txt extension (or something like that)
    - Enable it in youtube.com and download the files
    - Name them `cookie_Z.txt` and `cookie_P.txt`
    - Put them in `~/.config`
    - Uninstall chromium
