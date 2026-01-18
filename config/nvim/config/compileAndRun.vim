let makeFile = findfile('makefile', '.'.';')
if !empty(makeFile)
    let directory = substitute(makeFile, '/makefile$', '', '')
    nnoremap <F1> :w <CR>:execute 'cd' fnameescape(directory)<CR>:execute '!make'<CR>
else
    autocmd filetype python nnoremap <F1> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compilePython.sh %<CR><CR>

    autocmd filetype c nnoremap <F2> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileC.sh -r %<CR><CR>
    autocmd filetype c nnoremap <F1> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileC.sh -c %<CR><CR>

    autocmd filetype java nnoremap <F2> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileJava.sh -r $PWD<CR><CR>
    autocmd filetype java nnoremap <F1> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileJava.sh -c $PWD<CR><CR>

    autocmd filetype tex nnoremap <F1> :w <CR>:VimtexCompile<CR>
    autocmd filetype tex nnoremap <F2> :w <CR>:VimtexView<CR>
    autocmd filetype tex nnoremap <F3> :w <CR>:VimtexView %:r_Solutions.pdf<CR>
    autocmd filetype tex nnoremap <F4> :w <CR>:!rm -f *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.run.xml *.synctex.gz *.synctex\(busy\) *.out *.xdv<CR><CR>
endif
