{ pkgs, ... }: {
    programs.vifm = {
        enable = true;

        extraConfig = ''
            set vicmd=nvim
            set syscalls
            set trash
            set history=100
            set nofollowlinks
            set sortnumbers
            set undolevels=100
            set nohlsearch
            set incsearch
            set scrolloff=4
            set dotfiles
            set ignorecase
            set statusline=" "

            mark h ~/ iCloud
            mark n ~/iCloud/Dotfiles modules
            mark d ~/iCloud/Documents
            mark p ~/iCloud/Projects _cv
            mark w ~/iCloud/Projects/_web index.html
            mark u ~/iCloud/University/Courses MATH565_Functional_Analysis_AUDIT

            set viewcolumns=-{name}..,6{size},12{mtime}

            map f '
            nnoremap l :file<cr><cr>
            nnoremap <C-c> :!pdfcp *.pdf >/dev/null 2>&1 &
            nnoremap <C-t> :!alacritty --working-directory %d &<cr>
            nnoremap <C-s> :!alacritty --title vifm-float --option "window.dimensions={columns=100,lines=35}" --option "window.position={x=525,y=250}" --working-directory %d &<cr>
            
            filetype *.pdf zathura %c >/dev/null 2>&1 &
            filetype *.jpg,*.jpeg,*.png,*.gif open %c &

            highlight clear
            highlight Border	 cterm=none	         ctermfg=035     ctermbg=default
            highlight TopLine	 cterm=none	         ctermfg=002     ctermbg=default
            highlight TopLineSel cterm=bold          ctermfg=002     ctermbg=default
            highlight Win        cterm=none	         ctermfg=250     ctermbg=default
            highlight Directory	 cterm=bold	         ctermfg=004     ctermbg=default
            highlight CurrLine   cterm=bold,inverse	 ctermfg=default ctermbg=default
            highlight OtherLine  cterm=bold	         ctermfg=default ctermbg=default
            highlight Selected   cterm=none	         ctermfg=003     ctermbg=008
            highlight JobLine    cterm=bold	         ctermfg=250     ctermbg=008
            highlight StatusLine cterm=none          ctermfg=250     ctermbg=default
            highlight ErrorMsg   cterm=bold	         ctermfg=001     ctermbg=default
            highlight WildMenu   cterm=bold	         ctermfg=015     ctermbg=250
            highlight CmdLine    cterm=none	         ctermfg=007     ctermbg=default
            highlight Executable cterm=bold	         ctermfg=002     ctermbg=default
            highlight Link       cterm=bold	         ctermfg=006     ctermbg=default
            highlight BrokenLink cterm=bold	         ctermfg=001     ctermbg=default
            highlight Device     cterm=bold,standout ctermfg=000     ctermbg=011
            highlight Fifo       cterm=none	         ctermfg=003     ctermbg=default
            highlight Socket     cterm=bold	         ctermfg=005     ctermbg=default
        '';
    };
}
