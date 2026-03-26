-- Fold questions/exercises and solutions
vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'v:lua.TexFold()'

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

local opts = { buffer = true, silent = true }

-- <C-1>: Compile
vim.keymap.set('n', '<C-1>', '<cmd>write<CR><cmd>VimtexCompile<CR>', opts)

-- <C-2>: SyncTeX
vim.keymap.set('n', '<C-2>', function()
    vim.cmd('write')
    vim.cmd('VimtexView')

    local pdfpath = vim.fn.expand('%:p:r') .. '.pdf'

    if pdfpath:find("Projects/_attic/") then
        local id = vim.fn.fnamemodify(pdfpath, ':h:t')
        local dir = vim.fn.fnamemodify(pdfpath, ':h')
        local key_file = dir .. '/' .. id .. '.key'

        local keyword = ""
        if vim.fn.filereadable(key_file) == 1 then
            local lines = vim.fn.readfile(key_file, '', 1)
            if #lines > 0 then
                keyword = lines[1]:match("^%s*(.-)%s*$"):gsub("/", "-")
            end
        end

        if keyword ~= "" then
            local cache_dir = vim.fn.expand('/tmp/skim_tabs/') .. id
            vim.fn.mkdir(cache_dir, 'p')
            local link_path = cache_dir .. '/' .. keyword .. '.pdf'

            os.execute(string.format('rm -f "%s"', link_path))
            os.execute(string.format('ln "%s" "%s"', pdfpath, link_path))

            vim.fn.jobstart({'bash', '-c', 'sleep 0.2; open -a Skim "' .. link_path .. '"'}, {detach=true})
            return
        end
    end

    vim.fn.jobstart({'open', '-a', 'Skim', pdfpath}, {detach=true})
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
