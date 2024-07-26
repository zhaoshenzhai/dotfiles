autocmd BufEnter * call ncm2#enable_for_buffer()
set completeopt=noinsert,menuone,noselect
set noshowmode
let g:python3_host_prog='/usr/bin/python3'

augroup NCM2
    autocmd!
    autocmd Filetype tex call ncm2#register_source({
        \ 'name': 'vimtex',
        \ 'priority': 1,
        \ 'scope': ['tex'],
        \ 'matcher': {'name': 'combine',
        \   'matchers': [
        \       {'name': 'abbrfuzzy', 'key': 'menu'},
        \       {'name': 'prefix', 'key': 'word'},
        \   ]},
        \ 'mark': 'tex',
        \ 'word_pattern': '\w+',
        \ 'complete_pattern': g:vimtex#re#ncm2,
        \ 'on_complete': ['ncm2#on_complete#omni', 'vimtex#complete#omnifunc'],
        \ })
augroup END
