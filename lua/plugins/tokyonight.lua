return {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,

    opts = {
        transparent = true,
    },

    config = function(_, opts)
    require("tokyonight").setup(opts)

    -- Restore your original theme variant
    vim.cmd.colorscheme("tokyonight-night")

    -- Active tab
    vim.api.nvim_set_hl(0, "TabLineSel", {
        fg = "#7aa2f7",
        bg = "#16161e",
    })

    -- Inactive tabs
    vim.api.nvim_set_hl(0, "TabLine", {
        fg = "#7aa2f7",
        bg = "#1f2335",
        bold = true,
    })

    -- Transparent empty tabline space
    vim.api.nvim_set_hl(0, "TabLineFill", {
        bg = "NONE",
    })
    end,
}
