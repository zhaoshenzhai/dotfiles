- https://wiki.archlinux.org/title/Installation_guide

# Get bootable usb
    - Download .iso file
    - Download rufus
    - Disable secure boot
    - Unplug usb, shutdown, plug usb, power up

# Internet
    - `iwctl`
        - `device list`
        - ` station wlan0 scan`
        - ` station wlan0 get-networks`
        - ` station wlan0 connect WIFI_NAME`
        - `exit`
        - `ip addr`
        - `ping archlinux.org`

# Partition disk
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

# Base packages
    - `pacstrap /mnt linux linux-firmware base base-devel grub efibootmgr networkmanager xterm neovim git`
        - If pgp error, run `pacman -Sy archlinux-keyring` and retry

# Configure
    - `genfstab /mnt > /mnt/etc/fstab`
    - `ln -sf /usr/share/zoneinfo/TIMEZONE /etc/localtime`
    - `date`
    - `systemctl enable systemd-timesyncd.service`
    - `hwclock --systohc`
    - `nvim /etc/locale.gen`
        - Uncomment en_US.UTF-8
    - `locale-gen`
    - `nvim /etc/locale.conf`
        - LANG=en_US.UTF-8
    - `passwd`
    - `useradd -m -G wheel -s /bin/bash zhao`
    - `passwd zhao`
    - `EDITOR=nvim visudo`
        - G and uncomment
    - `systemctl enable NetworkManager`
    - `grub-install /dev/DISK`
    - `grub-mkconfig -o /boot/grub/grub.cfg`
    - `exit`
    - `umount -a`
    - Reboot and unplug usb

# Dotfiles
    - `mkdir ~/Dropbox`
    - `cd ~/Dropbox`
    - `git clone https://github.com/zhaoshenzhai/dotfiles.git`
    - `./dotfiles.sh`
    - `bash`

# Packages
    - Pacman
        - X
            - xorg xorg-xinit xmonad xmonad-contrib xmobar xclip
        - Programs
            - dmenu alacritty vifm nitrogen neofetch zathura zathura-pdf-mupdf obsidian qutebrowser
        - Audio
            - pipewire pipewire-pulse pipewire-jack pamixer playerctl bluez bluez-utils alsa-utils sof-firmware alsa-ucm-conf pavucontrol ffmpeg-compat-57
        - Fonts
            - ttf-font-awesome ttf-anonymous-pro adobe-source-han-sans-cn-fonts
        - Tools
            - htop tree bc scrot texlive biber python python-pip npm ghostscript pdf2svg zip unzip meh arandr
    - Yay
        - ttf-courier-prime ttf-cmu-serif ttf-mononoki-nerd noto-fonts qutebrowser-profile-git colorpicker chromium dropbox spotify spicetify-cli
    - pip
        - pynvim numpy matplotlib
    - npm
        - typescript

# Reboot, should `startx` immediately

# Nvim
    - `nvim`
        - :PlugInstall

# Natural scrolling
    - `sudo nvim /usr/share/X11/xorg.conf.d/40-libinput.conf`
    - Under "touchpad":
        - `Option "NaturalScrolling" "true"`
        - `Option "Tapping" "on"`

# Nitrogen
    - Add ~/.config/wallpapers

# Vifm
    - zo
    - :sort N

# Qutebrowser
    - `qutebrowser-profile --load 'Z' --new`
    - `qutebrowser-profile --load 'P' --new`
        - Set theme: #1e2127 #f8f8ff
    - `sudo nvim /usr/bin/qutebrowser-profile`
        - Search for window.title_format
        - Change to {perc}qute [${session}$]{title_sep}...

# Vim-markdown
    - `nvim ~/.config/nvim/plugged/vim-markdown/ftplugin/markdown.vim`
        - Comment out lines on code blocks

# Audio
    - If no speaker:
        - `sudo nvim /etc/modprobe.d/audio-fix.conf`
            - blacklist snd-sof-pci
            - options snd-intel-dspcfg dsp_driver=1
