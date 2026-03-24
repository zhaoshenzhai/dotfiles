local cmp = require('cmp')

local attic_cache = {}
local attic_dir = vim.fn.expand('~/iCloud/Projects/_attic')
local attic_group = vim.api.nvim_create_augroup("AtticSetup", { clear = true })
local in_aref_mode = false

local function load_attic_cache()
    local items = {}
    local dirs = vim.fn.globpath(attic_dir, '[0-9][0-9][0-9][0-9][0-9]', 0, 1)

    for _, dir in ipairs(dirs) do
        local id = vim.fn.fnamemodify(dir, ':t')
        local kw_file = dir .. '/' .. id .. '.key'

        if vim.fn.filereadable(kw_file) == 1 then
            local lines = vim.fn.readfile(kw_file)
            local keywords = lines[1] or ""

            if keywords ~= "" then
                table.insert(items, {
                    label = keywords,
                    filterText = keywords,
                    insertText = id,
                    documentation = {
                        kind = "markdown",
                        value = "**Code:** `" .. id
                    }
                })
            end
        end
    end
    attic_cache = items
end

-- Autocomplete Setup
local attic_source = {}
function attic_source:is_available() return true end
function attic_source:get_trigger_characters() return { '{' } end
function attic_source:get_keyword_pattern() return [=[[^{}]\+]=] end

function attic_source:complete(request, callback)
    local line = request.context.cursor_before_line
    if not string.match(line, "\\aref{[^}]*}{[^}]*$") then
        callback({ items = {}, isIncomplete = false })
        return
    end
    callback({ items = attic_cache, isIncomplete = false })
end

cmp.register_source('attic', attic_source)

-- Initialize Cache and Commands
load_attic_cache()
vim.api.nvim_create_user_command('ReloadAttic', function()
    load_attic_cache()
    print("Attic cmp cache reloaded!")
end, {})

-- Contextual Autocomplete Switching
vim.api.nvim_create_autocmd({"CursorMovedI", "InsertEnter"}, {
    group = attic_group,
    pattern = "*.tex",
    callback = function()
        local col = vim.fn.col('.')
        local line = vim.fn.getline('.')
        local before_cursor = string.sub(line, 1, col - 1)
        local is_code_block = string.match(before_cursor, "\\aref{[^}]*}{[^}]*$")

        if is_code_block then
            if not in_aref_mode then
                cmp.setup.buffer({ sources = { { name = 'attic' } } })
                in_aref_mode = true
            end

            if string.match(before_cursor, "\\aref{[^}]*}{$") then
                cmp.complete()
            end
        else
            if in_aref_mode then
                cmp.setup.buffer({
                    sources = {
                        { name = 'attic' },
                        { name = 'omni' },
                        { name = 'buffer' },
                        { name = 'path' }
                    }
                })
                in_aref_mode = false
            end
        end
    end
})

-- Automatic Metadata Syncing
vim.api.nvim_create_autocmd("BufWritePost", {
    group = attic_group,
    pattern = "*/_attic/*/*",
    callback = function()
        local id = vim.fn.expand('%:p:h:t')
        local script_path = vim.fn.expand('~/iCloud/Dotfiles/modules/scripts/attic.sh')
        vim.fn.jobstart({script_path, "-u", id}, { detach = true })

        if vim.fn.expand('%:e') == "key" then
            load_attic_cache()
            vim.schedule(function()
                vim.api.nvim_echo({{"Attic: cmp cache reloaded from " .. id .. ".key", "None"}}, false, {})
            end)
        end
    end,
})

-- Navigation
vim.keymap.set('n', '<C-h>', '<C-o>')
vim.keymap.set('n', '<C-l>', function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col('.')
    local id = nil

    local search_pos = 1
    while true do
        local s, e = line:find("\\aref{", search_pos, true)
        if not s then break end

        local brace_level = 1
        local first_arg_end = -1
        for i = e + 1, #line do
            local char = line:sub(i, i)
            if char == "{" then brace_level = brace_level + 1
            elseif char == "}" then brace_level = brace_level - 1 end

            if brace_level == 0 then
                first_arg_end = i
                break
            end
        end

        if first_arg_end ~= -1 then
            local id_start = first_arg_end + 1
            local match_id = line:match("^{([0-9][0-9][0-9][0-9][0-9])}", id_start)

            if match_id then
                local total_end = first_arg_end + 7

                if col >= s and col <= total_end then
                    id = match_id
                    break
                end
                search_pos = total_end + 1
            else
                search_pos = e + 1
            end
        else
            search_pos = e + 1
        end
    end

    if id then
        local target = vim.fn.expand('~/iCloud/Projects/_attic/') .. id .. '/' .. id .. '.tex'
        if vim.fn.filereadable(target) == 1 then
            vim.cmd("normal! m'")
            vim.cmd('edit ' .. target)
            vim.api.nvim_echo({{"Attic: Jumped to note " .. id, "None"}}, false, {})
        else
            vim.api.nvim_echo({{"Attic: Note " .. id .. " not found", "ErrorMsg"}}, false, {})
        end
    else
        local keys = vim.api.nvim_replace_termcodes("<C-i>", true, false, true)
        vim.api.nvim_feedkeys(keys, "n", false)
    end
end)

-- Surround with aref
vim.api.nvim_create_autocmd("FileType", {
    group = attic_group,
    pattern = "tex",
    callback = function()
        vim.keymap.set('v', '<C-l>', '"zc\\aref{<C-r>z}{}<Left>', { buffer = true })
        vim.keymap.set('v', '<C-S-l>', function()
            vim.cmd('normal! "zy')
            local text = vim.fn.getreg('z')
            local clean_text = text:gsub("\n", " "):gsub("\r", "")

            local script_path = vim.fn.expand('~/iCloud/Dotfiles/modules/scripts/attic.sh')
            local cmd = string.format("'%s' -e", script_path)
            local output = vim.fn.system(cmd)

            local id = string.match(output, "Note (%d%d%d%d%d)")

            if id then
                local replacement = string.format("\\aref{%s}{%s}", clean_text, id)
                vim.fn.setreg('z', replacement)
                vim.cmd('normal! gv"zp')
                vim.cmd('write')

                local target_tex = vim.fn.expand('~/iCloud/Projects/_attic/') .. id .. '/' .. id .. '.tex'
                local target_key = vim.fn.expand('~/iCloud/Projects/_attic/') .. id .. '/' .. id .. '.key'

                vim.cmd("normal! m'")
                vim.cmd('edit ' .. target_tex)
                vim.cmd('split ' .. target_key)

                vim.cmd('startinsert')
                vim.api.nvim_echo({{"Attic: Note " .. id .. " created. Enter keywords and :wq to proceed to the note.", "None"}}, false, {})
            else
                vim.api.nvim_echo({{"Attic: Failed to create note. Output: " .. output, "ErrorMsg"}}, false, {})
            end
        end, { buffer = true })
    end
})
