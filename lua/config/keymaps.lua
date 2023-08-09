-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("v", "<leader>y", '"+y', { silent = true, noremap = true })
vim.keymap.set("v", "<leader>p", '"+p', { silent = true, noremap = true })
vim.keymap.set("v", "<leader>Y", '"*p', { silent = true, noremap = true })
vim.keymap.set("v", "<leader>P", '"*p', { silent = true, noremap = true })
