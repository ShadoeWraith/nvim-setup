-- ============================================================================
-- Neovim Core Autocommands & Global Event Hooks
-- ============================================================================

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- 1. Comprehensive LSP Attach Keymaps
autocmd("LspAttach", {
    group = augroup("UserLspConfig", { clear = true }),
    callback = function(args)
        local opts = { buffer = args.buf }
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
    end,
})

-- 2. Forcefully banish the winbar globally across all events
vim.opt.winbar = ""
autocmd({ "WinNew", "WinEnter", "BufEnter", "BufWinEnter", "FileType", "LspAttach" }, {
    group = augroup("BanishWinbar", { clear = true }),
    callback = function()
        vim.opt_local.winbar = ""
    end,
})

-- 3. Automatically reload files if changed outside of Neovim
vim.opt.autoread = true
autocmd({ "FocusGained", "BufEnter", "CursorHold", "FileChangedShell" }, {
    group = augroup("AutoReadCheck", { clear = true }),
    callback = function()
        vim.cmd("checktime")
    end,
})

-- 4. Automatically enter insert/terminal mode when opening or focusing a terminal
autocmd({ "TermOpen", "BufEnter" }, {
    group = augroup("TerminalAutoInsert", { clear = true }),
    callback = function()
        if vim.bo.buftype == "terminal" then
            vim.cmd("startinsert")
        end
    end,
})

