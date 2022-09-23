autocmd filetype c nnoremap <F5> :w <CR>:!alacritty -e $DOTFILES_DIR/scripts/compileC.sh %<CR><CR>
autocmd filetype cs nnoremap <F5> :w <CR>:!alacritty -e $DOTFILES_DIR/scripts/compileCSharp.sh $PWD<CR><CR>
autocmd filetype python nnoremap <F5> :w <CR>:!python3 %<CR><CR>
autocmd filetype typescript nnoremap <F5> :w <CR>:!alacritty -e $DOTFILES_DIR/scripts/compileTypeScript.sh $PWD<CR><CR>

autocmd filetype java nnoremap <F4> :w <CR>:!alacritty -e $DOTFILES_DIR/scripts/compileJava.sh -r $PWD<CR><CR>
autocmd filetype java nnoremap <F5> :w <CR>:!alacritty -e $DOTFILES_DIR/scripts/compileJava.sh -c $PWD<CR><CR>

autocmd filetype tex nnoremap <F4> :w <CR>:VimtexView<CR>
autocmd filetype tex nnoremap <F5> :w <CR>:VimtexCompile<CR>
