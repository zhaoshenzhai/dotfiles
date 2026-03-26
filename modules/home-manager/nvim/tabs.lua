-- Tabline
_G.CustomTabLine = function()
    local s = ""
    for i = 1, vim.fn.tabpagenr('$') do
        if i == vim.fn.tabpagenr() then
            s = s .. "%#TabLineSel#"
        else
            s = s .. "%#TabLine#"
        end

        local buflist = vim.fn.tabpagebuflist(i)
        local winnr = vim.fn.tabpagewinnr(i)
        local bufnr = buflist[winnr]
        local file = vim.fn.bufname(bufnr)

        local basename = vim.fn.fnamemodify(file, ":t")
        if basename == "" then basename = "[No Name]" end

        s = s .. " " .. i .. ": " .. basename .. " "
    end
    s = s .. "%#TabLineFill#%T"
    return s
end

vim.opt.tabline = "%!v:lua.CustomTabLine()"
vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE", ctermbg = "NONE" })
vim.api.nvim_set_hl(0, "TabLine", { bg = "NONE", ctermbg = "NONE", fg = "#5c6370" })
vim.api.nvim_set_hl(0, "TabLineSel", { bg = "NONE", ctermbg = "NONE", fg = "#61afef", bold = true })

-- Track closed tabs to reopen them
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

-- Tab keymaps
local opts = { silent = true }
vim.keymap.set('n', '<C-j>', ':tabprevious<CR>', opts)
vim.keymap.set('n', '<C-k>', ':tabnext<CR>', opts)
vim.keymap.set('n', '<C-n>', ':tabnew<CR>', opts)
vim.keymap.set('n', '<C-u>', ':lua ReopenLastClosedTab()<CR>', opts)

vim.keymap.set('n', '<C-w>', function()
    if vim.fn.tabpagenr('$') > 1 then
        vim.cmd('q')
    end
end, { silent = true, nowait = true })
