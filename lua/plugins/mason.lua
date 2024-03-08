return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        solargraph = {
          mason = false,
        },
        rubocop = {
          mason = false,
        },
      },
      setup = {
        tailwindcss = function(_, opts)
          local util = require("lspconfig.util")

          opts.filetypes = { "html", "elixir", "eelixir", "heex" }

          opts.init_options = {
            userLanguages = {
              elixir = "html-eex",
              eelixir = "html-eex",
              heex = "html-eex",
            },
          }
          opts.settings = {
            tailwindCSS = {
              experimental = {
                classRegex = {
                  'class[:]\\s*"([^"]*)"',
                },
              },
            },
          }

          opts.root_dir = function(fname)
            return util.root_pattern(
              "tailwind.config.js",
              "tailwind.config.cjs",
              "tailwind.config.mjs",
              "tailwind.config.ts",
              "postcss.config.js",
              "postcss.config.cjs",
              "postcss.config.mjs",
              "postcss.config.ts",
              "mix.exs",
              "Gemfile"
            )(fname) or util.find_package_json_ancestor(fname) or util.find_node_modules_ancestor(fname) or util.find_git_ancestor(
              fname
            )
          end
        end,
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = vim.tbl_extend("force", opts.formatters_by_ft or {}, {
        eruby = { "erb_format" },
      })
      opts.formatters = {
        erb_format = {
          args = { "--single-class-per-line", "--stdin" },
        },
      }
    end,
  },
  -- {
  --   "nvimtools/none-ls.nvim",
  --   opts = function(_, opts)
  --     local nls = require("null-ls")

  --     -- table.insert(opts.sources, nls.builtins.formatting.erb_format)
  --   end,
  -- },
}
