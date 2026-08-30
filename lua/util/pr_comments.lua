-- GitHub pull-request review comments, listed and jumpable -- the rough
-- equivalent of Cursor's "Comments" tab.
--
-- Pulls the review threads of the PR for the current branch through the `gh`
-- CLI (GraphQL, so resolved/outdated state comes with them), lists them in the
-- active picker with the full thread as the preview, and opens the commented
-- file at the commented line in the working tree.
--
-- Line numbers are the ones GitHub recorded against the PR head commit; if the
-- working tree has moved on since, the cursor lands where the comment was made,
-- not necessarily where the code now lives.

local M = {}

local GRAPHQL = [[
query($owner: String!, $name: String!, $number: Int!, $endCursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          isResolved
          isOutdated
          path
          line
          startLine
          originalLine
          comments(first: 100) {
            totalCount
            nodes { author { login } body createdAt url }
          }
        }
      }
    }
  }
}
]]

-- Flatten each thread to a single compact JSON object per line, so `--paginate`
-- output can be decoded a line at a time.
-- stylua: ignore
local JQ = ".data.repository.pullRequest.reviewThreads.nodes[] | {"
  .. "path: .path,"
  .. "line: (.line // .originalLine // 1),"
  .. "startLine: (.startLine // .line // .originalLine // 1),"
  .. "isResolved: .isResolved,"
  .. "isOutdated: .isOutdated,"
  .. "count: .comments.totalCount,"
  .. 'url: (.comments.nodes[0].url // ""),'
  .. 'comments: [.comments.nodes[] | { author: (.author.login // "ghost"), body: .body, createdAt: .createdAt }]'
  .. "}"

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "PR Comments" })
end

local function git_root()
  local name = vim.api.nvim_buf_get_name(0)
  local start = (name ~= "" and vim.uv.fs_stat(name)) and name or vim.uv.cwd()
  return vim.fs.root(start, ".git") or vim.uv.cwd()
end

---@param args string[]
---@param opts { cwd: string, stdin: string? }
---@param on_done fun(out: vim.SystemCompleted)
local function gh(args, opts, on_done)
  vim.system(
    vim.list_extend({ "gh" }, args),
    { cwd = opts.cwd, stdin = opts.stdin, text = true },
    vim.schedule_wrap(on_done)
  )
end

local function fail(out, what)
  local err = vim.trim(out.stderr or "")
  notify(("%s\n%s"):format(what, err ~= "" and err or "gh exited with " .. out.code), vim.log.levels.ERROR)
end

--- First non-empty, non-fence line of a comment body, for the list column.
local function summary(body)
  for line in (body or ""):gsub("\r", ""):gmatch("[^\n]*") do
    local text = vim.trim(line)
    if text ~= "" and not text:match("^```") and not text:match("^>") then
      return text
    end
  end
  return "(empty)"
end

local function thread_lines(thread)
  local state = thread.isResolved and "resolved" or "unresolved"
  if thread.isOutdated then
    state = state .. ", outdated"
  end
  local lines = {
    ("# %s:%d"):format(thread.path, thread.line),
    "",
    ("_%s · %d comment%s_"):format(state, thread.count, thread.count == 1 and "" or "s"),
    "",
  }
  for i, comment in ipairs(thread.comments) do
    if i > 1 then
      vim.list_extend(lines, { "---", "" })
    end
    vim.list_extend(lines, { ("**@%s** · %s"):format(comment.author, comment.createdAt), "" })
    vim.list_extend(lines, vim.split((comment.body or ""):gsub("\r", ""), "\n"))
    table.insert(lines, "")
  end
  return lines
end

local function jump(thread, root)
  local file = root .. "/" .. thread.path
  if vim.fn.filereadable(file) == 0 then
    notify(
      ("%s is not in the working tree -- renamed, deleted, or not checked out."):format(thread.path),
      vim.log.levels.WARN
    )
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(file))
  local lnum = math.max(1, math.min(thread.startLine, vim.api.nvim_buf_line_count(0)))
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  vim.cmd("normal! zz")
end

local function to_quickfix(threads, root, title)
  local items = {}
  for _, thread in ipairs(threads) do
    table.insert(items, {
      filename = root .. "/" .. thread.path,
      lnum = thread.startLine,
      col = 1,
      type = thread.isResolved and "N" or "W",
      text = ("@%s: %s"):format(
        thread.comments[1] and thread.comments[1].author or "?",
        summary(thread.comments[1] and thread.comments[1].body)
      ),
    })
  end
  vim.fn.setqflist({}, " ", { title = title, items = items })
  vim.cmd("botright copen")
end

