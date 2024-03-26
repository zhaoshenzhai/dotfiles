#!/bin/bash

# Pacman colors
sudo sed -i 's/#Color/Color/g' /etc/pacman.conf

# Symlinks
rm $HOME/.config/kitty/kitty.yml
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
rm $HOME/.config/mpv/input.conf
rm $HOME/.config/mpv/mpv.conf
rm $HOME/.config/mpv/script-opts/reload.conf
rm $HOME/.config/mpv/script-opts/youtube-quality.conf
rm $HOME/.bashrc
rm $HOME/.bash_profile

mkdir -p $HOME/.config
cd $HOME/.config
mkdir -p kitty git vifm zathura xmonad qutebrowser/greasemonkey qutebrowser/bookmarks nvim/spell mpv/script-opts
cd ..

ln -s $HOME/Dropbox/Dotfiles/config/kitty.yml $HOME/.config/kitty/kitty.yml
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
ln -s $HOME/Dropbox/Dotfiles/config/mpv/input.conf $HOME/.config/mpv/input.conf
ln -s $HOME/Dropbox/Dotfiles/config/mpv/mpv.conf $HOME/.config/mpv/mpv.conf
ln -s $HOME/Dropbox/Dotfiles/config/mpv/script-opts/reload.conf $HOME/.config/mpv/script-opts/reload.conf
ln -s $HOME/Dropbox/Dotfiles/config/mpv/script-opts/youtube-quality.conf $HOME/.config/mpv/script-opts/youtube-quality.conf
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

# Downloads
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

# Packages
yay -Syu xorg xorg-xinit xmonad xmonad-contrib xmobar xclip
yay -Syu dmenu kitty vifm nitrogen neofetch zathura zathura-pdf-mupdf obsidian qutebrowser qutebrowser-profile-git dropbox spotify spicetify-cli
yay -Syu pipewire pipewire-pulse pipewire-jack pamixer playerctl bluez bluez-utils alsa-utils sof-firmware alsa-ucm-conf pavucontrol ffmpeg-compat-57
yay -Syu ttf-font-awesome ttf-anonymous-pro adobe-source-han-sans-cn-fonts ttf-courier-prime ttf-cmu-serif ttf-mononoki-nerd noto-fonts
yay -Syu htop tree bc scrot texlive biber python npm ghostscript pdf2svg zip unzip gpicview arandr colorpicker python-pynvim python-colorama python-click

# Dropbox
gitRepos=$(find /home/zhao -type d -name .git)
while IFS= read -r repo; do
    attr -s com.dropbox.ignored -V 1 $repo
done <<< "$gitRepos"

# Cpdf
curl https://raw.githubusercontent.com/coherentgraphics/cpdf-binaries/master/Linux-Intel-64bit/cpdf -o $HOME/.local/bin/cpdf
chmod +x $HOME/.local/bin/cpdf

# Mpv
cd $HOME/Downloads
mkdir -p $HOME/.config/mpv/scripts
git clone https://github.com/4e6/mpv-reload
git clone https://github.com/jgreco/mpv-youtube-quality
git clone https://github.com/CogentRedTester/mpv-scripts.git
mv mpv-reload/reload.lua $HOME/.config/mpv/scripts/reload.lua
mv mpv-youtube-quality/youtube-quality.lua $HOME/.config/mpv/scripts/youtube-quality.lua
mv mpv-scripts/cycle-commands.lua $HOME/.config/mpv/scripts/cycle-commands.lua
rm -rf mpv-reload mpv-youtube-quality mpv-scripts

# Spicetify
mkdir -p /usr/share/spicetify-cli/Themes/Dribbblish/
sudo cp $HOME/Dropbox/Dotfiles/config/spicetify.ini /usr/share/spicetify-cli/Themes/Dribbblish/color.ini
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R
spicetify config current_theme Dribbblish
spicetify config color_scheme rosepine
spicetify config experimental_features 0
spicetify backup apply
