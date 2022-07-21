autocmd filetype cs nnoremap <F5> :w <CR>:T ~/.config/scripts/compileCSharp.sh -p `dirname %`<CR>
autocmd filetype tex nnoremap <F5> :w <CR>:VimtexCompile<CR>
autocmd filetype java nnoremap <F5> :w <CR>:T ~/.config/scripts/compileJava.sh -p `dirname %`<CR>
autocmd filetype python nnoremap <F5> :w <CR>:!python3 %<CR>

autocmd filetype c nnoremap <F5> :w <CR>:!alacritty -e ~/.config/scripts/compileC.sh %<CR><CR>
autocmd filetype typescript nnoremap <F5> :w <CR>:!alacritty -e ~/.config/scripts/compileTypeScript.sh %<CR><CR>
