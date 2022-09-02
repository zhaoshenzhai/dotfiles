syntax on                                                             " code highlighting
set number                                                            " line numbers
set relativenumber                                                    " relative line numbers
set tabstop=4                                                         " tab spaces
set softtabstop=4                                                     " multiple spaces become tab stops
set expandtab                                                         " converts tabs to spaces
set shiftwidth=4                                                      " width for auto indents
set fileencoding=utf-8                                                " written encoding
set encoding=utf-8                                                    " terminal encoding
set title                                                             " enable title
set titlestring=\ %-25.55t\ %a%r%m                                    " remove full path; name only
set incsearch                                                         " incremental search
set wildmode=longest,list                                             " get bash-like tab completions
set wrap                                                              " wraps text
set breakindent                                                       " wraps with correct indent
set linebreak                                                         " wraps at word boundaries
set clipboard+=unnamedplus                                            " uses system clipboard
set autoindent                                                        " indents a new line
set autochdir                                                         " change to current directory
set spell                                                             " spelling
set spelllang=en                                                      " spell language
set ignorecase                                                        " case insensitive when typing commands
set nofoldenable                                                      " no folding
set nohlsearch                                                        " no highlighting
set noswapfile                                                        " disable creating a swap file
set noshowmode                                                        " remove default mode display
set conceallevel=0                                                    " no conceal

call plug#begin('~/.config/nvim/plugged')
    " Core
    Plug 'SirVer/ultisnips'                                           " snippets
    Plug 'ncm2/ncm2'                                                  " code completion
    Plug 'roxma/nvim-yarp'                                            " framework required for ncm2
    Plug 'ncm2/ncm2-bufword'                                          " complete words in buffer
    Plug 'ncm2/ncm2-path'                                             " complete paths
    Plug 'kana/vim-textobj-user'                                      " custom textObjects

    " Development
    Plug 'lervag/vimtex'                                              " latex support
    Plug 'Quramy/tsuquyomi'                                           " typescript

    " Theme
    Plug 'joshdick/onedark.vim'                                       " onedark color scheme
    Plug 'itchyny/lightline.vim'                                      " lightline
    Plug 'inkarkat/vim-SyntaxRange'                                   " tex syntax in md
    Plug 'preservim/vim-markdown'                                     " syntax highlighting markdown
    Plug 'leafgarland/typescript-vim'                                 " syntax highlighting typescript
    Plug 'uiiaoo/java-syntax.vim'                                     " syntax highlighting java
call plug#end()

source ~/Dropbox/Dotfiles/config/nvim/config/theme.vim
source ~/Dropbox/Dotfiles/config/nvim/config/keyboardMovement.vim
source ~/Dropbox/Dotfiles/config/nvim/config/mappings.vim
source ~/Dropbox/Dotfiles/config/nvim/config/textObjects.vim
source ~/Dropbox/Dotfiles/config/nvim/config/compileAndRun.vim
source ~/Dropbox/Dotfiles/config/nvim/config/MathWiki.vim

source ~/Dropbox/Dotfiles/config/nvim/config/pluggins/markdown.vim
source ~/Dropbox/Dotfiles/config/nvim/config/pluggins/syntaxRange.vim
source ~/Dropbox/Dotfiles/config/nvim/config/pluggins/ultisnips.vim
source ~/Dropbox/Dotfiles/config/nvim/config/pluggins/vimtex.vim
source ~/Dropbox/Dotfiles/config/nvim/config/pluggins/ncm2.vim

autocmd VimEnter * :silent exec "!kill -s SIGWINCH $PPID"
