return {
  "ellisonleao/glow.nvim",
  init = function()
    vim.keymap.set("n", "<leader>mp", function()
      -- Auto-save buffer so glow always reads your latest edits
      vim.cmd("silent! write")

      local file = vim.fn.expand("%")
      if file == "" then
        print("No file to preview")
        return
      end

      -- Calculate dimensions (80% of screen size)
      local width = math.floor(vim.o.columns * 0.8)
      local height = math.floor(vim.o.lines * 0.8)
      local row = math.floor((vim.o.lines - height) / 2)
      local col = math.floor((vim.o.columns - width) / 2)

      local buf = vim.api.nvim_create_buf(false, true)
      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = { { " Markdown Preview ", "TelescopePromptTitle" } },
        title_pos = "center",
        footer = { { " q: Close | j/k: Scroll ", "Comment" } },
        footer_pos = "center",
      })

      -- Pass the -p (pager) flag so glow stays open and interactive
      vim.fn.termopen("glow -p " .. vim.fn.shellescape(file))
      vim.cmd("startinsert")

      -- Clean exit mapping on 'q'
      vim.keymap.set("t", "q", "<C-\\><C-n>:q<CR>", { buffer = buf, silent = true })
    end, { desc = "Toggle Markdown Preview" })
  end,
  config = false,
  enabled = true,
}
