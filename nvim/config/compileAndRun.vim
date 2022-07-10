autocmd filetype c nnoremap <F5> :w <CR>:!gcc % -o %:r && ./%:r<CR>
autocmd filetype cs nnoremap <F5> :w <CR>:T ~/.config/scripts/compile/cSharpCompile.sh -p `dirname %`<CR>
autocmd filetype sh nnoremap <F5> :w <CR>:!alacritty -e `dirname %`/%<CR>
autocmd filetype tex nnoremap <F5> :w <CR>:VimtexCompile<CR>
autocmd filetype java nnoremap <F5> :w <CR>:T ~/.config/scripts/compile/javaCompile.sh -p `dirname %`<CR>
autocmd filetype python nnoremap <F5> :w <CR>:!python3 %<CR>
