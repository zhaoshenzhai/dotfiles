_G.CFold = function()
    local lnum = vim.v.lnum
    local line = vim.fn.getline(lnum)

    if line:match('^%a.*%)%s*{') then
        return '>1'
    elseif line:match('^}') then
        return '<1'
    end

    return '='
end

local c_group = vim.api.nvim_create_augroup("c_folds", { clear = true })

vim.api.nvim_create_autocmd({"FileType", "BufWinEnter"}, {
    group = c_group,
    pattern = {"*.c", "*.h", "*.m"},
    command = "setlocal foldmethod=expr foldexpr=v:lua.CFold() foldlevel=0"
})

vim.api.nvim_create_autocmd({"InsertLeave", "TextChanged"}, {
    group = c_group,
    pattern = {"*.c", "*.h", "*.m"},
    command = "let &l:foldexpr = &l:foldexpr"
})
