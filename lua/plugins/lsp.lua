-- ============================================================================
-- Modern LSP Configuration (Mason + Native vim.lsp.config + nvim-cmp)
-- ============================================================================

return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local cmp = require("cmp")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- Configure nvim-cmp completion and documentation windows with clean transparent borders
            cmp.setup({
                window = {
                    completion = cmp.config.window.bordered({
                        border = "rounded",
                        winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
                    }),
                    documentation = cmp.config.window.bordered({
                        border = "rounded",
                        winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
                    }),
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                }),
            })

            -- Force transparent background and clean borders for all floating elements & code blocks
            local function apply_transparency()
                vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", fg = "NONE" })
                vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#7aa2f7", bg = "NONE" })
                vim.api.nvim_set_hl(0, "@markup.raw", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "@markup.code", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "markdownCode", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "markdownCodeBlock", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "LspKindColor", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "CmpItemKindColor", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "TailwindColor", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "Colorizer", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "HexColor", { bg = "NONE" })
                vim.api.nvim_set_hl(0, "CSSColor", { bg = "NONE" })

                for _, group in ipairs(vim.fn.getcompletion("", "highlight")) do
                    if group:match("Color") or group:match("Tailwind") then
                        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
                        if ok and hl and hl.bg then
                            vim.api.nvim_set_hl(0, group, { fg = hl.fg, bg = "NONE" })
                        end
                    end
                end
            end
            apply_transparency()

            vim.api.nvim_create_autocmd("ColorScheme", {
                callback = apply_transparency,
            })

            -- Automatically disable cursorline and enforce transparency in all floating windows
            vim.api.nvim_create_autocmd("WinEnter", {
                callback = function()
                    local win = vim.api.nvim_get_current_win()
                    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative ~= "" then
                        vim.wo[win].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:NormalFloat"
                        vim.wo[win].cursorline = false
                    end
                end,
            })

            -- Modern Native LSP Config API (Neovim 0.11+) replacing deprecated vim.lsp.with() and lspconfig framework
            vim.lsp.config("ols", {
                cmd = { "/usr/bin/ols" },
                filetypes = { "odin" },
                capabilities = capabilities,
                root_markers = { "ols.json", ".git" },
            })
            vim.lsp.enable("ols")
            vim.lsp.config("clangd", {
                cmd = { "clangd", "--background-index", "--clang-tidy" },
                filetypes = { "c", "cpp", "objc", "objcpp" },
                capabilities = capabilities,
                root_markers = { "compile_commands.json", "compile_flags.txt", ".git" },
            })
            vim.lsp.enable("clangd")

            vim.lsp.config("tailwindcss", {
                cmd = { "tailwindcss-language-server", "--stdio" },
                filetypes = { "html", "jsx", "tsx", "typescript", "typescriptreact" },
                capabilities = capabilities,
                root_markers = { "tailwind.config.js", "tailwind.config.ts", "package.json", ".git" },
                settings = {
                    tailwindCSS = {
                        classAttributes = { "class", "className", "tw", "css" },
                        validate = true,
                    },
                },
            })
            vim.lsp.enable("tailwindcss")

            -- Buffer-local keymaps and modern non-deprecated UI options on LspAttach
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    local opts = { buffer = args.buf }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "K", function()
                        vim.lsp.buf.hover({
                            border = "rounded",
                            max_width = 80,
                            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
                        })
                    end, opts)
                    vim.keymap.set("i", "<C-k>", function()
                        vim.lsp.buf.signature_help({
                            border = "rounded",
                            max_width = 80,
                            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
                        })
                    end, opts)
                end,
            })
        end,
    },
}
