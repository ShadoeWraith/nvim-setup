vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.timeoutlen = 300

-- Disable built-in netrw completely
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Completely disable the bottom status line across all panes
vim.opt.laststatus = 0

-- Disable the default window bar globally
vim.opt.winbar = ""

-- Disable swap files and backups to prevent "file open elsewhere" false positives
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Polished Diagnostics Styling & Configuration
vim.diagnostic.config({
    virtual_text = {
        prefix = "●",
        spacing = 4,
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "✕",
            [vim.diagnostic.severity.WARN]  = "⚠",
            [vim.diagnostic.severity.INFO]  = "ℹ",
            [vim.diagnostic.severity.HINT]  = "💡",
        },
    },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
    },
})
