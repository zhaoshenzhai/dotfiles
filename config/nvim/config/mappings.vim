" Search
nnoremap <C-f> :%s//gc<Left><Left><Left>
vnoremap <C-f> :s//gc<Left><Left><Left>

" Spell check
nnoremap <silent> <C-s> :set spell!<cr>
inoremap <silent> <C-c> <c-g>u<Esc>[s1z=`]a<c-g>u

" Wrap
nnoremap <silent> <C-w> :set wrap!<cr>
