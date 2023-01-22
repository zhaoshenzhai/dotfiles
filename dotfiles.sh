#!/bin/bash

YELLOW='\033[0;33m'
NC='\033[0m'

# Pacman colors
sudo sed -i 's/#Color/Color/g' /etc/pacman.conf

# Symlinks
rm $HOME/.config/alacritty/alacritty.yml
rm $HOME/.config/git/config
rm $HOME/.config/mpv/input.conf
rm $HOME/.config/mpv/mpv.conf
rm $HOME/.config/mpv/script-opts/reload.conf
rm $HOME/.config/mpv/script-opts/youtube-quality.conf
rm $HOME/.config/vifm/vifmrc
rm $HOME/.config/zathura/zathurarc
rm $HOME/.config/xmonad/xmonad.hs
rm $HOME/.config/xmonad/xmobarrc
rm $HOME/.config/mimeapps.list
rm $HOME/.config/qutebrowser/config.py
rm $HOME/.config/qutebrowser/quickmarks
rm $HOME/.config/qutebrowser/bookmarks/urls
rm $HOME/.config/nvim/UltiSnips
rm $HOME/.config/nvim/spell/en.utf-8.add
rm $HOME/.config/nvim/spell/en.utf-8.add.spl
rm $HOME/.config/nvim/init.vim
rm $HOME/.bashrc
rm $HOME/.bash_profile

mkdir $HOME/.config
cd $HOME/.config
mkdir alacritty git mpv mpv/script-opts vifm zathura xmonad qutebrowser nvim nvim/spell
cd ..

ln -s $HOME/Dropbox/Dotfiles/config/alacritty.yml $HOME/.config/alacritty/alacritty.yml
ln -s $HOME/Dropbox/Dotfiles/config/git.conf $HOME/.config/git/config
ln -s $HOME/Dropbox/Dotfiles/config/mpv/input.conf $HOME/.config/mpv/input.conf
ln -s $HOME/Dropbox/Dotfiles/config/mpv/mpv.conf $HOME/.config/mpv/mpv.conf
ln -s $HOME/Dropbox/Dotfiles/config/mpv/script-opts/reload.conf $HOME/.config/mpv/script-opts/reload.conf
ln -s $HOME/Dropbox/Dotfiles/config/mpv/script-opts/youtube-quality.conf $HOME/.config/mpv/script-opts/youtube-quality.conf
ln -s $HOME/Dropbox/Dotfiles/config/vifmrc $HOME/.config/vifm/vifmrc
ln -s $HOME/Dropbox/Dotfiles/config/zathurarc $HOME/.config/zathura/zathurarc
ln -s $HOME/Dropbox/Dotfiles/config/xmonad.hs $HOME/.config/xmonad/xmonad.hs
ln -s $HOME/Dropbox/Dotfiles/config/xmobarrc $HOME/.config/xmonad/xmobarrc
ln -s $HOME/Dropbox/Dotfiles/config/mimeapps.list $HOME/.config/mimeapps.list
ln -s $HOME/Dropbox/Dotfiles/config/qutebrowser/config.py $HOME/.config/qutebrowser/config.py
ln -s $HOME/Dropbox/Dotfiles/config/qutebrowser/quickmarks $HOME/.config/qutebrowser/quickmarks
ln -s $HOME/Dropbox/Dotfiles/config/qutebrowser/bookmarks/urls $HOME/.config/qutebrowser/bookmarks/urls
ln -s $HOME/Dropbox/Dotfiles/config/nvim/UltiSnips/ $HOME/.config/nvim/UltiSnips
ln -s $HOME/Dropbox/Dotfiles/config/nvim/spell/en.utf-8.add $HOME/.config/nvim/spell/en.utf-8.add
ln -s $HOME/Dropbox/Dotfiles/config/nvim/spell/en.utf-8.add.spl $HOME/.config/nvim/spell/en.utf-8.add.spl
ln -s $HOME/Dropbox/Dotfiles/config/nvim/init.vim $HOME/.config/nvim/init.vim
ln -s $HOME/Dropbox/Dotfiles/config/.bashrc $HOME/.bashrc
ln -s $HOME/Dropbox/Dotfiles/config/.bash_profile $HOME/.bash_profile

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

# Dmenu
cd $HOME/Dropbox/Dotfiles/dmenu
sudo make install

# Nvim
sh -c 'curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Bluetooth
sudo systemctl enable bluetooth
sudo systemctl start --now bluetooth

# Clone repos
cd $HOME/Dropbox
git clone https://github.com/zhaoshenzhai/MathWiki.git
git clone https://github.com/zhaoshenzhai/MathLinks.git
mkdir $HOME/Downloads
cd $HOME/Downloads
git clone https://aur.archlinux.org/yay-git
git clone https://github.com/Ventto/lux.git
git clone https://github.com/4e6/mpv-reload
git clone https://github.com/jgreco/mpv-youtube-quality

# Yay
cd yay-git
makepkg -si
cd ..
rm -rf yay-git

# Brightness
cd lux
sudo make install
sudo lux
cd ..
rm -rf lux

# Mpv
mkdir -p $HOME/.config/mpv/scripts
mv mpv-reload/reload.lua $HOME/.config/mpv/scripts/reload.lua
mv mpv-youtube-quality/youtube-quality.lua $HOME/.config/mpv/scripts/youtube-quality.lua
rm -rf mpv-reload mpv-youtube-quality

#Qutebrowser
mkdir -p $HOME/.config/qutebrowser/greasemonkey
curl https://greasyfork.org/scripts/436115-return-youtube-dislike/code/Return%20YouTube%20Dislike.user.js -o $HOME/.config/qutebrowser/greasemonkey/return-youtube-dislike.js
