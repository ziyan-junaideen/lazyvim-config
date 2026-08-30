-- GitLens-style inline blame: virtual text at the end of the current line
-- showing who last touched it, when, and the commit summary.
return {
  {
    "lewis6991/gitsigns.nvim",
    -- NOTE: use `opts` (not `config`) so LazyVim's sign glyphs and its
    -- <leader>gh* hunk mappings are kept and merged with these settings.
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- "right_align" to pin it to the window edge
        delay = 250,
        ignore_whitespace = false,
        use_focus = true,
      },
      -- "You" is substituted automatically when the author is you.
      current_line_blame_formatter = "    <author>, <author_time:%R> · <summary>",
      current_line_blame_formatter_nc = "    You · uncommitted",
      -- Requires the `gh` CLI: adds PR numbers/links to the blame popup.
      gh = true,
      preview_config = { border = "rounded" },
    },
    keys = {
      { "<leader>gtb", "<cmd>Gitsigns toggle_current_line_blame<cr>", desc = "Toggle Line Blame" },
      { "<leader>ghP", "<cmd>Gitsigns preview_hunk<cr>", desc = "Preview Hunk (float)" },
    },
  },
}
