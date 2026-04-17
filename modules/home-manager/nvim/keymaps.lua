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
local expr_opts = { silent = true, expr = true }
vim.keymap.set({'n', 'o', 'x'}, 'j', "v:count == 0 ? 'gj' : 'j'", expr_opts)
vim.keymap.set({'n', 'o', 'x'}, 'k', "v:count == 0 ? 'gk' : 'k'", expr_opts)

local opts = { silent = true }
vim.keymap.set({'n', 'o', 'x'}, '0', 'g0', opts)
vim.keymap.set({'n', 'o', 'x'}, '^', 'g^', opts)
vim.keymap.set({'n', 'o', 'x'}, '$', 'g$', opts)
