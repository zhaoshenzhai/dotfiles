- https://wiki.archlinux.org/title/Installation_guide

# Get bootable usb
    - Download .iso file
    - Download rufus
    - Plug usb, power up, disable secure boot

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
            - 300M for boot
            - 512M for swap
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
        - Press G, find correct line, and uncomment
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
    - `mv dotfiles Dotfiles`
    - `cd Dotfiles`
    - `./dotfiles.sh`
    - `bash`

# Reboot, should `startx` immediately

# Nvim
    - `nvim`
        - :PlugInstall

# Touchpad
    - `xinput list`
    - Get id of touchpad
    - `xinput list-props ID`
    - `xinput set-prop ID OPTION SETTING`

# Nitrogen
    - Add ~/.config/wallpapers

# Vifm
    - zo
    - :sort N

# Vim-markdown
    - `nvim ~/.config/nvim/plugged/vim-markdown/ftplugin/markdown.vim`
        - Comment out lines on code blocks

# Audio
    - If no speaker:
        - `sudo nvim /etc/modprobe.d/audio-fix.conf`
            - blacklist snd-sof-pci
            - options snd-intel-dspcfg dsp_driver=1
