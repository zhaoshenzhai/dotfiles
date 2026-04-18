local cmp = require('cmp')

local opts = { buffer = true, silent = true }
local autocompile_group = vim.api.nvim_create_augroup("TexAutoCompile", { clear = true })
local tex_cmp_group = vim.api.nvim_create_augroup("TexRefCiteGroup", { clear = true })

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
    callback = function()
        vim.cmd("setlocal foldmethod=expr foldexpr=v:lua.TexFold() foldlevel=0")
        vim.opt_local.indentkeys:remove({"0{", "0}", "{", "}"})
    end
})

vim.api.nvim_create_autocmd({"InsertLeave", "TextChanged"}, {
    group = tex_group,
    pattern = "*.tex",
    command = "let &l:foldexpr = &l:foldexpr"
})

local function get_labels()
    local items = {}
    local seen = {}

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    for _, line in ipairs(lines) do
        for label in line:gmatch('\\label%s*{([^}]+)}') do
            if not seen[label] then
                seen[label] = true
                table.insert(items, {
                    label = label,
                    kind = 18,
                })
            end
        end
    end

    return items
end

local function get_bib_entries()
    local items = {}
    local seen_keys = {}
    local current_dir = vim.fn.expand('%:p:h')

    local bib_path = current_dir .. '/refs.bib'
    if vim.fn.filereadable(bib_path) == 0 then
        bib_path = vim.fn.resolve(current_dir .. '/../../latex/refs.bib')
        if vim.fn.filereadable(bib_path) == 0 then
            return items
        end
    end

    local bib_lines = vim.fn.readfile(bib_path)
    local c_key, c_author, c_title = nil, "Unknown Author", "Unknown Title"

    local function save_entry()
        if c_key and not seen_keys[c_key] then
            seen_keys[c_key] = true
            local display = c_author .. " - " .. c_title
            display = display:gsub("[{}]", ""):gsub("%s+", " ")

            table.insert(items, {
                label = display,
                filterText = c_key .. " " .. display,
                insertText = c_key,
                kind = 14
            })
        end
    end

    for _, line in ipairs(bib_lines) do
        local key, rest = line:match('@%a+%s*{%s*([^,]+),(.*)')
        if key then
            save_entry()
            c_key = key
            c_author = "Unknown Author"
            c_title = "Unknown Title"
            line = rest or ""
        end

        if c_key and line and line ~= "" then
            local author = line:match('[aA]uthor%s*=%s*[{"]?(.*)')
            if author then c_author = author:gsub('[}"]+,?%s*$', '') end

            local title = line:match('[tT]itle%s*=%s*[{"]?(.*)')
            if title then c_title = title:gsub('[}"]+,?%s*$', '') end
        end
    end
    save_entry()

    return items
end

local function check_ref_cite_context(before_cursor)
    local search_pos = 1
    local is_ref = false
    local is_cite = false
    local just_entered = false

    while true do
        local s_ref, e_ref = before_cursor:find("\\[a%-zA%-Z]*ref%*?%s*{", search_pos)
        local s_cite, e_cite = before_cursor:find("\\[a%-zA%-Z]*cite[a%-zA%-Z]*%*?%s*{", search_pos)
        local s_cite2, e_cite2 = before_cursor:find("\\[a%-zA%-Z]*cite[a%-zA%-Z]*%*?%s*%[.-%]%s*{", search_pos)

        local start_pos, end_pos, cmd_type
        if s_ref and (not start_pos or s_ref < start_pos) then start_pos, end_pos, cmd_type = s_ref, e_ref, "ref" end
        if s_cite and (not start_pos or s_cite < start_pos) then start_pos, end_pos, cmd_type = s_cite, e_cite, "cite" end
        if s_cite2 and (not start_pos or s_cite2 < start_pos) then start_pos, end_pos, cmd_type = s_cite2, e_cite2, "cite" end

        if not start_pos then break end

        local brace_level = 1
        local closed = false

        for i = end_pos + 1, #before_cursor do
            local char = before_cursor:sub(i, i)
            if char == "{" then brace_level = brace_level + 1
            elseif char == "}" then brace_level = brace_level - 1 end

            if brace_level == 0 then
                closed = true
                search_pos = i + 1
                break
            end
        end

        if not closed then
            is_ref = (cmd_type == "ref")
            is_cite = (cmd_type == "cite")
            just_entered = (end_pos == #before_cursor)
            break
        end
    end

    return is_ref, is_cite, just_entered
end

-- Autocomplete Setup
local ref_source = {}
function ref_source:is_available() return vim.bo.filetype == "tex" end
function ref_source:get_trigger_characters() return { '{', ',' } end
function ref_source:get_keyword_pattern() return [=[[^}{, \t]\+]=] end
function ref_source:complete(request, callback)
    local line = request.context.cursor_before_line
    local is_ref, _, _ = check_ref_cite_context(line)
    if is_ref then
        callback({ items = get_labels(), isIncomplete = false })
    else
        callback({ items = {}, isIncomplete = false })
    end
end

cmp.register_source('tex_ref', ref_source)

local cite_source = {}
function cite_source:is_available() return vim.bo.filetype == "tex" end
function cite_source:get_trigger_characters() return { '{', ',' } end
function cite_source:get_keyword_pattern() return [=[[^}{, \t]\+]=] end
function cite_source:complete(request, callback)
    local line = request.context.cursor_before_line
    local _, is_cite, _ = check_ref_cite_context(line)
    if is_cite then
        callback({ items = get_bib_entries(), isIncomplete = false })
    else
        callback({ items = {}, isIncomplete = false })
    end
end

cmp.register_source('tex_cite', cite_source)

-- Contextual Autocomplete Switching
vim.api.nvim_create_autocmd({"CursorMovedI", "InsertEnter"}, {
    group = tex_cmp_group,
    pattern = "*.tex",
    callback = function()
        local col = vim.fn.col('.')
        local line = vim.fn.getline('.')
        local before_cursor = string.sub(line, 1, col - 1)

        local is_ref, is_cite, just_entered = check_ref_cite_context(before_cursor)

        if (is_ref or is_cite) and just_entered then
            cmp.complete()
        else
            cmp.setup.buffer({
                sources = {
                    { name = 'tex_ref' },
                    { name = 'tex_cite' },
                    { name = 'attic' },
                    { name = 'omni' },
                    { name = 'buffer' },
                    { name = 'path' }
                }
            })
        end
    end
})
