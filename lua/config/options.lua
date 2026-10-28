vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.timeoutlen = 300
vim.opt.wrap = false
vim.opt.sidescroll = 1
vim.opt.sidescrolloff = 8
vim.opt.mouse = 'a'

-- Use Neovim's modern core Treesitter folding engine (FIXED)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Keep folds open by default when opening a file (otherwise everything collapses)
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- Disable built-in netrw completely
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Clean session options (exclude blank so placeholder plugin splits don't get saved)
vim.opt.sessionoptions = { "buffers", "curdir", "folds", "help", "tabpages", "winsize", "terminal" }

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

-- 1. Ensure conceal level is active (1 hides chars, 2 replaces them with conceal char)
vim.opt.conceallevel = 2
vim.opt.concealcursor = "nc" -- Keeps concealment active even on the current line unless you are in insert mode

-- 2. Define a custom autocmd that applies a Treesitter query for TSX/JSX
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "typescriptreact", "javascriptreact" },
    callback = function(args)
        -- Create a local-to-buffer inline conceal query for string contents inside className
        local query_string = [[
            (jsx_attribute
              (property_identifier) @prop (#eq? @prop "className")
              value: (string (string_fragment) @string_content))
        ]]

        -- Fallback parser check for TSX / Typescript
        local ok, query = pcall(vim.treesitter.query.parse, "typescriptreact", query_string)
        if not ok then
            ok, query = pcall(vim.treesitter.query.parse, "tsx", query_string)
            if not ok then return end
        end

        -- Apply the conceal directive via an extmark loop on render
        vim.api.nvim_create_autocmd({ "CursorHold", "BufEnter", "InsertLeave" }, {
            buffer = args.buf,
            callback = function()
                local parser = vim.treesitter.get_parser(args.buf)
                if not parser then return end
                local tree = parser:parse()[1]
                if not tree then return end

                for id, node, _ in query:iter_captures(tree:root(), args.buf, 0, -1) do
                    if query.captures[id] == "string_content" then
                        local start_row, start_col, end_row, end_col = node:range()
                        -- Only conceal if the string is actually long (> 20 chars)
                        if (end_col - start_col) > 20 then
                            vim.api.nvim_buf_set_extmark(args.buf, vim.api.nvim_create_namespace("tailwind_conceal"), start_row, start_col, {
                                end_row = end_row,
                                end_col = end_col,
                                conceal = "…",
                            })
                        end
                    end
                end
            end,
        })
    end,
})

-- Style the ellipsis badge color to match your theme (subtle blue/cyan)
vim.api.nvim_set_hl(0, "Conceal", { fg = "#38BDF8", bg = "NONE" })
