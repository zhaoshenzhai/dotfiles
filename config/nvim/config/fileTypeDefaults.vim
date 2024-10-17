autocmd filetype java setlocal spell!

if $PWD == "/home/zhao/Dropbox/Others/Reminders"
    set spell!
    let g:vim_markdown_math = 1
endif

if ($PWD == "/home/zhao/Dropbox/MathWiki/Notes")
    autocmd filetype markdown nnoremap <F6> :w <CR>:!$MATHWIKI_DIR/.scripts/updateImages.sh -n "%"<CR><esc>
    autocmd filetype markdown setlocal syntax=tex
    autocmd filetype markdown match Underlined "\vdisplay\=\".{-}\""
    autocmd filetype markdown set conceallevel=2

    autocmd filetype markdown syntax match Normal "\v\&emsp;\&emsp;" conceal
    autocmd filetype markdown syntax match Normal "\v\{\{\<\slink\sfile\=\".{-}\.md" conceal
    autocmd filetype markdown syntax match Normal "\v\"\stype\=\".{-}\""me=e-1 conceal
    autocmd filetype markdown syntax match Normal "\v\"\ssecID\=\".{-}\""me=e-1 conceal
    autocmd filetype markdown syntax match Normal "\v\"\ssecDisplay\=\".{-}\""me=e-1 conceal
    autocmd filetype markdown syntax match Normal "\v\"\sdisplay\=\"" conceal
    autocmd filetype markdown syntax match Normal "\v\"\smod\=\"dag" conceal cchar=†

    autocmd filetype markdown syntax match Normal "\v\{\{\<\senv\s" conceal
    autocmd filetype markdown syntax match Normal "\vtype\=\"" conceal
    autocmd filetype markdown syntax match Normal "\v\"\sname\=\"" conceal cchar=|
    autocmd filetype markdown syntax match Normal "\v\"\shide\=\"(\a)*" conceal
    autocmd filetype markdown syntax match Normal "\v\"\sid\=\".{-}\""me=e-1 conceal

    autocmd filetype markdown syntax match Normal "\v\{\{\<\s/env\s\>\}\}" conceal
    autocmd filetype markdown syntax match Normal "\v\"\s\>\}\}" conceal
    autocmd filetype markdown syntax match Normal "\v\<br\>" conceal
    autocmd filetype markdown syntax match Normal "\v\<div\s.{-}div\>" conceal
    autocmd filetype markdown syntax match Normal "\v\<span.{-}blacksquare.{-}span\>" conceal cchar=▢
    autocmd filetype markdown syntax match Normal "\v\<h.{-}\>" conceal
    autocmd filetype markdown syntax match Normal "\v\</h.\>" conceal
endif

if $PWD == "/home/zhao/Dropbox/MathWiki/Images"
    autocmd filetype tex nnoremap <F6> :w <CR>:!pdflatex -shell-escape image.tex && pdfcrop image.pdf image.pdf && pdf2svg image.pdf image.svg<CR>
endif
