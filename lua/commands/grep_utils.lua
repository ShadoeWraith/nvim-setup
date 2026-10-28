-- Enhanced Ripper-Grep (:grep, :Grep, :Rg) and polished Quickfix layout

-- 1. Configure ripgrep with standard vimgrep formatting if available
if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case --hidden --glob '!.git'"
  vim.opt.grepformat = "%f:%l:%c:%m"
end

-- 2. Custom quickfix item formatting function
-- Provides clean columnar spacing: [File] | [Line:Col] | [Text]
function _G.custom_qf_format(info)
  local items
  if info.quickfix == 1 then
    items = vim.fn.getqflist({ id = info.id, items = 1 }).items
  else
    items = vim.fn.getloclist(info.winid, { id = info.id, items = 1 }).items
  end

  local l = {}
  local start_idx = info.start_idx
  local end_idx = info.end_idx

  -- Calculate max filename width for dynamic clean column alignment
  local max_fname_len = 0
  for i = start_idx, end_idx do
    local item = items[i]
    if item and item.bufnr > 0 then
      local raw_name = vim.api.nvim_buf_get_name(item.bufnr)
      local name = vim.fn.fnamemodify(raw_name, ":.")
      if #name > max_fname_len then
        max_fname_len = #name
      end
    end
  end

  -- Clamp between 18 and 42 characters for a neat table layout
  max_fname_len = math.max(18, math.min(max_fname_len, 42))

  for i = start_idx, end_idx do
    local item = items[i]
    if not item or not item.valid or item.valid == 0 then
      table.insert(l, item and item.text or "")
    else
      local fname = ""
      if item.bufnr > 0 then
        local raw_name = vim.api.nvim_buf_get_name(item.bufnr)
        fname = vim.fn.fnamemodify(raw_name, ":.")
        if #fname > max_fname_len then
          fname = "…" .. fname:sub(#fname - max_fname_len + 2)
        end
      end

      local lnum = item.lnum > 0 and tostring(item.lnum) or "1"
      local col = item.col > 0 and tostring(item.col) or "1"
      local pos = string.format("%s:%s", lnum, col)
      local text = item.text and vim.trim(item.text:gsub("\r", ""):gsub("\n", " ")) or ""

      -- Clean aligned output: File (padded)  │  Line:Col (padded)  │  Match text
      local line = string.format("%-" .. max_fname_len .. "s │ %-7s │ %s", fname, pos, text)
      table.insert(l, line)
    end
  end

  return l
end

vim.o.quickfixtextfunc = "v:lua.custom_qf_format"

-- 3. Dedicated fast, clean search function
local function run_grep(query, whole_word)
  if not query or query == "" then
    -- Default to word under cursor if no query is given
    query = vim.fn.expand("<cword>")
    if query == "" then
      vim.notify("No search query or word under cursor.", vim.log.levels.WARN)
      return
    end
  end

  local escaped_query = vim.fn.escape(query, "#%")
  if whole_word then
    escaped_query = "-w " .. escaped_query
  end

  vim.cmd("silent grep! " .. escaped_query)
  vim.cmd("botright copen 12")

  local qf_list = vim.fn.getqflist()
  if #qf_list == 0 then
    vim.notify("No matches found for: " .. query, vim.log.levels.INFO)
  else
    vim.notify(string.format("Found %d %s for '%s'", #qf_list, #qf_list == 1 and "match" or "matches", query), vim.log.levels.INFO)
  end
end

-- Function to search word under cursor across project (whole word match)
local function grep_cword()
  local cword = vim.fn.expand("<cword>")
  if cword == "" then
    vim.notify("No word under cursor.", vim.log.levels.WARN)
    return
  end
  run_grep(cword, true)
end

-- 4. User commands: :Grep and :Rg
vim.api.nvim_create_user_command("Grep", function(opts)
  run_grep(opts.args)
end, {
  nargs = "*",
  complete = "file",
  desc = "Search workspace with ripgrep and formatted quickfix",
})

vim.api.nvim_create_user_command("Rg", function(opts)
  run_grep(opts.args)
end, {
  nargs = "*",
  complete = "file",
  desc = "Search workspace with ripgrep and formatted quickfix",
})

-- 5. Command-line abbreviation so typing :grep invokes :Grep automatically
vim.cmd([[
  cnoreabbrev <expr> grep (getcmdtype() ==# ':' && getcmdline() =~# '^grep\>') ? 'Grep' : 'grep'
]])

-- 6. Quick toggle function for the search results window
local function toggle_qf()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "quickfix" then
      vim.cmd("cclose")
      return
    end
  end

  local qf = vim.fn.getqflist()
  if #qf == 0 then
    vim.notify("Search results list is empty. Run :grep <pattern> first.", vim.log.levels.WARN)
    return
  end
  vim.cmd("botright copen 12")
end

-- Keymap to toggle results split back open anytime
vim.keymap.set("n", "<leader>q", toggle_qf, { desc = "Toggle Grep / Quickfix Results" })

-- 'gw' or '<leader>gw': Grep all occurrences of word under cursor in project (like gd / gr)
vim.keymap.set("n", "gw", grep_cword, { desc = "Grep word under cursor across project" })
vim.keymap.set("n", "<leader>gw", grep_cword, { desc = "Grep word under cursor across project" })

-- Navigation shortcuts to cycle matches without opening the window
vim.keymap.set("n", "]q", function()
  local ok = pcall(vim.cmd, "cnext")
  if not ok then vim.notify("Reached end of search results", vim.log.levels.INFO) end
end, { desc = "Next search match" })

vim.keymap.set("n", "[q", function()
  local ok = pcall(vim.cmd, "cprev")
  if not ok then vim.notify("Reached start of search results", vim.log.levels.INFO) end
end, { desc = "Previous search match" })

-- 7. Quickfix window styling, keymaps, and visual polish
local qf_group = vim.api.nvim_create_augroup("QuickfixCustomStyling", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = qf_group,
  pattern = "qf",
  callback = function(args)
    local buf = args.buf
    local win = vim.api.nvim_get_current_win()

    -- Window display settings
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].cursorline = true
    vim.wo[win].wrap = false
    vim.wo[win].signcolumn = "no"

    -- Quick ergonomic keymaps inside the Quickfix window
    local opts = { buffer = buf, silent = true }
    -- <CR> to jump to file and keep quickfix open
    vim.keymap.set("n", "<CR>", "<CR>", opts)
    -- 'o' or '<C-CR>' to jump and close quickfix
    vim.keymap.set("n", "o", "<CR><cmd>cclose<CR>", opts)
    -- 'q' or '<Esc>' to quickly close quickfix
    vim.keymap.set("n", "q", "<cmd>cclose<CR>", opts)
    -- 'dd' to remove entry from quickfix list
    vim.keymap.set("n", "dd", function()
      local qf = vim.fn.getqflist()
      local cur_line = vim.api.nvim_win_get_cursor(0)[1]
      if #qf > 0 and cur_line <= #qf then
        table.remove(qf, cur_line)
        vim.fn.setqflist(qf, "r")
        if #qf == 0 then
          vim.cmd("cclose")
        else
          local new_line = math.min(cur_line, #qf)
          vim.api.nvim_win_set_cursor(0, { new_line, 0 })
        end
      end
    end, { buffer = buf, silent = true, desc = "Remove entry from quickfix" })

    -- Clean syntax highlights for column dividers and numbers
    vim.cmd([[
      syn match QfCustomDelimiter "│" containedin=ALL
      syn match QfCustomLineCol "\v\d+:\d+" containedin=ALL
      hi default link QfCustomDelimiter Delimiter
      hi default link QfCustomLineCol Number
    ]])
  end,
})
