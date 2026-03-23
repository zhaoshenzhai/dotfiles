vim.opt.shortmess:append("c")

if vim.env.FROM_LAUNCHER == "1" then
    vim.cmd([[
        cnoreabbrev <expr> q getcmdtype() == ":" && getcmdline() == 'q' ? 'silent !aerospace close --quit-if-last-window' : 'q'
        cnoreabbrev <expr> wq getcmdtype() == ":" && getcmdline() == 'wq' ? 'w <bar> silent !aerospace close --quit-if-last-window' : 'wq'
    ]])
end

vim.api.nvim_create_autocmd({"VimEnter", "VimResume", "FocusGained"}, {
    callback = function()
        vim.fn.jobstart({"bash", "-c", "sleep 0.05 && sketchybar --trigger aerospace_custom_app_switched INFO=\"$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null)\" TITLE=\"nvim\""})
    end,
})

vim.api.nvim_create_autocmd({"VimLeave", "VimSuspend"}, {
    callback = function()
        vim.fn.jobstart(
            {"bash", "-c", "sketchybar --trigger aerospace_custom_app_switched INFO=\"$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null)\" TITLE=\"$(aerospace list-windows --focused --format '%{window-title}' 2>/dev/null)\""},
            { detach = true }
        )
    end,
})
