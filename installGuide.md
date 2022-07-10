# Base packages:
    - linux linux-firmware base base-devel grub efibootmgr vim networkmanager xterm git

# Boot is something with grub.efi

# Yay:
    - git clone https://aur.archlinux.org/yay-git and makepkg -si

# More Packages:
    - Xmonad:
        xorg xorg-xinit xmonad xmobar-contrib xmobar dmenu alacritty vifm pipewire pipewire-pulse pipewire-jack pamixer nitrogen ttf-courier-prime ttf-font-awesome ttf-anonymous-pro ttf-cmu-serif nerd-fonts-mononoki neofetch
    - Tools:
        neovim python htop tree unzip ghostscript pdf2svg bc scrot colorpicker texlive-core texlive-latexextra texlive-science texlive-pictures 
    - Programs:
        zathura zathura-pdf-mupdf obsidian dropbox spotify qutebrowser

# Clone dotfiles:
    - git clone https://github.com/zhaoshenzhai/dotfiles.git

# Nvim pluggins:
    - sh -c 'curl -fL0 "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Natural scrolling: 
    - Add `Option "NaturalScrolling" "true"` to `/usr/share/X11/xorg.conf.d/40-libinput.conf`
