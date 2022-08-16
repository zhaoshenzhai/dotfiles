autocmd BufEnter * call ncm2#enable_for_buffer()
set completeopt=noinsert,menuone,noselect
let g:python3_host_prog='/usr/bin/python3'

augroup NCM2
    autocmd!
    autocmd Filetype tex call ncm2#register_source({
        \ 'name': 'vimtex',
        \ 'priority': 8,
        \ 'scope': ['tex'],
        \ 'mark': 'tex',
        \ 'word_pattern': '\w+',
        \ 'complete_pattern': g:vimtex#re#ncm2,
        \ 'on_complete': ['ncm2#on_complete#omni', 'vimtex#complete#omnifunc'],
        \ })
augroup END
