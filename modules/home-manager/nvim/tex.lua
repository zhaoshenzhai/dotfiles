local opts = { buffer = true, silent = true }
local autocompile_group = vim.api.nvim_create_augroup("TexAutoCompile", { clear = true })

-- Auto-compile
vim.api.nvim_create_autocmd("BufWritePost", {
    group = autocompile_group,
    pattern = "*.tex",
    callback = function(ev)
        if ev.file:match('/_attic/notes/') then return end
        vim.fn.jobstart({ "texManager", ev.file }, { detach = true })
    end,
})

-- Forward sync
vim.keymap.set('n', '<C-Enter>', function()
    local tex_file = vim.fn.expand('%:p')
    local pdf_file = vim.fn.expand('%:p:r') .. '.pdf'
    local line = vim.fn.line('.')

    local displayline = '/Applications/Skim.app/Contents/SharedSupport/displayline'

    if vim.fn.executable(displayline) == 1 then
        vim.fn.jobstart({ displayline, "-r", tostring(line), pdf_file, tex_file }, { detach = true })
    end
end, opts)

-- Open student pdf
vim.keymap.set('n', '<C-S-Enter>', function()
    vim.cmd('write')
    local f = vim.fn.expand('%:p:r') .. '_Student.pdf'
    if vim.fn.filereadable(f) == 1 then
        vim.fn.jobstart({ "open", "-a", "Skim", f }, {detach=true})
    end
end, opts)

-- Math zone for snippets
_G.in_mathzone = function()
    local has_ts, ts = pcall(require, 'vim.treesitter')
    if not has_ts then return 0 end

    local buf = vim.api.nvim_get_current_buf()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1

    if vim.fn.mode():match('^i') and col > 0 then
        col = col - 1
    end

    local node = ts.get_node({ bufnr = buf, pos = {row, col} })

    while node do
        local type = node:type()
        if type == 'inline_formula' or type == 'displayed_equation' or type == 'math_environment' then
            return 1
        end
        node = node:parent()
    end

    return 0
end

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
