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
        },
        config = function()
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        -- Native Neovim 0.11+ configuration using your custom /usr/bin/ols binary
        vim.lsp.config("ols", {
            cmd = { "/usr/bin/ols" },
            filetypes = { "odin" },
            capabilities = capabilities,
            root_markers = { "ols.json", ".git" },
        })
        vim.lsp.enable("ols")

        -- Buffer-local keymaps with explicit rounded borders for hover and signature help
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
            local opts = { buffer = args.buf }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "K", function()
            vim.lsp.buf.hover({ border = "rounded" })
            end, opts)
            vim.keymap.set("i", "<C-k>", function()
            vim.lsp.buf.signature_help({ border = "rounded" })
            end, opts)
            end,
        })
        end,
    },
}
