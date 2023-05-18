autocmd filetype markdown nnoremap <F6> :w <CR>:!$MATHWIKI_DIR/.scripts/newTikZ.sh<CR>i[[Images/<C-r>=system('$MATHWIKI_DIR/.scripts/getCurrentImage.sh')<CR>/image.svg]]<esc>I<backspace><esc>
autocmd filetype tex nnoremap <F6> :w <CR>:!pdflatex -shell-escape image.tex && pdfcrop image.pdf image.pdf && pdf2svg image.pdf image.svg<CR>

let @a="?equation\<CR>dd/equation\<CR>dd?aligned\<CR>/e\<CR>xxI$$\<Esc>/aligned\<CR>/e\<CR>xxA$$\<Esc>v?align\<CR>n</align\<CR>kA\\qedin\<Esc>"
let @s="v/md\<CR>:s/\\%V\\s/%20/g\<CR>"
