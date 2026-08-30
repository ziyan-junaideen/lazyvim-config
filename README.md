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

### GitHub PR review comments

The equivalent of Cursor's **Comments** tab: list every review comment on the
pull request for the current branch and jump straight to the commented line.

Two pieces, both needing the [`gh`](https://cli.github.com) CLI to be
authenticated (`gh auth status`):

- [`lua/util/pr_comments.lua`](lua/util/pr_comments.lua) — a small local module.
  It resolves the PR for the current branch (`gh pr view`), pulls its review
  threads over GraphQL (so resolved/outdated state comes with them), lists them
  in fzf-lua with the whole thread rendered as markdown in the preview, and
  opens the file at the commented line on `<CR>`.
- [`octo.nvim`](https://github.com/pwntester/octo.nvim), enabled through the
  `lazyvim.plugins.extras.util.octo` extra, for the full review workflow —
  reading a PR, an inline diff with threads attached, replying, resolving and
  submitting.

#### Keymaps

Everything lives under `<leader>gv` ("review"), which is free of collisions with
LazyVim's and fugitive's `<leader>g` maps.

| Key | Action |
| --- | --- |
| `<leader>gvc` | List **open** review comments on the current branch's PR |
| `<leader>gvC` | Same, including resolved threads |
| `<leader>gvq` | Send them to the quickfix list instead (`]q` / `[q` to walk, `<leader>xq` for Trouble) |
| `<leader>gvp` | List PRs (Octo) |
| `<leader>gvo` | Check out a PR (Octo) |
| `<leader>gvs` | Start a review (Octo) |
| `<leader>gvr` | Resume a pending review (Octo) |
| `<leader>gvt` | Toggle the review thread panel (Octo) |
| `<leader>gvx` | Submit the review (Octo) |

Inside the `<leader>gvc` picker: `<CR>` jumps, `<C-o>` opens the thread on
GitHub, `<C-q>` sends the whole list to quickfix. The list is marked `●` open,
`✓` resolved, `~` outdated, and sorts open threads first.

Inside an Octo review buffer the plugin's own maps apply — `]t` / `[t` move
between threads, `<localleader>ca` adds a comment, `<localleader>rt` resolves a
thread, `<localleader>vs` submits (LazyVim's local leader is `\`). `:Octo issue
list`, `:Octo search` and the rest are reachable through `<leader>gi`,
`<leader>gI`, `<leader>gP` and `<leader>gS`.

> [!NOTE]
> Comment line numbers are the ones GitHub recorded against the PR head commit.
> If the working tree has moved on since the comment was written, the cursor
> lands where the comment was made, not where the code now lives.

> [!NOTE]
> The octo extra also maps `<leader>gp` (PR list) and `<leader>gr` (repo list),
> but [`lua/plugins/figutive.lua`](lua/plugins/figutive.lua) sets those to
> `Git push` and `Gread` later during startup and wins.
> [`lua/plugins/octo.lua`](lua/plugins/octo.lua) therefore disables both octo
> maps so which-key stops advertising keys that never fire.
