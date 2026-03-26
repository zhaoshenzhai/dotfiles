-- Sketchybar
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

-- Dynamically start a server socket based on the Aerospace window ID
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if vim.env.FROM_LAUNCHER == "1" then
            vim.defer_fn(function()
                local win_id = vim.fn.system("aerospace list-windows --focused --format '%{window-id}'"):gsub("%s+", "")
                if win_id ~= "" then
                    local socket_path = "/tmp/nvim-window-" .. win_id .. ".sock"
                    os.remove(socket_path)
                    vim.fn.serverstart(socket_path)
                end
            end, 100)
        end
    end,
})

-- Quit overrides for launcher
if vim.env.FROM_LAUNCHER == "1" then
    vim.cmd([[
        cnoreabbrev <expr> q getcmdtype() == ":" && getcmdline() == 'q' ? (tabpagenr('$') > 1 ? 'q' : 'silent !aerospace close --quit-if-last-window') : 'q'
        cnoreabbrev <expr> wq getcmdtype() == ":" && getcmdline() == 'wq' ? (tabpagenr('$') > 1 ? 'wq' : 'w <bar> silent !aerospace close --quit-if-last-window') : 'wq'
    ]])
end
