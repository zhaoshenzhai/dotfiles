autocmd filetype java setlocal spell!

if $PWD == "/home/zhao/Dropbox/Others/Reminders"
    set spell!
    let g:vim_markdown_math = 1
endif

if ($PWD == "/home/zhao/Dropbox/Projects/MathWiki/Notes")
    autocmd filetype markdown nnoremap <F6> :w <CR>:!$MATHWIKI_DIR/.scripts/updateImages.sh -n "%"<CR><esc>
    autocmd filetype markdown set filetype=md
    autocmd filetype markdown setlocal syntax=tex
endif

if $PWD == "/home/zhao/Dropbox/Projects/MathWiki/Images"
    autocmd filetype tex nnoremap <F6> :w <CR>:!pdflatex -shell-escape image.tex && pdfcrop image.pdf image.pdf && pdf2svg image.pdf image.svg<CR>
endif
