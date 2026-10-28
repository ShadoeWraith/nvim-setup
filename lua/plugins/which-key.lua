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
            { "<leader>t", group = "Tabs / Workspaces" },
            { "<leader>to", desc = "Open Oil in New Tab" },
            { "<leader>e", desc = "Toggle Oil File Explorer" },
            { "<leader>q", desc = "Toggle Grep / Quickfix Window" },
            { "<leader>m", group = "Music / CAVA" },
            { "<leader>mr", desc = "Refresh CAVA Visualizer" },
            { "<leader>mp", desc = "Play / Pause Music" },
        })
    end,
}
