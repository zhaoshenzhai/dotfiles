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
set conceallevel=0                                                      " conceal
set autochdir                                                           " change to current directory
set spell                                                               " spelling
set spelllang=en                                                        " spell language

call plug#begin('~/.config/nvim/plugged')
    " Core
    Plug 'SirVer/ultisnips'                                             " snippets
    Plug 'ncm2/ncm2'                                                    " code completion
    Plug 'roxma/nvim-yarp'                                              " framework required for ncm2
    Plug 'ncm2/ncm2-bufword'                                            " complete words in buffer
    Plug 'ncm2/ncm2-path'                                               " complete paths

    " Development
    Plug 'lervag/vimtex'                                                " latex support

    " Theme
    Plug 'joshdick/onedark.vim'                                         " onedark color scheme
    Plug 'itchyny/lightline.vim'                                        " lightline
    Plug 'inkarkat/vim-SyntaxRange'                                     " tex syntax in md
    Plug 'preservim/vim-markdown'                                       " syntax highlighting markdown
    Plug 'leafgarland/typescript-vim'                                   " syntax highlighting typescript
call plug#end()

let mapleader = "`"

source ~/.config/nvim/config/theme.vim
source ~/.config/nvim/config/keyboardMovement.vim
source ~/.config/nvim/config/mappings.vim
source ~/.config/nvim/config/textObjects.vim
source ~/.config/nvim/config/compileAndRun.vim
source ~/.config/nvim/config/MathWiki.vim

source ~/.config/nvim/config/pluggins/syntaxRange.vim
source ~/.config/nvim/config/pluggins/ultisnips.vim
source ~/.config/nvim/config/pluggins/vimtex.vim
source ~/.config/nvim/config/pluggins/ncm2.vim

autocmd VimEnter * :silent exec "!kill -s SIGWINCH $PPID"
