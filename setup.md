- https://wiki.archlinux.org/title/Installation_guide

# Get bootable usb
    - Download .iso file
    - Download rufus
    - Plug usb, power up, disable secure boot
    - `cat /sys/firmware/efi/fw_platform_size`

# Internet
    - `iwctl`
        - `device list`
        - ` station wlan0 scan`
        - ` station wlan0 get-networks`
        - ` station wlan0 connect WIFI_NAME`
        - `exit`
        - `ping archlinux.org`

    - `lsblk`
    - Here, `DISK` stands for the main disk
    - `cfdisk /dev/DISK`
        - Delete everything and make three partitions:
            - 512M for boot
            - 4G for swap
            - Rest for /
        - Write and Quit

# Format disks
    - `mkfs.ext4 /dev/DISKp3`
    - `mkfs.fat -F 32 /dev/DISKp1`
    - `mkswap /dev/DISKp2`
    - `mount /dev/DISKp3 /mnt`
    - `mkdir -p /mnt/boot/efi`
    - `mount /dev/DISKp1 /mnt/boot/efi`
    - `swapon /dev/DISKp2`

# Base packages
    - `pacstrap /mnt linux linux-firmware sof-firmware base base-devel grub efibootmgr networkmanager xterm vim neovim git`
        - If pgp error, run `pacman -Sy archlinux-keyring` and retry

# Mount
    - `genfstab /mnt > /mnt/etc/fstab`
    - `cat /mnt/etc/fstab`
    - `arch-chroot /mnt`

# Configurations
    ## Timezone
        - `ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime`
        - `timedatectl set-timezone Canada/Eastern`
        - `hwclock --systohc`
        - `date`
    ## System
        - `systemctl enable systemd-timesyncd.service`
        - `systemctl enable NetworkManager`
    ## Localization
        - `nvim /etc/locale.gen`
            - Uncomment en_US.UTF-8
        - `locale-gen`
        - `nvim /etc/locale.conf`
            - LANG=en_US.UTF-8
    ## Users
        - `nvim /etc/hostname`
        - `passwd`
        - `useradd -m -G wheel -s /bin/bash zhao`
        - `passwd zhao`
        - `EDITOR=nvim visudo`
            - Press G, find correct line, and uncomment
    ## Bootloader
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
