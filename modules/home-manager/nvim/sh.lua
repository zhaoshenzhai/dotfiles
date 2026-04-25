_G.ShFold = function()
    local lnum = vim.v.lnum
    local line = vim.fn.getline(lnum)

    if line:match('^%a.*%)%s*{') then
        return '>1'
    elseif line:match('^}') then
        return '<1'
    end

    return '='
end

local sh_group = vim.api.nvim_create_augroup("sh_folds", { clear = true })

vim.api.nvim_create_autocmd({"FileType", "BufWinEnter"}, {
    group = sh_group,
    pattern = {"*.sh", "*.bash", "*.zsh"},
    command = "setlocal foldmethod=expr foldexpr=v:lua.ShFold() foldlevel=0"
})

vim.api.nvim_create_autocmd({"InsertLeave", "TextChanged"}, {
    group = sh_group,
    pattern = {"*.sh", "*.bash", "*.zsh"},
    command = "let &l:foldexpr = &l:foldexpr"
})
