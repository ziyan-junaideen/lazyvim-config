return {
  {
    "tpope/vim-fugitive",
    config = function()
      local noremap = { noremap = true }

      vim.keymap.set("n", "<leader>gs", "<CMD>G<CR>", noremap)
      vim.keymap.set("n", "<leader>gq", "<CMD>G<CR><CMD>q<CR>", noremap)
      vim.keymap.set("n", "<leader>gw", "<CMD>Gwrite<CR>", noremap)
      vim.keymap.set("n", "<leader>gr", "<CMD>Gread<CR>", noremap)
      vim.keymap.set("n", "<leader>gh", "<CMD>diffget //2<CR>", noremap)
      vim.keymap.set("n", "<leader>gl", "<CMD>diffget //3<CR>", noremap)
      vim.keymap.set("n", "<leader>gp", "<CMD>Git push<CR>", noremap)
    end,
  },
}
