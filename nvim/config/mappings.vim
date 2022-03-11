" Search
nnoremap S :%s//gc<Left><Left><Left>

" Spell check
nnoremap <silent> <M-Space>s :set spell!<cr>
inoremap <silent> <M-Space>s <C-O>:set spell!<cr>
inoremap <silent> <M-Space>c <c-g>u<Esc>[s1z=`]a<c-g>u

" Switch tabs
map <silent> <F2> :tabp<CR>
map <silent> <F3> :tabn<CR>
