-- neovim is a flatpak installation.
-- add 
--     alias nvim='flatpak run io.neovim.nvim -u ~/.config/nvim/init.lua'
-- to .bashrc to load config. 



-- Enable mouse support
vim.o.mouse = 'a'
-- enable line numbers 
 vim.o.number = true
-- Use system clipboard for yanking and pasting
vim.o.clipboard = 'unnamedplus'
-- Handle tabs
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4 
vim.opt.expandtab = true
vim.opt.smarttab = true




-- DEPRECATED / not sure if I should delete:
-- This makes the control c v work somehow
-- vim.api.nvim_set_keymap('v', '<C-S-c>', '"+y', { noremap = true, silent = true })
-- Make copying feel more natural
-- vim.api.nvim_set_keymap('v', '<C-S-c>', 'y', { noremap = true, silent = true })
-- Make pasting feel more natural
-- vim.api.nvim_set_keymap('n', '<C-S-v>', 'p', { noremap = true, silent = true })

-- to copy and paste between Neovim's yank ring and system clipboard,
-- you can use these key mappings
-- vim.api.nvim_set_keymap('v', '<C-c>', '"+y', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', '<C-v>', '"+p', { noremap = true, silent = true })
 
