let g:tex_flavor='latex'
let g:vimtex_view_method='zathura'
let g:vimtex_mappings_enabled='false'
let g:vimtex_syntax_conceal_disable='1'
let g:vimtex_quickfix_ignore_filters=[
    \'Underfull \\hbox (badness [0-9]*) in paragraph at lines',
    \'Overfull \\hbox ([0-9]*.[0-9]*pt too wide) in paragraph at lines',
    \'Underfull \\hbox (badness [0-9]*) in ',
    \'Underfull \\vbox (badness [0-9]*) detected at line ',
    \'Overfull \\hbox ([0-9]*.[0-9]*pt too wide) in ',
    \'Package hyperref Warning: Token not allowed in a PDF string',
    \'Package typearea Warning: Bad type area settings!',
    \'LaTeX Warning: Label(s) may have changed. Rerun to get cross-references right.',
    \'Dimension too large.',
    \'LaTeX Warning\: Marginpar on page * moved. ',
    \'I found no \\bibdata command'
    \]
