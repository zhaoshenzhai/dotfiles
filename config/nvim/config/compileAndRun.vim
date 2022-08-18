autocmd filetype c nnoremap <F5> :w <CR>:!alacritty -e $DOTFILES_DIR/scripts/compileC.sh %<CR><CR>
autocmd filetype tex nnoremap <F5> :w <CR>:VimtexCompile<CR>
autocmd filetype typescript nnoremap <F5> :w <CR>:!alacritty -e $DOTFILES_DIR/scripts/compileTypeScript.sh %<CR><CR>

" Need to rewrite those
autocmd filetype cs nnoremap <F5> :w <CR>:T $DOTFILES_DIR/scripts/compileCSharp.sh -p `dirname %`<CR>
autocmd filetype java nnoremap <F5> :w <CR>:T $DOTFILES_DIR/scripts/compileJava.sh -p `dirname %`<CR>
autocmd filetype python nnoremap <F5> :w <CR>:!python3 %<CR>
