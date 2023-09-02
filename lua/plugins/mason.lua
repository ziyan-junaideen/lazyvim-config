return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        solargraph = {
          mason = false,
        },
      },
    },
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    opts = function(_, opts)
      local nls = require("null-ls")

      table.insert(opts.sources, nls.builtins.formatting.erb_format)
    end,
  },
}
