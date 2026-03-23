local cmp = require('cmp')
local attic_cache = {}
local attic_dir = vim.fn.expand('~/iCloud/Projects/_attic')

local function load_attic_cache()
    local items = {}
    local dirs = vim.fn.globpath(attic_dir, '[0-9][0-9][0-9][0-9][0-9]', 0, 1)

    for _, dir in ipairs(dirs) do
        local id = vim.fn.fnamemodify(dir, ':t')
        local kw_file = dir .. '/keywords'

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
                        value = "**Code:** `" .. id .. "`\n**Keywords:** " .. keywords
                    }
                })
            end
        end
    end
    attic_cache = items
end

load_attic_cache()

vim.api.nvim_create_user_command('ReloadAttic', function()
    load_attic_cache()
    print("Attic cmp cache reloaded!")
end, {})

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

local in_aref_mode = false

vim.api.nvim_create_autocmd({"CursorMovedI", "InsertEnter"}, {
    group = vim.api.nvim_create_augroup("AtticCmpTrigger", { clear = true }),
    pattern = "*.tex",
    callback = function()
        local col = vim.fn.col('.')
        local line = vim.fn.getline('.')
        local before_cursor = string.sub(line, 1, col - 1)
        local is_code_block = string.match(before_cursor, "\\aref{[^}]*}{[^}]*$")

        if is_code_block then
            if not in_aref_mode then
                cmp.setup.buffer({
                    sources = { { name = 'attic' } }
                })
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

vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*/_attic/*/*",
    callback = function()
        local id = vim.fn.expand('%:p:h:t')
        vim.fn.system({"/run/current-system/sw/bin/attic", "-m", id})
        if vim.fn.expand('%:t') == "keywords" then load_attic_cache() end
    end,
})

local function jump_to_attic_note()
    local line = vim.api.nvim_get_current_line()
    local id = string.match(line, "\\aref{[^}]*}{([0-9]{5})}")

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
        vim.lsp.buf.definition()
    end
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "tex",
    callback = function()
        vim.keymap.set('n', '<C-l>', jump_to_attic_note, {
            buffer = true,
            desc = "Jump to Attic Note Source"
        })

        vim.keymap.set('n', '<C-h>', '<C-o>', {
            buffer = true,
            desc = "Go Back to Previous Note"
        })
    end
})