--- fzf-lua previewer rendering the whole thread as markdown.
local function previewer(by_entry)
  local ok, builtin = pcall(require, "fzf-lua.previewer.builtin")
  if not ok then
    return nil
  end
  local Preview = builtin.base:extend()

  function Preview:new(o, opts, fzf_win)
    Preview.super.new(self, o, opts, fzf_win)
    setmetatable(self, Preview)
    return self
  end

  function Preview:populate_preview_buf(entry)
    local thread = by_entry[entry]
    local buf = self:get_tmp_buffer()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, thread and thread_lines(thread) or { "" })
    vim.bo[buf].filetype = "markdown"
    self:set_preview_buf(buf)
    pcall(function()
      self.win:update_preview_title(" Thread ")
    end)
    pcall(function()
      self.win:update_preview_scrollbar()
    end)
  end

  function Preview:gen_winopts()
    return vim.tbl_extend("force", self.winopts, { wrap = true, number = false })
  end

  return Preview
end

local function pick(threads, root, pr)
  -- Entry strings double as the lookup key, so keep them unique.
  local entries, by_entry = {}, {}
  for _, thread in ipairs(threads) do
    local first = thread.comments[1] or {}
    local icon = thread.isResolved and "✓" or (thread.isOutdated and "~" or "●")
    local entry = ("%s %s:%d  @%s  %s%s"):format(
      icon,
      thread.path,
      thread.line,
      first.author or "?",
      summary(first.body),
      thread.count > 1 and (" (+%d)"):format(thread.count - 1) or ""
    )
    while by_entry[entry] do
      entry = entry .. " "
    end
    by_entry[entry] = thread
    table.insert(entries, entry)
  end

  local title = ("PR #%d review comments (%d)"):format(pr.number, #threads)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.ui.select(entries, { prompt = title }, function(choice)
      if choice then
        jump(by_entry[choice], root)
      end
    end)
    return
  end

  fzf.fzf_exec(entries, {
    prompt = "PR Comments> ",
    winopts = { title = " " .. title .. " ", title_pos = "center" },
    previewer = previewer(by_entry),
    actions = {
      ["default"] = function(selected)
        local thread = selected[1] and by_entry[selected[1]]
        if thread then
          jump(thread, root)
        end
      end,
      ["ctrl-o"] = function(selected)
        local thread = selected[1] and by_entry[selected[1]]
        if thread and thread.url ~= "" then
          vim.ui.open(thread.url)
        end
      end,
      ["ctrl-q"] = function()
        to_quickfix(threads, root, title)
      end,
    },
  })
end

---@param opts? { resolved?: boolean, quickfix?: boolean }
--- `resolved` also lists threads that have been resolved (default: only open
--- ones). `quickfix` skips the picker and fills the quickfix list instead.
function M.open(opts)
  opts = opts or {}
  if vim.fn.executable("gh") == 0 then
    return notify("the `gh` CLI is not on PATH", vim.log.levels.ERROR)
  end

  local root = git_root()
  notify("Loading review comments…")

  gh({ "pr", "view", "--json", "number,url,title" }, { cwd = root }, function(out)
    if out.code ~= 0 then
      return fail(out, "No pull request found for this branch.")
    end
    local pr = vim.json.decode(out.stdout)
    local host, owner, name, number = pr.url:match("^https?://([^/]+)/([^/]+)/([^/]+)/pull/(%d+)")
    if not number then
      return notify("could not parse the PR url: " .. pr.url, vim.log.levels.ERROR)
    end

    -- stylua: ignore
    local args = {
      "api", "graphql", "--paginate", "--hostname", host,
      "-F", "owner=" .. owner, "-F", "name=" .. name, "-F", "number=" .. number,
      "-F", "query=@-", "--jq", JQ,
    }
    gh(args, { cwd = root, stdin = GRAPHQL }, function(res)
      if res.code ~= 0 then
        return fail(res, "Could not fetch review threads.")
      end

      local threads = {}
      for line in (res.stdout or ""):gmatch("[^\n]+") do
        local decoded = vim.json.decode(line)
        if opts.resolved or not decoded.isResolved then
          table.insert(threads, decoded)
        end
      end
      if #threads == 0 then
        return notify(("PR #%d has no %sreview comments."):format(pr.number, opts.resolved and "" or "open "))
      end

      -- Open threads first, then by file and line.
      table.sort(threads, function(a, b)
        if a.isResolved ~= b.isResolved then
          return not a.isResolved
        end
        if a.path ~= b.path then
          return a.path < b.path
        end
        return a.line < b.line
      end)

      if opts.quickfix then
        to_quickfix(threads, root, ("PR #%d review comments"):format(pr.number))
      else
        pick(threads, root, pr)
      end
    end)
  end)
end

return M
