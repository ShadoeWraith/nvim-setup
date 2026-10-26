return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
    local custom_theme = {
        normal = {
            a = { fg = "#ff9e64", bg = "NONE", gui = "bold" },
            b = { fg = "#7aa2f7", bg = "NONE" },
            c = { fg = "#c0caf5", bg = "NONE" },
        },
        insert = {
            a = { fg = "#7aa2f7", bg = "NONE", gui = "bold" },
            b = { fg = "#7aa2f7", bg = "NONE" },
            c = { fg = "#c0caf5", bg = "NONE" },
        },
        visual = {
            a = { fg = "#bb9af7", bg = "NONE", gui = "bold" },
            b = { fg = "#7aa2f7", bg = "NONE" },
            c = { fg = "#c0caf5", bg = "NONE" },
        },
        command = {
            a = { fg = "#e0af68", bg = "NONE", gui = "bold" },
            b = { fg = "#7aa2f7", bg = "NONE" },
            c = { fg = "#c0caf5", bg = "NONE" },
        },
        inactive = {
            a = { fg = "#414868", bg = "NONE" },
            b = { fg = "#414868", bg = "NONE" },
            c = { fg = "#414868", bg = "NONE" },
        },
    }

    require("lualine").setup({
        options = {
            icons_enabled = true,
            theme = custom_theme,
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            globalstatus = true,
        },
    })

    -- Force statusline backgrounds to be completely transparent
    vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
    end,
}
