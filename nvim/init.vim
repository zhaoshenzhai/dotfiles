" Settings
syntax on                                                               " code highlighting 
set number                                                              " line numbers
set nohlsearch                                                          " no highlighting
set incsearch                                                           " incremental search
set tabstop=4                                                           " tab spaces
set softtabstop=4                                                       " multiple spaces become tab stops
set expandtab                                                           " converts tabs to spaces
set shiftwidth=4                                                        " width for auto indents
set autoindent                                                          " indents a new line    
set wildmode=longest,list                                               " get bash-like tab completions
set noswapfile                                                          " disable creating a swap file 
set wrap                                                                " wraps text
set breakindent                                                         " wraps with correct indent
set linebreak                                                           " wraps at word boundaries
set clipboard+=unnamedplus                                              " uses system clipboard
set ignorecase                                                          " case insensitive when typing commands
set noshowmode                                                          " remove default mode display
set fileencoding=utf-8                                                  " written encoding
set encoding=utf-8                                                      " terminal encoding
set title                                                               " enable title
set titlestring=\ %-25.55t\ %a%r%m                                      " remove full path; name only
set relativenumber                                                      " relative line numbers
set nofoldenable                                                        " no folding
set conceallevel=2                                                      " conceal
set autochdir                                                           " change to current directory

" Pluggins
call plug#begin('~/.config/nvim/plugged')
    Plug 'tpope/vim-fugitive'                                           " allows git commands
    Plug 'preservim/nerdtree'                                           " side bar file tree
    Plug 'lervag/vimtex'                                                " latex support
    Plug 'SirVer/ultisnips'                                             " snippets to code much faster
    Plug 'kassio/neoterm'                                               " interactive shell
    Plug 'ctrlpvim/ctrlp.vim'                                           " fuzzy search
    Plug 'sbdchd/neoformat'                                             " formats code
    Plug 'easymotion/vim-easymotion'                                    " go to any word quickly
    Plug 'ncm2/ncm2'                                                    " code completion
    Plug 'roxma/nvim-yarp'                                              " framework required for ncm2
    Plug 'ncm2/ncm2-bufword'                                            " complete words in buffer
    Plug 'ncm2/ncm2-path'                                               " complete paths
    Plug 'ncm2/ncm2-jedi'                                               " python completion
    Plug 'ObserverOfTime/ncm2-jc2', {'for': ['java', 'jsp']}            " java completion
    Plug 'OmniSharp/omnisharp-vim'                                      " C# code completion
    Plug 'artur-shaik/vim-javacomplete2', {'for': ['java', 'jsp']}      " framework required for java completion
    Plug 'uiiaoo/java-syntax.vim'                                       " java code highlighting
    Plug 'numirias/semshi', { 'do': ':UpdateRemotePlugins' }            " python code highlighting
    Plug 'fisadev/vim-isort'                                            " python sort imports
    Plug 'joshdick/onedark.vim'                                         " onedark color scheme
    Plug 'itchyny/lightline.vim'                                        " lightline
    Plug 'mhinz/vim-startify'                                           " start screen
    Plug 'godlygeek/tabular'                                            " needed by markdown
    Plug 'plasticboy/vim-markdown'                                      " markdown syntax
    Plug 'vimwiki/vimwiki'                                              " wiki
    Plug 'inkarkat/vim-SyntaxRange'                                     " tex syntax in md
call plug#end()

" Color scheme
colorscheme onedark
highlight Normal ctermbg=NONE guibg=NONE
highlight NonText ctermbg=NONE guibg=NONE
highlight LineNr ctermbg=NONE guibg=NONE
highlight SignColumn ctermbg=NONE guibg=NONE
highlight EndOfBuffer ctermbg=NONE guibg=NONE
let g:loaded_matchparen=1

" Leader
let mapleader = "`"

" ncm2
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

" VimWiki
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
" ~/.config/nvim/plugged/vimwiki/ftplugin/vimwiki.vim line 486 and change the
" key binding
map <leader>p :grep -r "Status: \#In_Progress" ~/MathWiki<CR>:copen<CR><CR>

" NerdTree
map <silent> <Leader>n :NERDTreeToggle<CR>
map <silent> <Leader>m :NERDTreeToggle ~/MathWiki/<CR>j<CR>
let NERDTreeIgnore=['\.pyc$']

" Isort
let g:vim_isort_map = '<M-Space>i'

" Search
nnoremap S :%s//gc<Left><Left><Left>

" Ultisnips
let g:UltiSnipsExpandTrigger="<S-tab>"                                            
let g:UltiSnipsJumpForwardTrigger="<tab>"

" VimMarkdown
let g:vim_markdown_math = 1

" VimTex
let g:tex_flavor='latex'
let g:vimtex_compiler_progname = 'nvr'
let g:vimtex_view_method='zathura'
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
    \]
map <F4> :VimtexView<CR>

" Lightline
let g:lightline = {
    \ 'colorscheme': 'wombat',
    \ 'active': {
    \   'right': [ [ 'lineinfo' ],
    \              [ 'percent' ]]
    \ },
    \ }

" Spell check
setlocal spell
set spelllang=en
nnoremap <silent> <M-Space>s :set spell!<cr>
inoremap <silent> <M-Space>s <C-O>:set spell!<cr>
inoremap <M-Space>c <c-g>u<Esc>[s1z=`]a<c-g>u

" Switch tabs
map <F2> :tabp<CR>
map <F3> :tabn<CR>
map <leader>j <C-w>j
map <leader>k <C-w>k
map <M-Space>d <C-w>+
map <M-Space>u <C-w>-

" Scroll
function! ScreenMovement(movement)
   if &wrap
      return "g" . a:movement
   else
      return a:movement
   endif
endfunction
onoremap <silent> <expr> j ScreenMovement("j")
onoremap <silent> <expr> k ScreenMovement("k")
onoremap <silent> <expr> 0 ScreenMovement("0")
onoremap <silent> <expr> ^ ScreenMovement("^")
onoremap <silent> <expr> $ ScreenMovement("$")
nnoremap <silent> <expr> j ScreenMovement("j")
nnoremap <silent> <expr> k ScreenMovement("k")
nnoremap <silent> <expr> 0 ScreenMovement("0")
nnoremap <silent> <expr> ^ ScreenMovement("^")
nnoremap <silent> <expr> $ ScreenMovement("$")

" Compile and run programs
autocmd filetype c nnoremap <F5> :w <CR>:!gcc % -o %:r && ./%:r<CR>
autocmd filetype cs nnoremap <F5> :w <CR>:T ~/.config/scripts/Compile Programs/cSharpCompile.sh -p `dirname %`<CR>
autocmd filetype tex nnoremap <F5> :w <CR>:VimtexCompile<CR>
autocmd filetype java nnoremap <F5> :w <CR>:T ~/.config/scripts/Compile Programs/javaCompile.sh -p `dirname %`<CR>
autocmd filetype python nnoremap <F5> :w <CR>:!python3 %<CR>

autocmd filetype vimwiki nnoremap <F6> :w <CR>:!~/.config/scripts/MathWiki/newTikZ.sh<CR>i<center><img src="https://raw.githubusercontent.com/zhaoshenzhai/MathWiki/master/Images/<C-r>=system('date +%d-%m-%Y_%H%M')<CR>/image.svg"></center><esc>I<backspace><esc>
autocmd filetype tex nnoremap <F6> :w <CR>:!pdflatex -shell-escape image.tex && pdfcrop image.pdf image.pdf && pdf2svg image.pdf image.svg<CR>

" Fix resizing
autocmd VimEnter * :silent exec "!kill -s SIGWINCH $PPID"
