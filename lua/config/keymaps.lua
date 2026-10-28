-- Line & selection movement using Alt + j/k
vim.keymap.set("n", "<M-j>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
vim.keymap.set("v", "<M-j>", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
vim.keymap.set("n", "<M-k>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })
vim.keymap.set("v", "<M-k>", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })

-- Insert mode exit
vim.keymap.set("i", "jj", "<ESC>", { silent = true })
vim.keymap.set('n', '<leader>ch', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlights' })

-- Disable default Vim Ctrl-w s horizontal split to prevent accidental splits
vim.keymap.set({'n', 'v', 'i'}, '<C-w>s', '<Nop>', { silent = true, desc = "Disable Ctrl-w s split" })
vim.keymap.set({'n', 'v', 'i'}, '<C-w><C-s>', '<Nop>', { silent = true, desc = "Disable Ctrl-w Ctrl-s split" })

-- Save file with Ctrl + s
vim.keymap.set({'n', 'i', 'v'}, '<C-s>', function()
    if vim.fn.mode() == 'i' then
        vim.cmd('stopinsert')
    end
    vim.cmd('silent! update')
    print("File saved!")
end, { silent = true, desc = "Save file" })

vim.keymap.set('n', '<leader>tc', ':tabclose<CR>', { desc = "Close current workspace tab" })

-- Cycle through native tab workspaces using Shift + h and Shift + l
vim.keymap.set('n', '<S-h>', 'gT', { desc = "Previous workspace tab" })
vim.keymap.set('n', '<S-l>', 'gt', { desc = "Next workspace tab" })

-- Reorder workspaces
vim.keymap.set('n', '<leader>tr', ':tabmove +1<CR>', { desc = "Move workspace right" })
vim.keymap.set('n', '<leader>tl', ':tabmove -1<CR>', { desc = "Move workspace left" })

-- Keymap to open Oil in a new tab at the current file's directory
vim.keymap.set("n", "<leader>to", function()
    local current_dir = vim.fn.expand("%:p:h")
    vim.cmd("tabnew")
    require("oil").open(current_dir)
end, { desc = "Open Oil in a new tab" })

-- Jump directly to workspace 1-9
for i = 1, 9 do
    vim.keymap.set('n', '<leader>' .. i, i .. 'gt', { desc = "Goto workspace " .. i })
end

-- Ergonomic line-boundary shortcuts (avoiding the number row)
vim.keymap.set('n', '<leader>h', '^', { desc = "First non-blank character" })
vim.keymap.set('n', '<leader>l', '$', { desc = "End of line" })

-- Helper functions for spatial layout resizing
local function resize_width(direction)
    local has_left = vim.fn.winnr('h') ~= vim.fn.winnr()
    local step = 3
    local delta = direction == "left" and (has_left and step or -step) or (has_left and -step or step)
    vim.cmd("vertical resize " .. (delta > 0 and "+" or "") .. delta)
end

local function resize_height(direction)
    local has_above = vim.fn.winnr('k') ~= vim.fn.winnr()
    local step = 3
    local delta = direction == "up" and (has_above and step or -step) or (has_above and -step or step)
    vim.cmd("resize " .. (delta > 0 and "+" or "") .. delta)
end

-- Safe Spatial Resizing (Arrows only, freeing up Alt-h/l for terminals)
vim.keymap.set('n', '<M-Left>', function() resize_width("left") end, { desc = "Spatial resize left" })
vim.keymap.set('n', '<M-Right>', function() resize_width("right") end, { desc = "Spatial resize right" })
vim.keymap.set('n', '<M-Up>', function() resize_height("up") end, { desc = "Spatial resize up" })
vim.keymap.set('n', '<M-Down>', function() resize_height("down") end, { desc = "Spatial resize down" })

-- Move current tab left/right
vim.keymap.set("n", "<leader>th", ":tabmove -1<CR>", { silent = true, desc = "Move tab left" })
vim.keymap.set("n", "<leader>tl", ":tabmove +1<CR>", { silent = true, desc = "Move tab right" })

vim.keymap.set('n', '<leader>df', function()
    require('telescope.builtin').lsp_document_symbols({
        symbols = { "function", "method", "Procedure" },
    })
end, { desc = "Find functions in current file" })

-- Pressing Tab in visual mode auto-indents selection to the proper spot and stays in visual mode
vim.keymap.set("v", "<Tab>", "=", { desc = "Auto-indent selection to proper spot and stay in visual mode" })
vim.keymap.set("v", "<S-Tab>", "<", { desc = "Outdent and stay in visual mode" })
