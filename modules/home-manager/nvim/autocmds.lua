-- Clean trailing spaces
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        local save_cursor = vim.fn.getpos(".")
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.setpos(".", save_cursor)
    end,
})

-- Remember Folds
local fold_group = vim.api.nvim_create_augroup("remember_folds", { clear = true })

vim.api.nvim_create_autocmd({ "BufWinLeave", "BufWritePost", "WinLeave" }, {
    group = fold_group,
    pattern = "*",
    callback = function()
        if vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
            vim.cmd("silent! mkview")
        end
    end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = fold_group,
    pattern = "*",
    callback = function()
        if vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
            vim.cmd("silent! loadview")
        end
    end,
})
