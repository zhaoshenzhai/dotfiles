autocmd filetype java set spell!

if $PWD == "/home/zhao/Dropbox/Others/Reminders"
    set spell!
    let g:vim_markdown_math = 1
endif

if $PWD == "/home/zhao/Dropbox/MathWiki/Notes"
    autocmd filetype markdown nnoremap <F6> :w <CR>:!$MATHWIKI_DIR/.scripts/newTikZ.sh<CR>i![[Images/<C-r>=system('$MATHWIKI_DIR/.scripts/getCurrentImage.sh')<CR>/image.svg]]<esc>I<backspace><esc>

    let @a="?equation\<CR>dd/equation\<CR>dd?aligned\<CR>/e\<CR>xxI$$\<Esc>/aligned\<CR>/e\<CR>xxA$$\<Esc>v?align\<CR>n</align\<CR>kA\\qedin\<Esc>"
    let @g="?equation\<CR>dd/equation\<CR>dd?gathered\<CR>/e\<CR>xxI$$\<Esc>/gathered\<CR>/e\<CR>xxA$$\<Esc>v?gather\<CR>n</gather\<CR>kA\\qedin\<Esc>"
    let @b="/\\\\r)\<CR>xx?\\\\l(\<CR>lr,/)\<CR>"

    autocmd filetype markdown set syntax=tex
    let g:vim_markdown_fenced_languages = ["ad-Definition=tex", "ad-Theorem=tex", "ad-Proposition=tex", "ad-Example=tex", "ad-Axiom=tex"]
endif

if $PWD == "/home/zhao/Dropbox/MathWiki/Images"
    autocmd filetype tex nnoremap <F6> :w <CR>:!pdflatex -shell-escape image.tex && pdfcrop image.pdf image.pdf && pdf2svg image.pdf image.svg<CR>
endif
