-- Terminal-Style File & Directory Management Commands

vim.opt.wildoptions = "pum"
vim.opt.pumblend = 10
vim.opt.pumheight = 10

-- Match your exact Telescope & Tokyo Night accent colors
vim.api.nvim_set_hl(0, "Pmenu", { bg = "#1f2335", fg = "#c0caf5" })
vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#364a82", fg = "#ff9e64", bold = true })
vim.api.nvim_set_hl(0, "PmenuSbar", { bg = "#1f2335" })
vim.api.nvim_set_hl(0, "PmenuThumb", { bg = "#7aa2f7" })

local function file_completer(arg_lead, cmd_line, cursor_pos)
  return vim.fn.getcompletion(arg_lead, "file")
end

local function file_completer(arg_lead, cmd_line, cursor_pos)
  return vim.fn.getcompletion(arg_lead, "file")
end

-- 1. Touch: Create file and automatically build missing parent directories (mkdir -p)
vim.api.nvim_create_user_command("Touch", function(opts)
  local path = opts.args
  local dir = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end, {
  nargs = 1,
  complete = file_completer,
})

-- 2. Mkdir: Create an empty directory (and parents) without opening any buffer
vim.api.nvim_create_user_command("Mkdir", function(opts)
  local path = opts.args
  if path == "" then
    print("No path provided")
    return
  end
  local full_path = vim.fn.fnamemodify(path, ":p")
  if vim.fn.isdirectory(full_path) == 0 then
    vim.fn.mkdir(full_path, "p")
    print("Created directory: " .. path)
  else
    print("Directory already exists: " .. path)
  end
end, {
  nargs = 1,
  complete = file_completer,
})

-- 3. Rm: Recursively remove files/directories with a safety prompt and buffer cleanup
vim.api.nvim_create_user_command("Rm", function(opts)
  local path = opts.args
  if path == "" then
    print("No path provided")
    return
  end

  local full_path = vim.fn.fnamemodify(path, ":p")

  vim.ui.select({ "Yes", "No" }, {
    prompt = "Delete " .. path .. "?",
  }, function(choice)
    if choice ~= "Yes" then
      return
    end

    local success = os.execute("rm -rf " .. vim.fn.shellescape(full_path))
    if success == 0 or success == true then
      print("Removed: " .. path)

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf) == full_path then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
    else
      print("Failed to remove: " .. path)
    end
  end)
end, {
  nargs = 1,
  complete = file_completer,
})

-- 4. Mv: Move or rename files/directories with auto-mkdir and open buffer updates
vim.api.nvim_create_user_command("Mv", function(opts)
  local args = opts.fargs
  if #args < 2 then
    print("Usage: Mv <old_path> <new_path>")
    return
  end

  local src = args[1]
  local dst = args[2]
  local full_src = vim.fn.fnamemodify(src, ":p")
  local full_dst = vim.fn.fnamemodify(dst, ":p")

  local dest_dir = vim.fn.fnamemodify(full_dst, ":h")
  if vim.fn.isdirectory(dest_dir) == 0 then
    vim.fn.mkdir(dest_dir, "p")
  end

  local success = os.execute("mv " .. vim.fn.shellescape(full_src) .. " " .. vim.fn.shellescape(full_dst))
  if success == 0 or success == true then
    print("Moved: " .. src .. " -> " .. dst)

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(buf) == full_src then
        if buf == vim.api.nvim_get_current_buf() then
          vim.cmd("edit " .. vim.fn.fnameescape(full_dst))
        else
          vim.api.nvim_buf_set_name(buf, full_dst)
          vim.api.nvim_buf_call(buf, function()
            vim.cmd("silent! edit!")
          end)
        end
      end
    end
  else
    print("Failed to move: " .. src .. " -> " .. dst)
  end
end, {
  nargs = "+",
  complete = file_completer,
})

return {}
