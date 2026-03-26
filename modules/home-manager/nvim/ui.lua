local transparent = { bg = "NONE", ctermbg = "NONE" }

vim.api.nvim_set_hl(0, "Normal", transparent)
vim.api.nvim_set_hl(0, "NonText", transparent)
vim.api.nvim_set_hl(0, "LineNr", transparent)
vim.api.nvim_set_hl(0, "SignColumn", transparent)
vim.api.nvim_set_hl(0, "EndOfBuffer", transparent)
vim.api.nvim_set_hl(0, "StatusLine", transparent)
vim.api.nvim_set_hl(0, "StatusLineNC", transparent)
vim.api.nvim_set_hl(0, "Folded", { bg = "NONE", ctermbg = "NONE", fg = "#abb2bf" })
