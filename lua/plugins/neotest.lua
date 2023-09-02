return {
  { "tpope/vim-vinegar", keys = { { "-", desc = "Explore folder" } } },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "olimorris/neotest-rspec",
    },
    opts = {
      adapters = {
        ["neotest-rspec"] = {
          rspec_cmd = function()
            return vim.tbl_flatten({
              "bundle",
              "exec",
              "rspec",
            })
          end,
        },
      },
    },
    keys = {
      {
        "<leader>ta",
        function()
          require("neotest").run.attach()
        end,
        desc = "Attach",
      },
    },
  },
}
