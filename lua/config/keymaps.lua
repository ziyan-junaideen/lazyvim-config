-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("v", "<leader>y", '"+y', { silent = true, noremap = true })
vim.keymap.set("v", "<leader>p", '"+p', { silent = true, noremap = true })
vim.keymap.set("v", "<leader>Y", '"*p', { silent = true, noremap = true })
vim.keymap.set("v", "<leader>P", '"*p', { silent = true, noremap = true })

-- GitHub PR review comments -- see lua/util/pr_comments.lua
-- stylua: ignore start
vim.keymap.set("n", "<leader>gvc", function() require("util.pr_comments").open() end, { desc = "PR Comments (open threads)" })
vim.keymap.set("n", "<leader>gvC", function() require("util.pr_comments").open({ resolved = true }) end, { desc = "PR Comments (incl. resolved)" })
vim.keymap.set("n", "<leader>gvq", function() require("util.pr_comments").open({ quickfix = true }) end, { desc = "PR Comments to Quickfix" })
-- stylua: ignore end
