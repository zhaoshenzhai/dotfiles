# Archlinux Setup
    - https://wiki.archlinux.org/title/Installation_guide
    - https://www.youtube.com/watch?v=68z11VAYMS8
    - https://www.youtube.com/watch?v=pouX5VvX0_Q

    ## Get bootable usb
        - Download .iso file
        - Download rufus
        - Write with gpt(?) format
        - Disable secure boot
        - Unplug usb, shutdown, plug usb, power up, and pray

    ## Internet
        - `iwctl`
            - `device list`
            - ` station wlan0 scan`
            - ` station wlan0 get-networks`
            - ` station wlan0 connect "Z-5GHz"`
            - `exit`
            - `ip addr`
            - `ping archlinux.org`

    ## Partition disk
        - `lsblk`
        - Here, `DISK` stands for the main disk
        - `cfdisk /dev/DISK`
            - Delete everything and make three partitions:
                - 100M for boot
                - 4G for virtual memory
                - Rest for /
            - Write, then type yes
        - `mkfs.ext4 /dev/DISKp3`
        - `mkfs.fat -F 32 /dev/DISKp1`
        - `mkswap /dev/DISKp2`
        - `mount /dev/DISKp3 /mnt`
        - `mkdir -p /mnt/boot/efi`
        - `mount /dev/DISKp1 /mnt/boot/efi`
        - `swapon /dev/DISKp2`

    ## Base packages
        - `pacstrap /mnt linux linux-firmware base base-devel grub efibootmgr vim networkmanager xterm git`
            - If pgp error, run `pacman -Sy archlinux-keyring` and retry

    ## Configure
        - `genfstab /mnt > /mnt/etc/fstab`
        - `ln -sf /usr/share/zoneinfo/TIMEZONE /etc/localtime`
        - `date`
        - `hwclock --systohc`
        - `vim /etc/locale.gen`
            - Uncomment en_US.UTF-8
        - `locale-gen`
        - `vim /etc/locale.conf`
            - LANG=en_US.UTF-8
        - `passwd`
        - `useradd -m -G wheel -s /bin/bash zhao`
        - `passwd zhao`
        - `EDITOR=vim visudo`
            - G and uncomment
        - `systemctl enable NetworkManager`
        - `grub-install /dev/DISK`
        - `grub-mkconfig -o /boot/grub/grub.cfg`
        - `exit`
        - `umount -a`
        - Reboot, unplug usb, and pray

    ## Packages
        - `git clone https://aur.archlinux.org/yay-git`
        - `makepkg -si`
        - `sudo vim /etc/pacman.conf`
            - Uncomment Color
        - Pacman:
            - xorg xorg-xinit xmonad xmonad-contrib xmobar neovim dmenu alacritty vifm pipewire pipewire-pulse pipewire-jack pamixer playerctl bluez bluez-utils nitrogen ttf-courier-prime ttf-font-awesome ttf-anonymous-pro ttf-cmu-serif nerd-fonts-mononoki neofetch htop tree unzip bc xclip scrot python python-pip npm ghostscript pdf2svg texlive-core texlive-latexextra texlive-science texlive-pictures gpicview zathura zathura-pdf-mupdf obsidian qutebrowser yt-dlp mpv
        - pip
            - pynvim numpy matplotlib
        - npm
            - typescript

    ## Natural scrolling
        - `sudo vim /usr/share/X11/xorg.conf.d/40-libinput.conf`
        - Under "touchpad": Option "NaturalScrolling" "true"

    ## Dotfiles
        - `git clone https://github.com/zhaoshenzhai/dotfiles.git`
        - `mv ~/.config/bash/.bashrc ~/.bashrc`
        - `mv ~/.config/bash/.bash_profile ~/.bash_profile`
        - `bash`
        - `cd ~/.config/dmenu_patched`
        - `sudo make install`

    ## Xorg
        - `cp /etc/X11/xinit/xinitrc ~/.xinitrc`
        - `nvim ~/.xinitrc`
            - Cleanup
            - Change last block to `exec xmonad`
        - Reboot

    ## Nvim
        - `sh -c 'curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'`

    ## Nitrogen
        - Add ~/.config/wallpapers

    ## Dropbox and git repos
        - `yay dropbox spotify qutebrowser-profile-git`
        - `mkdir ~/Dropbox`
        - `cd ~/Dropbox`
        - `git clone https://github.com/zhaoshenzhai/MathWiki.git`
        - `git clone https://github.com/zhaoshenzhai/obsidian-mathlinks.git`
        - `dropbox`; don't close this until finished

    ## Git
        - `git config --global user.name "zhaoshenzhai"`
        - `git config --global user.email "email"`
        - Generate new PAT, copy it
        - `nvim ~/.config/.gitpat`
            - Paste

    ## Vifm
        - zo
        - :sort N
        - Add marks:
            - c ~/.config [xmonad]
            - d ~/Dropbox [MathWiki]
            - h ~/ [none]
            - m ~/Dropbox/MathWiki [Notes]
            - o ~/Dropbox/obsidian-mathlinks [src]
            - u ~/Dropbox/University/Courses/22F [MATH133]

    ## Qutebrowser
        - `qutebrowser-profile --new 'Z'`
        - `qutebrowser-profile --new 'P'`
            - Set theme: #1e2127 #f8f8ff
        - `sudo nvim /usr/bin/qutebrowser-profile`
            - Search for window.title_format
            - Change to {perc}qute [${session}$]{title_sep}...
        - Move `cookies_Z.txt` and `cookies_P.txt` to `~/.config`

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
