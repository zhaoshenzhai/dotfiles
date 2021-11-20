" Settings
syntax on                                                               " code highlighting 
set number                                                              " line numbers
set hlsearch                                                            " highlight search
set incsearch                                                           " incremental search
set tabstop=4                                                           " tab spaces
set softtabstop=4                                                       " multiple spaces become tab stops
set expandtab                                                           " converts tabs to spaces
set shiftwidth=4                                                        " width for auto indents
set autoindent                                                          " indents a new line    
set wildmode=longest,list                                               " get bash-like tab completions
set mouse=a                                                             " enable mouse clicks
set noswapfile                                                          " disable creating a swap file 
set wrap                                                                " wraps text
set breakindent                                                         " wraps with correct indent
set linebreak                                                           " wraps at word boundaries
set updatetime=100                                                      " sets update time for git-gutter
set clipboard=unnamedplus                                               " uses system clipboard
set ignorecase                                                          " case insensitive when typing commands
set noshowmode                                                          " remove default mode display
set fileencoding=utf-8                                                  " written encoding
set encoding=utf-8                                                      " terminal encoding

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
    Plug 'artur-shaik/vim-javacomplete2', {'for': ['java', 'jsp']}      " framework required for java completion
    Plug 'uiiaoo/java-syntax.vim'                                       " java code highlighting
    Plug 'numirias/semshi', { 'do': ':UpdateRemotePlugins' }            " python code highlighting
    Plug 'fisadev/vim-isort'                                            " python sort imports
    Plug 'joshdick/onedark.vim'                                         " onedark color scheme
    Plug 'itchyny/lightline.vim'                                        " lightline
    Plug 'mhinz/vim-startify'                                           " start screen
call plug#end()

" Color scheme
colorscheme onedark
highlight Normal ctermbg=NONE guibg=NONE
highlight NonText ctermbg=NONE guibg=NONE
highlight LineNr ctermbg=NONE guibg=NONE
highlight SignColumn ctermbg=NONE guibg=NONE
highlight EndOfBuffer ctermbg=NONE guibg=NONE

" ncm2
autocmd BufEnter * call ncm2#enable_for_buffer()
set completeopt=noinsert,menuone,noselect
let g:python3_host_prog='/usr/bin/python3'

" NerdTree
map <silent> <leader>n :NERDTreeFocus<CR>
let NERDTreeIgnore=['\.pyc$']

"Isort
let g:vim_isort_map = '<leader>i'

" VimTex
let g:tex_flavor='latex'
let g:vimtex_compiler_progname = 'nvr'
let g:vimtex_view_method='zathura'
let g:vimtex_quickfix_ignore_filters=[
    \'Underfull \\hbox (badness [0-9]*) in paragraph at lines',
    \'Overfull \\hbox ([0-9]*.[0-9]*pt too wide) in paragraph at lines',
    \'Underfull \\hbox (badness [0-9]*) in ',
    \'Overfull \\hbox ([0-9]*.[0-9]*pt too wide) in ',
    \'Package hyperref Warning: Token not allowed in a PDF string',
    \'Package typearea Warning: Bad type area settings!',
    \'LaTeX Warning: Label(s) may have changed. Rerun to get cross-references right.',
    \'Dimension too large.',
    \]
let g:UltiSnipsExpandTrigger="<s-tab>"                                            
let g:UltiSnipsJumpForwardTrigger="<tab>"
map <leader>f <leader>lv

" Lightline
let g:lightline = {
    \ 'colorscheme': 'wombat',
    \ 'active': {
    \   'right': [ [ 'lineinfo' ],
    \              [ 'percent' ]]
    \ },
    \ }

" Spell check
setlocal nospell
set spelllang=en
nnoremap <silent> <leader>s :set spell!<cr>
inoremap <silent> <leader>s <C-O>:set spell!<cr>
inoremap <leader>c <c-g>u<Esc>[s1z=`]a<c-g>u

" Switch tabs
map <F2> :tabp<CR>
map <F3> :tabn<CR>

" Search
nnoremap <CR> :noh <CR>

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
autocmd filetype cs nnoremap <F5> :w <CR>:T cSharpCompile.sh -p `dirname %`<CR>
autocmd filetype java nnoremap <F5> :w <CR>:T javaCompile.sh -p `dirname %`<CR>
autocmd filetype python nnoremap <F5> :w <CR>:!python3 %<CR>
