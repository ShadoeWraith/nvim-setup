return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        win = {
            border = "rounded",
        },
    },
    config = function(_, opts)
    require("which-key").setup(opts)

    -- Match the transparent style with #7aa2f7 borders and #ff9e64 accents
    vim.api.nvim_set_hl(0, "WhichKeyNormal", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "WhichKeyBorder", { fg = "#7aa2f7", bg = "NONE" })
    vim.api.nvim_set_hl(0, "WhichKeyTitle", { fg = "#ff9e64", bg = "NONE", bold = true })
    vim.api.nvim_set_hl(0, "WhichKey", { fg = "#ff9e64" })
    end,
}
