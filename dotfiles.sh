#!/bin/bash

sudo sed -i 's/#Color/Color/g' /etc/pacman.conf

# Connection
res=$(curl -I archlinux.org 2>&1)
fatal=$(echo $res | grep -o "Could not")
attempt=1
while [[ $fatal ]]; do
    echo -ne "${YELLOW}Connecting... (x$attempt)${NC}\r"
    sleep 1
    res=$(curl -I archlinux.org 2>&1)
    fatal=$(echo $res | grep -o "Could not")
    attempt=$(($attempt + 1))
done

# Yay
mkdir $HOME/Downloads
cd $HOME/Downloads
git clone https://aur.archlinux.org/yay-git
cd yay-git
makepkg -si
cd ..
rm -rf yay-git

# Xinit
yay -Syu xorg xorg-xinit xmonad xmonad-contrib xmobar xclip xdotool dmeny kitty vifm nitrogen neofetch 
ln -sf $HOME/Dropbox/Dotfiles/config/.bashrc $HOME/.bashrc
ln -sf $HOME/Dropbox/Dotfiles/config/.bash_profile $HOME/.bash_profile
rm /home/zhao/.bash_logout

# Configuration
mkdir -p $HOME/.config
cd $HOME/.config
mkdir -p kitty git vifm zathura xmonad qutebrowser/greasemonkey qutebrowser/bookmarks nvim/spell mpv

ln -sf $HOME/Dropbox/Dotfiles/config/kitty.conf $HOME/.config/kitty/kitty.conf
ln -sf $HOME/Dropbox/Dotfiles/config/git.conf $HOME/.config/git/config
ln -sf $HOME/Dropbox/Dotfiles/config/vifmrc $HOME/.config/vifm/vifmrc
ln -sf $HOME/Dropbox/Dotfiles/config/zathurarc $HOME/.config/zathura/zathurarc
ln -sf $HOME/Dropbox/Dotfiles/config/xmonad.hs $HOME/.config/xmonad/xmonad.hs
ln -sf $HOME/Dropbox/Dotfiles/config/xmobarrc $HOME/.config/xmonad/xmobarrc
ln -sf $HOME/Dropbox/Dotfiles/config/mimeapps.list $HOME/.config/mimeapps.list
ln -sf $HOME/Dropbox/Dotfiles/config/qutebrowser/config.py $HOME/.config/qutebrowser/config.py
ln -sf $HOME/Dropbox/Dotfiles/config/qutebrowser/quickmarks $HOME/.config/qutebrowser/quickmarks
ln -sf $HOME/Dropbox/Dotfiles/config/qutebrowser/bookmarks/urls $HOME/.config/qutebrowser/bookmarks/urls
ln -sf $HOME/Dropbox/Dotfiles/config/qutebrowser/scripts/cssGithub.js $HOME/.config/qutebrowser/greasemonkey/cssGithub.js
ln -sf $HOME/Dropbox/Dotfiles/config/qutebrowser/scripts/ytAdBlock.js.js $HOME/.config/qutebrowser/greasemonkey/ytAdBlock.js
ln -sf $HOME/Dropbox/Dotfiles/config/nvim/UltiSnips/ $HOME/.config/nvim/UltiSnips
ln -sf $HOME/Dropbox/Dotfiles/config/nvim/spell/en.utf-8.add $HOME/.config/nvim/spell/en.utf-8.add
ln -sf $HOME/Dropbox/Dotfiles/config/nvim/spell/en.utf-8.add.spl $HOME/.config/nvim/spell/en.utf-8.add.spl
ln -sf $HOME/Dropbox/Dotfiles/config/nvim/init.vim $HOME/.config/nvim/init.vim
ln -sf $HOME/Dropbox/Dotfiles/config/mpv/input.conf $HOME/.config/mpv/input.conf
ln -sf $HOME/Dropbox/Dotfiles/config/mpv/mpv.conf $HOME/.config/mpv/mpv.conf

# Packages
yay -Syu zathura zathura-pdf-poppler obsidian github-cli qutebrowser qutebrowser-profile-git dropbox spotify spicetify-cli
yay -Syu pipewire pipewire-pulse pipewire-jack pamixer bluez bluez-utils alsa-utils alsa-ucm-conf playerctl htop tree bc python python-pynvim
yay -Syu ttf-font-awesome ttf-anonymous-pro ttf-courier-prime ttf-cmu-serif ttf-mononoki-nerd noto-fonts adobe-source-han-sans-cn-fonts
yay -Syu pdftk scrot texlive biber npm ghostscript pdf2svg zip unzip gpicview arandr colorpicker

# Dmenu
cd $HOME/Dropbox/Dotfiles/dmenu
sudo make install

# Bluetooth
sudo systemctl enable bluetooth
sudo systemctl start --now bluetooth

# Nvim
sh -c 'curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Cpdf
mkdir -p $HOME/.local/bin
curl https://raw.githubusercontent.com/coherentgraphics/cpdf-binaries/master/Linux-Intel-64bit/cpdf -o $HOME/.local/bin/cpdf
chmod +x $HOME/.local/bin/cpdf

# Brightness
cd $HOME/Downloads
git clone https://github.com/Ventto/lux.git
cd lux
sudo make install
sudo lux
cd ..
rm -rf lux

# Github
gh auth login

# Spicetify
sudo mkdir -p /usr/share/spicetify-cli/Themes/Dribbblish/
sudo mkdir -p $HOME/.config/spicetify/Themes/Dribbblish/
sudo cp $HOME/Dropbox/Dotfiles/config/spicetify.ini $HOME/.config/spicetify/Themes/Dribbblish/color.ini
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R
spicetify config current_theme Dribbblish
spicetify config color_scheme rosepine
spicetify config experimental_features 0
spicetify backup apply
