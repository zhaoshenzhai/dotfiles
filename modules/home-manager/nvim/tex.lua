local opts = { buffer = true, silent = true }

-- <C-1>: Compile
vim.keymap.set('n', '<C-1>', '<cmd>write<CR><cmd>VimtexCompile<CR>', opts)

-- <C-2>: SyncTeX
vim.keymap.set('n', '<C-2>', function()
    vim.cmd('write')
    vim.cmd('VimtexView')
    vim.fn.jobstart({ "open", "-n", "-a", "Skim" }, { detach = true })
end, opts)

-- <C-3>: Clean
local clean_cmd = '!rm -f *.aux(N) *.bbl(N) *.bcf(N) *bcf-SAVE-ERROR(N) *.blg(N) *.fdb_latexmk(N) *.fls(N) *.log(N) *.run.xml(N) *.synctex.gz(N) *.synctex\\(busy\\)(N)'
vim.keymap.set('n', '<C-3>', '<cmd>write<CR><cmd>' .. clean_cmd .. '<CR><CR>', opts)

-- <C-4>: Open student pdf
vim.keymap.set('n', '<C-4>', function()
    vim.cmd('write')
    local f = vim.fn.expand('%:p:r') .. '_Student.pdf'
    if vim.fn.filereadable(f) == 1 then
        vim.fn.jobstart({ "open", "-a", "Skim", f }, {detach=true})
    end
end, opts)

-- Fold questions/exercises and solutions
_G.TexFold = function()
    local lnum = vim.v.lnum
    local line = vim.fn.getline(lnum)

    if line:match('^%s*\\begin%{question%}') or line:match('^%s*\\begin%{exercise%}') then
        return '>1'
    elseif line:match('^%s*\\end%{solution%}') then
        return '<1'
    elseif line:match('^%s*\\end%{question%}') or line:match('^%s*\\end%{exercise%}') then
        local next_lnum = vim.fn.nextnonblank(lnum + 1)
        if next_lnum > 0 then
            local next_line = vim.fn.getline(next_lnum)
            if next_line:match('^%s*\\begin%{solution%}') then
                return '1'
            end
        end
        return '<1'
    end

    return '='
end

local tex_group = vim.api.nvim_create_augroup("tex_folds", { clear = true })

vim.api.nvim_create_autocmd({"FileType", "BufWinEnter"}, {
    group = tex_group,
    pattern = "*.tex",
    command = "setlocal foldmethod=expr foldexpr=TexFold(v:lnum) foldlevel=0"
})

vim.api.nvim_create_autocmd({"InsertLeave", "TextChanged"}, {
    group = tex_group,
    pattern = "*.tex",
    command = "let &l:foldexpr = &l:foldexpr"
})

vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'v:lua.TexFold()'
