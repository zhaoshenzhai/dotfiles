autocmd filetype java set spell!

if $PWD == "/home/zhao/Dropbox/Others/Reminders"
    set spell!
    let g:vim_markdown_math = 1
    echo "hi"
endif

if $PWD == "/home/zhao/Dropbox/MathWiki/Notes"
    autocmd filetype markdown nnoremap <F6> :w <CR>:!$MATHWIKI_DIR/.scripts/newTikZ.sh<CR>i![[Images/<C-r>=system('$MATHWIKI_DIR/.scripts/getCurrentImage.sh')<CR>/image.svg]]<esc>I<backspace><esc>
    autocmd filetype markdown set syntax=tex

    let @a="?equation\<CR>dd/equation\<CR>dd?aligned\<CR>/e\<CR>xxI$$\<Esc>/aligned\<CR>/e\<CR>xxA$$\<Esc>v?align\<CR>n</align\<CR>kA\\qedin\<Esc>"
    let @b="/\\\\r)\<CR>xx?\\\\l(\<CR>lr,/)\<CR>"
endif

if $PWD == "/home/zhao/Dropbox/MathWiki/Images"
    autocmd filetype tex nnoremap <F6> :w <CR>:!pdflatex -shell-escape image.tex && pdfcrop image.pdf image.pdf && pdf2svg image.pdf image.svg<CR>
endif
