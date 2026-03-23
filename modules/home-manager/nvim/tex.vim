nnoremap <buffer><silent> <C-1> <cmd>write<CR><cmd>VimtexCompile<CR>
nnoremap <buffer><silent> <C-2> <cmd>write<CR><cmd>VimtexView<CR><cmd>VimtexView<CR>
nnoremap <buffer><silent> <C-3> <cmd>write<CR><cmd>lua vim.fn.jobstart({"/Users/zhao/iCloud/Dotfiles/scripts/attic.sh", "-c"})<CR>
nnoremap <buffer><silent> <C-4> <cmd>write<CR><cmd>lua local f=vim.fn.expand('%:p:r')..'_Student.pdf'; if vim.fn.filereadable(f)==1 then vim.fn.jobstart({ "open", "-n", "-a", "Skim", f }, {detach=true}) end<CR>

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
