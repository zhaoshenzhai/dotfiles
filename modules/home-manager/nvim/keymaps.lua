local opts = { silent = true }
local expr_opts = { silent = true, expr = true }

-- Search and replace
vim.keymap.set('n', '<C-f>', ':%s//gc<Left><Left><Left>', { desc = "Search and Replace" })
vim.keymap.set('v', '<C-f>', ':s//gc<Left><Left><Left>', { desc = "Search and Replace Range" })

-- Spell checking and correction
vim.keymap.set('n', '<C-s>', ':set spell!<CR>', opts)
vim.keymap.set('i', '<C-c>', '<c-g>u<Esc>[s1z=`]a<c-g>u', opts)
vim.keymap.set('n', '<C-c>', 'mz[s1z=`z', opts)

-- Custom text objects
vim.keymap.set('x', 'im', 'T$ot$', opts)
vim.keymap.set('o', 'im', ':normal vim<CR>', opts)
vim.keymap.set('x', 'am', 'F$of$', opts)
vim.keymap.set('o', 'am', ':normal vam<CR>', opts)

-- Screen movement
_G.ScreenMovement = function(movement)
    if vim.wo.wrap then
        return "g" .. movement
    else
        return movement
    end
end

vim.keymap.set({'n', 'o'}, 'j', "v:lua.ScreenMovement('j')", expr_opts)
vim.keymap.set({'n', 'o'}, 'k', "v:lua.ScreenMovement('k')", expr_opts)
vim.keymap.set({'n', 'o'}, '0', "v:lua.ScreenMovement('0')", expr_opts)
vim.keymap.set({'n', 'o'}, '^', "v:lua.ScreenMovement('^')", expr_opts)
vim.keymap.set({'n', 'o'}, '$', "v:lua.ScreenMovement('$')", expr_opts)
