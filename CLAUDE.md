# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal Neovim configuration built on the [LazyVim](https://lazyvim.github.io) distribution
(a LazyVim starter fork), managed by `lazy.nvim`. There is no build step and no test suite —
"running" the code means starting Neovim. Day-to-day work is Ruby/Rails and Elixir/Phoenix,
which is what most of the LSP/formatter/test wiring here targets.

## Commands

There is no Makefile or task runner. Everything happens inside Neovim or via headless invocations.

```bash
# Format Lua (stylua is installed via Mason, NOT on PATH)
~/.local/share/nvim/mason/bin/stylua lua/ init.lua

# Sync plugins to the lockfile / update them
nvim --headless "+Lazy! sync" +qa
nvim --headless "+Lazy! update" +qa

# Health checks
nvim --headless "+checkhealth lazy" +qa
nvim "+LazyHealth"          # LazyVim's own check; interactive
```

Interactive UIs that have no CLI equivalent: `:Lazy` (plugins), `:LazyExtras` (see below),
`:Mason` (LSP servers, formatters, linters), `:ConformInfo` (formatter resolution).

### Verifying a config change

Because a broken spec often fails silently (lazy.nvim catches the error and moves on), assert the
resulting runtime state rather than trusting that Neovim opened. `vim.defer_fn` is needed to let
lazy-loaded plugins attach:

```bash
nvim --headless "+lua vim.defer_fn(function()
  print(vim.inspect(require('gitsigns.config').config.current_line_blame))
  vim.cmd('qa!')
end, 2000)"
```

## Architecture

### Load order

`init.lua` → `lua/config/lazy.lua` → `lazy.setup()` imports `lazyvim.plugins` first, then the
local `plugins` module. `lua/config/{options,keymaps,autocmds}.lua` are loaded by LazyVim itself
(options before startup, keymaps/autocmds on `VeryLazy`) — they are never `require`d explicitly.
Every file under `lua/plugins/` is auto-imported; a file's name is arbitrary and only the returned
spec table matters.

### Extras live in `lazyvim.json`, not in `lazy.lua`

The `{ import = "lazyvim.plugins.extras.*" }` lines in `lua/config/lazy.lua` are all commented out —
that block is inert starter boilerplate. The extras that are actually active (elixir, ruby,
typescript, tailwind, terraform, json, markdown, eslint, project) are the `extras` array in
`lazyvim.json`, which LazyVim reads at startup. Add or remove extras with `:LazyExtras`, which
rewrites that file; hand-editing `lazy.lua` to import an extra will duplicate specs instead.

### `opts` vs `config` — the rule that matters most here

LazyVim already ships a spec for most plugins in this repo. Adding `opts = {...}` deep-merges with
LazyVim's, preserving its defaults and its `on_attach` keymaps. Adding `config = function() ... end`
**replaces** LazyVim's config entirely, so a bare `require("x").setup()` silently discards
everything LazyVim configured for that plugin.

`lua/plugins/gitsigns.lua` documents this in a comment — it was previously a `config` function whose
`setup()` call had thrown away LazyVim's sign glyphs and its whole `<leader>gh*` hunk keymap set.
Prefer `opts` (or `opts = function(_, opts)` when extending a list, since `tbl_deep_extend` overwrites
rather than appends lists). `telescope.lua` and `figutive.lua` still use `config` functions —
intentionally, since neither is configured by LazyVim in the same way.

### Two pickers coexist

LazyVim's active picker resolves to **fzf-lua**, which owns `<leader>ff`, `<leader>fg`, `<leader>sg`
and the rest of LazyVim's default picker maps. Telescope is also installed and configured
(`lua/plugins/telescope.lua`) but is only reachable through the explicit maps that file sets:
`<leader>?`, `<leader>/`, `<leader>fb`, `<leader>s{f,h,w,g,d,b}`. Some of those shadow LazyVim
defaults of the same name. When adding a picker keymap, decide which of the two it should hit.

### Keymap namespace collisions

Local mappings are set in two places — plugin `keys` specs and bare `vim.keymap.set` calls inside
`config` functions — and several collide with LazyVim's own `<leader>` groups. Known live one:
`figutive.lua` binds `<leader>gh` (`diffget //2`), which shadows LazyVim's `<leader>gh` *hunks*
prefix, so `<leader>ghb` etc. only fire after `timeoutlen`. Before adding a `<leader>` map, check
it against LazyVim's which-key groups (`<leader>g` git, `<leader>gh` hunks, `<leader>c` code,
`<leader>f` file/find, `<leader>s` search, `<leader>u` ui, `<leader>x` diagnostics).

### Files that are not what they look like

- `lua/plugins/example.lua` — starter boilerplate, short-circuited by `if true then return {} end`
  on line 3. Its nvim-cmp, tsserver and Mason `ensure_installed` blocks are **dead code** and do not
  apply. Do not edit it to change behaviour; it also predates the migration to `blink.cmp`.
- `lua/plugins/mason.lua` — despite the name, configures `nvim-lspconfig` (solargraph, rubocop,
  tsserver, tailwindcss) and `conform.nvim` (erb formatting). Mason itself is not configured here.
- `lua/plugins/lazygit.lua` — its first line is `# LazyGit configuration`, a shell-style comment
  that only parses because Lua skips a leading `#` line in a chunk. Nothing may be inserted above it.
- `lua/plugins/figutive.lua` — typo for "fugitive"; the filename is load-order irrelevant.

### Completion chain

Completion is `blink.cmp` (LazyVim's default), not nvim-cmp. `lua/plugins/neocursor.lua` shows the
pattern for inserting into the `<Tab>` chain: register a `LazyVim.cmp.actions.<name>` function, then
list it in `opts.keymap["<Tab>"]` via `LazyVim.cmp.map({...})` so the actions fall through in order.
That file deliberately probes `package.loaded["neocursor"]` instead of `require`ing, to avoid forcing
a lazy-loaded plugin to load early.

### Plugin versions are not pinned in VCS

`lazy-lock.json` is listed in `.gitignore` and is untracked, while `lazy.nvim` runs with
`version = false` and `checker.enabled = true`. Plugin versions therefore float and update
notifications appear automatically — a "this broke after an update" report is plausible and is not
reproducible from the repo alone. Also note `defaults.lazy = false`, so local plugin specs load at
startup unless they declare their own `event`/`keys`/`cmd`.

## Conventions

- Lua formatting follows `stylua.toml`: 2-space indent, 120 column width. Use `-- stylua: ignore`
  above a line that must stay long (the codebase already does this for one-line keymap specs).
- `README.md` documents user-facing keymaps and settings per plugin under `## Plugins` → `### <Plugin>`.
  When a change alters a keymap or a visible behaviour, update that section too.

## Git workflow

Commit directly to `main`. This is a single-user config repo with no CI and no review step, so do
not create a feature branch, and do not open a pull request, unless explicitly asked to. Push to
`origin main` when the change is done.
