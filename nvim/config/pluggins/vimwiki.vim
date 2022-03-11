nmap <leader><space> <Plug>VimwikiNextLink
nmap <leader>. <Plug>VimwikiPrevLink
nmap <leader><enter> <Plug>VimwikiFollowLink
let g:vimwiki_conceallevel = 2
let g:vimwiki_table_mappings = 0
let g:vimwiki_list = [{'path': '~/MathWiki/',
                        \ 'syntax': 'markdown', 'ext': '.md'}]
autocmd filetype vimwiki :call SyntaxRange#Include('\$', '\$', 'tex')
autocmd filetype vimwiki :call SyntaxRange#Include('\$\$', '\$\$', 'tex')
autocmd filetype vimwiki :set spell
" NOTE: To fix autocomplete <CR> skipping to next line, go to
" ~/.config/nvim/plugged/vimwiki/ftplugin/vimwiki.vim line 486 and change the key binding
