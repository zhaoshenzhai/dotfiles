vim.opt.shortmess:append("c")

-- Aerospace and sketchybar
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

-- Clean trailing spaces
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*",
    callback = function()
        local save_cursor = vim.fn.getpos(".")
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.setpos(".", save_cursor)
    end,
})

-- Screen movement
_G.ScreenMovement = function(movement)
    if vim.wo.wrap then
        return "g" .. movement
    else
        return movement
    end
end

-- Tabs
_G.closed_tabs = {}

vim.api.nvim_create_autocmd("QuitPre", {
    callback = function()
        local current_buf = vim.api.nvim_get_current_buf()
        local file = vim.api.nvim_buf_get_name(current_buf)

        if file ~= "" and vim.fn.filereadable(file) == 1 then
            table.insert(_G.closed_tabs, file)
        end
    end,
})

_G.ReopenLastClosedTab = function()
    if #_G.closed_tabs > 0 then
        local last_file = table.remove(_G.closed_tabs)
        vim.cmd("tabedit " .. vim.fn.fnameescape(last_file))
    else
        print("No recently closed tabs to reopen")
    end
end

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

-- Quit
if vim.env.FROM_LAUNCHER == "1" then
    vim.cmd([[
        cnoreabbrev <expr> q getcmdtype() == ":" && getcmdline() == 'q' ? (tabpagenr('$') > 1 ? 'q' : 'silent !aerospace close --quit-if-last-window') : 'q'
        cnoreabbrev <expr> wq getcmdtype() == ":" && getcmdline() == 'wq' ? (tabpagenr('$') > 1 ? 'wq' : 'w <bar> silent !aerospace close --quit-if-last-window') : 'wq'
    ]])
end
