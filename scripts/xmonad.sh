#!/bin/bash

sudo ghc --make $DOTFILES_DIR/config/xmonad.hs -i -ilib -fforce-recomp -main-is main -dynamic -v0 -outputdir /home/zhao/.config/xmonad/build-x86_64-linux -o /home/zhao/.config/xmonad/xmonad-x86_64-linux
