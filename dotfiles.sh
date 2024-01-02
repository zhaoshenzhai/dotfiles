#!/bin/bash

# Pacman colors
sudo sed -i 's/#Color/Color/g' /etc/pacman.conf

# Symlinks
rm $HOME/.config/alacritty/alacritty.yml
rm $HOME/.config/git/config
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

mkdir -p $HOME/.config
cd $HOME/.config
mkdir -p alacritty git vifm zathura xmonad qutebrowser/greasemonkey nvim/spell
cd ..

ln -s $HOME/Dropbox/Dotfiles/config/alacritty.yml $HOME/.config/alacritty/alacritty.yml
ln -s $HOME/Dropbox/Dotfiles/config/git.conf $HOME/.config/git/config
ln -s $HOME/Dropbox/Dotfiles/config/vifmrc $HOME/.config/vifm/vifmrc
ln -s $HOME/Dropbox/Dotfiles/config/zathurarc $HOME/.config/zathura/zathurarc
ln -s $HOME/Dropbox/Dotfiles/config/xmonad.hs $HOME/.config/xmonad/xmonad.hs
ln -s $HOME/Dropbox/Dotfiles/config/xmobarrc $HOME/.config/xmonad/xmobarrc
ln -s $HOME/Dropbox/Dotfiles/config/mimeapps.list $HOME/.config/mimeapps.list
ln -s $HOME/Dropbox/Dotfiles/config/qutebrowser/config.py $HOME/.config/qutebrowser/config.py
ln -s $HOME/Dropbox/Dotfiles/config/qutebrowser/quickmarks $HOME/.config/qutebrowser/quickmarks
ln -s $HOME/Dropbox/Dotfiles/config/qutebrowser/bookmarks/urls $HOME/.config/qutebrowser/bookmarks/urls
ln -s $HOME/Dropbox/Dotfiles/config/qutebrowser/scripts/cssGithub.js $HOME/.config/qutebrowser/greasemonkey/cssGithub.js
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

# Git
git config --global credential.helper store

# Clone repos
cd $HOME/Dropbox
git clone https://github.com/zhaoshenzhai/MathWiki.git

mkdir $HOME/Dropbox/Projects
cd $HOME/Dropbox/Projects
git clone https://github.com/zhaoshenzhai/MathLinks.git

mkdir $HOME/Dropbox/University
cd $HOME/Dropbox/University
git clone https://github.com/zhaoshenzhai/courses.git
mv courses Courses

mkdir $HOME/Downloads
cd $HOME/Downloads
git clone https://aur.archlinux.org/yay-git
git clone https://github.com/Ventto/lux.git

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

# Qutebrowser
mkdir -p $HOME/.config/qutebrowser/greasemonkey
curl https://greasyfork.org/scripts/436115-return-youtube-dislike/code/Return%20YouTube%20Dislike.user.js -o $HOME/.config/qutebrowser/greasemonkey/return-youtube-dislike.js

# Dropbox
gitRepos=$(find /home/zhao -type d -name .git)
while IFS= read -r repo; do
    attr -s com.dropbox.ignored -V 1 $repo
done <<< "$gitRepos"

# Cpdf
curl https://raw.githubusercontent.com/coherentgraphics/cpdf-binaries/master/Linux-Intel-64bit/cpdf -o $HOME/.local/bin/cpdf
chmod +x $HOME/.local/bin/cpdf

# Spicetify
mkdir -p /usr/share/spicetify-cli/Themes/Dribbblish/
sudo cp $HOME/Dropbox/Dotfiles/config/spicetify.ini /usr/share/spicetify-cli/Themes/Dribbblish/color.ini
spicetify config current_theme Dribbblish
spicetify config color_scheme rosepine
spicetify config experimental_features 0
spicetify backup apply
