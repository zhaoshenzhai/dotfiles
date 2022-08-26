xnoremap <silent> im T$ot$
onoremap <silent> im :normal vim<CR>
xnoremap <silent> am F$of$
onoremap <silent> am :normal vam<CR>

call textobj#user#plugin('link', {
\   'squareBracket': {
\     'pattern': ['\[\[', '\]\]'],
\     'select-a': 'al',
\     'select-i': 'il'
\   }
\ })
