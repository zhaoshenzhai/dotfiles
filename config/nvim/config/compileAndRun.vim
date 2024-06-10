let makeFile = findfile('makefile', '.'.';')
if !empty(makeFile)
    let directory = substitute(makeFile, '/makefile$', '', '')
    nnoremap <F5> :w <CR>:execute 'cd' fnameescape(directory)<CR>:execute '!make'<CR>
else
    autocmd filetype python nnoremap <F5> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compilePython.sh %<CR><CR>

    autocmd filetype c nnoremap <F4> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileC.sh -r %<CR><CR>
    autocmd filetype c nnoremap <F5> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileC.sh -c %<CR><CR>

    autocmd filetype java nnoremap <F4> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileJava.sh -r $PWD<CR><CR>
    autocmd filetype java nnoremap <F5> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileJava.sh -c $PWD<CR><CR>

    autocmd filetype tex nnoremap <F4> :w <CR>:VimtexView<CR>
    autocmd filetype tex nnoremap <F5> :w <CR>:VimtexCompile<CR>
endif
