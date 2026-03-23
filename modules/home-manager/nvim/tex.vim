nnoremap <buffer> <C-1> :w <CR>:VimtexCompile<CR>
nnoremap <buffer> <C-2> :w <CR>:VimtexView<CR>:lua vim.fn.jobstart({ "open", "-a", "Skim" }, {detach=true})<CR><CR>
nnoremap <buffer> <C-3> :w <CR>:!rm -f *.aux(N) *.bbl(N) *.bcf(N) *bcf-SAVE-ERROR(N) *.blg(N) *.fdb_latexmk(N) *.fls(N) *.log(N) *.run.xml(N) *.synctex.gz(N) *.synctex\(busy\)(N)<CR><CR>
nnoremap <buffer> <C-4> :w <CR>:lua local f=vim.fn.expand('%:p:r')..'_Student.pdf'; if vim.fn.filereadable(f)==1 then vim.fn.jobstart({ "open", "-n", "-a", "Skim", f }, {detach=true}) end<CR><CR>

function! TexFold(lnum)
    let l:line = getline(a:lnum)

    if l:line =~# '^\s*\\begin{\(question\|exercise\)}'
        return '>1'
    elseif l:line =~# '^\s*\\end{solution}'
        return '<1'
    elseif l:line =~# '^\s*\\end{\(question\|exercise\)}'
        let l:next_lnum = nextnonblank(a:lnum + 1)
        if l:next_lnum > 0 && getline(l:next_lnum) =~# '^\s*\\begin{solution}'
            return '1'
        else
            return '<1'
        endif
    endif

    return '='
endfunction
