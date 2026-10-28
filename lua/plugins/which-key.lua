-- ============================================================================
-- Which-Key Configuration (folke/which-key.nvim)
-- ============================================================================

return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        delay = 300,
        win = {
            border = "rounded",
            wo = {
                winblend = 10,
            },
        },
        icons = {
            breadcrumb = "»",
            separator = "➜",
            group = "+",
        },
    },
    config = function(_, opts)
        local wk = require("which-key")
        wk.setup(opts)

        -- Register your custom leader key groups and descriptions
        wk.add({
            { "<leader>t", group = "Terminal / Tabs" },
            { "<leader>tt", desc = "Toggle Global Singleton Terminal" },
            { "<leader>ww", desc = "Shuttle / Toggle Terminal Focus" },
            { "<leader>tq", desc = "Kill Terminal Completely" },
            { "<leader>to", desc = "Open Oil in New Tab" },
            { "<leader>e", desc = "Toggle Oil File Explorer" },
        })
    end,
}
