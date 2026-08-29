-- Cursor's Tab (next-edit prediction + cursor jumps) inside Neovim.
-- Drives Cursor's own backend using the desktop app's existing session,
-- so it needs Cursor installed + signed in, and `uv` on PATH.
return {
  {
    "teocns/neocursor.nvim",
    event = "InsertEnter",
    -- pre-warm the python sidecar's deps at install/update time
    build = 'uv run --with "httpx[http2]" python -c "import httpx"',
    opts = {
      -- blink.cmp owns <Tab>; we hook in through LazyVim's cmp action chain below
      map_tab = false,
    },
  },

  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      -- expose neocursor's accept/jump/chain as a LazyVim cmp action.
      -- package.loaded is checked instead of require() so this never forces
      -- neocursor to load before its InsertEnter event.
      LazyVim.cmp.actions.neocursor = function()
        local nc = package.loaded["neocursor"]
        return nc and nc.accept()
      end

      opts.keymap = opts.keymap or {}
      -- snippets first, then neocursor (accept() only consumes <Tab> when it
      -- has ghost text, a jump target or a chain step), then plain <Tab>
      opts.keymap["<Tab>"] = {
        LazyVim.cmp.map({ "snippet_forward", "neocursor" }),
        "fallback",
      }
    end,
  },
}
