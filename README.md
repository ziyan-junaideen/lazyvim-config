# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

## Plugins

### Gitsigns

Configured in [`lua/plugins/gitsigns.lua`](lua/plugins/gitsigns.lua) to give a
VSCode/Cursor (GitLens) style inline blame: the author, relative time and commit
summary for the line under the cursor are shown as virtual text at the end of
that line, with drill-down into the full commit.

```
local M = {}    You, 3 years ago · Initial commit
```

The spec uses `opts` rather than `config = function() ... end` on purpose. A bare
`require("gitsigns").setup()` discards everything LazyVim configures for the
plugin — its sign glyphs and its entire `<leader>gh*` hunk keymap set — whereas
`opts` merges with them.

#### Settings

| Option | Value | Notes |
| --- | --- | --- |
| `current_line_blame` | `true` | The inline annotation itself |
| `current_line_blame_opts.delay` | `250` | ms after the cursor settles |
| `current_line_blame_opts.virt_text_pos` | `eol` | Use `right_align` to pin it to the window edge instead |
| `current_line_blame_formatter` | `<author>, <author_time:%R> · <summary>` | Your own commits render the author as "You" |
| `gh` | `true` | Adds PR numbers and links to the blame popup; needs the [`gh`](https://cli.github.com) CLI |
| `preview_config.border` | `rounded` | Applies to the preview and blame floats |

#### Keymaps

| Key | Action |
| --- | --- |
| `<leader>ghb` | Blame popup for the current line — full commit message plus that commit's diff |
| `<leader>ghb` (again) | Focuses the popup, so it can be scrolled and the SHA yanked |
| `<leader>ghB` | Full-file blame in a scroll-bound split. Inside: `s` show commit, `S` show in a new tab, `r` reblame at that commit |
| `<leader>gtb` | Toggle the inline blame annotation |
| `<leader>ghP` | Hunk preview in a float |

`<leader>ghb`, `<leader>ghB` and the rest of the `<leader>gh*` hunk mappings come
from LazyVim's own gitsigns spec; `<leader>gtb` and `<leader>ghP` are defined
locally.

> [!NOTE]
> [`lua/plugins/figutive.lua`](lua/plugins/figutive.lua) binds `<leader>gh` to
> `diffget //2`, which shadows the `<leader>gh` hunks prefix — so `<leader>ghb`
> and friends only fire once `timeoutlen` elapses. Rebinding the fugitive
> mergetool maps (e.g. to `<leader>g2` / `<leader>g3`) makes them instant.
