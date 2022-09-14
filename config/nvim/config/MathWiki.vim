autocmd filetype markdown nnoremap <F6> :w <CR>:!$MATHWIKI_DIR/.scripts/newTikZ.sh<CR>i<center><img src="app://local/<C-r>=strpart($MATHWIKI_DIR, 1, strlen($MATHWIKI_DIR)-1)<CR>/Images/<C-r>=system('$MATHWIKI_DIR/.scripts/getCurrentImage.sh')<CR>/image.svg"></center><esc>I<backspace><esc>
autocmd filetype tex nnoremap <F6> :w <CR>:!pdflatex -shell-escape image.tex && pdfcrop image.pdf image.pdf && pdf2svg image.pdf image.svg<CR>