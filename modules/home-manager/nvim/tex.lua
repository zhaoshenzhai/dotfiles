local opts = { buffer = true, silent = true }

vim.keymap.set('n', '<C-S-c>', '<cmd>write<CR><cmd>VimtexCompile<CR>', opts)
vim.keymap.set('n', '<C-S-v>', '<cmd>write<CR><cmd>VimtexView<CR>', opts)
vim.keymap.set('n', '<C-S-d>', '<cmd>!rm -f *.aux(N) *.bbl(N) *.bcf(N) *.bcf-SAVE-ERROR(N) *.bbl-SAVE-ERROR(N) *.blg(N) *.fdb_latexmk(N) *.fls(N) *.log(N) *.xml(N) *.run.xml(N) *.synctex.gz(N) *.synctex\\(busy\\)(N)<CR><CR>', opts)

-- Open student pdf
vim.keymap.set('n', '<C-S-s>', function()
    vim.cmd('write')
    local f = vim.fn.expand('%:p:r') .. '_Student.pdf'
    if vim.fn.filereadable(f) == 1 then
        vim.fn.jobstart({ "open", "-a", "Skim", f }, {detach=true})
    end
end, opts)

-- Open corresponding .key
vim.keymap.set('n', '<C-S-k>', function()
    local current_file = vim.fn.expand('%:p')
    if current_file:match('Projects/_attic/notes') and current_file:match('%.tex$') then
        local key_file = current_file:gsub('%.tex$', '.key')

        if vim.fn.filereadable(key_file) == 1 then
            vim.cmd('tabedit ' .. vim.fn.fnameescape(key_file))
        end
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
    command = "setlocal foldmethod=expr foldexpr=v:lua.TexFold() foldlevel=0"
})

vim.api.nvim_create_autocmd({"InsertLeave", "TextChanged"}, {
    group = tex_group,
    pattern = "*.tex",
    command = "let &l:foldexpr = &l:foldexpr"
})
