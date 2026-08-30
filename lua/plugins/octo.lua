-- GitHub pull requests inside Neovim.
--
-- The plugin itself comes from the `lazyvim.plugins.extras.util.octo` extra
-- (listed in `lazyvim.json`); this file only fixes the extra's keymap
-- collisions and adds the `<leader>gv` review namespace.
return {
  {
    "pwntester/octo.nvim",
    keys = {
      -- The extra maps these, but figutive.lua sets them later during startup
      -- (`Git push` / `Gread`), so octo never actually gets them. Drop them
      -- rather than leave dead entries in which-key.
      { "<leader>gp", false },
      { "<leader>gr", false },

      { "<leader>gvp", "<cmd>Octo pr list<cr>", desc = "List PRs (Octo)" },
      { "<leader>gvo", "<cmd>Octo pr checkout<cr>", desc = "Checkout PR (Octo)" },
      { "<leader>gvs", "<cmd>Octo review start<cr>", desc = "Start Review (Octo)" },
      { "<leader>gvr", "<cmd>Octo review resume<cr>", desc = "Resume Review (Octo)" },
      { "<leader>gvt", "<cmd>Octo review thread<cr>", desc = "Toggle Thread Panel (Octo)" },
      { "<leader>gvx", "<cmd>Octo review submit<cr>", desc = "Submit Review (Octo)" },
    },
  },

  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      -- `spec` is a list; tbl_deep_extend would overwrite it, so append.
      table.insert(opts.spec, { "<leader>gv", group = "review (PR)" })
    end,
  },
}
