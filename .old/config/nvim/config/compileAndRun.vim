let makeFile = findfile('makefile', '.'.';')
if !empty(makeFile)
    let directory = substitute(makeFile, '/makefile$', '', '')
    nnoremap <F1> :w <CR>:execute 'cd' fnameescape(directory)<CR>:execute '!make'<CR>
else
    autocmd filetype python nnoremap <buffer> <F1> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compilePython.sh %<CR><CR>

    autocmd filetype c nnoremap <buffer> <F2> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileC.sh -r %<CR><CR>
    autocmd filetype c nnoremap <buffer> <F1> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileC.sh -c %<CR><CR>

    autocmd filetype java nnoremap <buffer> <F2> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileJava.sh -r $PWD<CR><CR>
    autocmd filetype java nnoremap <buffer> <F1> :w <CR>:!kitty -e $DOTFILES_DIR/scripts/compileJava.sh -c $PWD<CR><CR>

    autocmd filetype tex nnoremap <buffer> <F1> :w <CR>:VimtexCompile<CR>
    autocmd filetype tex nnoremap <buffer> <F2> :w <CR>:VimtexView<CR>
    autocmd filetype tex nnoremap <buffer> <F3> :w <CR>:!rm -f *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.log *.run.xml *.synctex.gz *.synctex\(busy\) *.out *.xdv<CR><CR>
    autocmd filetype tex nnoremap <buffer> <F4> :w <CR>:silent !test -f %:r_Student.pdf && (wmctrl -a "%:t:r_Student.pdf" <Bar><Bar> zathura %:r_Student.pdf &)<CR><CR>
endif
