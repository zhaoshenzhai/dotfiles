vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.termguicolors = true
vim.opt.title = true
vim.opt.titlestring = "nvim"
vim.opt.incsearch = true
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.opt.clipboard = "unnamedplus"
vim.opt.autoindent = true
vim.opt.spell = true
vim.opt.spelllang = "en"
vim.opt.ignorecase = true
vim.opt.foldmethod = "manual"
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.hlsearch = false
vim.opt.swapfile = false
vim.opt.showmode = false
vim.opt.laststatus = 3
vim.opt.shortmess:append("c")

vim.g.UltiSnipsExpandTrigger = "<S-tab>"
vim.g.UltiSnipsJumpForwardTrigger = "<tab>"
vim.g.UltiSnipsSnippetDirectories = { "UltiSnips" }

vim.opt.spellfile = vim.fn.expand("~/iCloud/Dotfiles/modules/home-manager/nvim/spell/en.utf-8.add")
