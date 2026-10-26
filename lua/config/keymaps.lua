-- General QoL keymaps
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = "Show line diagnostic" })

-- Line & selection movement using Alt + j/k
vim.keymap.set("n", "<M-j>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
vim.keymap.set("v", "<M-j>", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
vim.keymap.set("n", "<M-k>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })
vim.keymap.set("v", "<M-k>", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })

-- Insert mode exit
vim.keymap.set("i", "jj", "<ESC>", { silent = true })

-- Save file with Ctrl + s
vim.keymap.set({'n', 'i', 'v'}, '<C-s>', function()
if vim.fn.mode() == 'i' then
    vim.cmd('stopinsert')
    end
    vim.cmd('w')
    print("File saved!")
    end, { silent = true, desc = "Save file" })

-- Workspace / Tab Page Management (tabby.nvim native tabs)
vim.keymap.set('n', '<leader>to', function()
vim.cmd("tabnew")
require("telescope.builtin").find_files()
end, { desc = "Open new workspace tab and find files" })

vim.keymap.set('n', '<leader>tc', ':tabclose<CR>', { desc = "Close current workspace tab" })

-- Cycle through native tab workspaces using Shift + h and Shift + l
vim.keymap.set('n', '<S-h>', 'gT', { desc = "Previous workspace tab" })
vim.keymap.set('n', '<S-l>', 'gt', { desc = "Next workspace tab" })

-- Reorder workspaces
vim.keymap.set('n', '<leader>tr', ':tabmove +1<CR>', { desc = "Move workspace right" })
vim.keymap.set('n', '<leader>tl', ':tabmove -1<CR>', { desc = "Move workspace left" })

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

    -- Map Alt + h/l and Left/Right arrows for Width
    vim.keymap.set('n', '<M-h>', function() resize_width("left") end, { desc = "Spatial resize left" })
    vim.keymap.set('n', '<M-l>', function() resize_width("right") end, { desc = "Spatial resize right" })
    vim.keymap.set('n', '<M-Left>', function() resize_width("left") end, { desc = "Spatial resize left" })
    vim.keymap.set('n', '<M-Right>', function() resize_width("right") end, { desc = "Spatial resize right" })

    -- Map Alt + Up/Down arrows for Height (leaving j/k free for line movement)
    vim.keymap.set('n', '<M-Up>', function() resize_height("up") end, { desc = "Spatial resize up" })
    vim.keymap.set('n', '<M-Down>', function() resize_height("down") end, { desc = "Spatial resize down" })

    -- Move current tab left
    vim.keymap.set("n", "<leader>th", ":tabmove -1<CR>", { silent = true, desc = "Move tab left" })

    -- Move current tab right
    vim.keymap.set("n", "<leader>tl", ":tabmove +1<CR>", { silent = true, desc = "Move tab right" })
