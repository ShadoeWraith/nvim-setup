return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    keys = {
        {
            "<leader>ft",
            function()
            -- Close Neogit sidebar if open before toggling file tree
            for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.bo[buf].filetype == "NeogitStatus" then
                    vim.api.nvim_win_close(win, true)
                    end
                    end
                    vim.cmd("Neotree toggle")
                    end,
                    desc = "Toggle File Tree Sidebar",
        },
    },
    config = function()
    require("neo-tree").setup({
        close_if_last_window = true,
        enable_git_status = true,
        enable_diagnostics = false,
        sources = { "filesystem" },
        window = {
            position = "left",
            width = 40,
        },
        filesystem = {
            filtered_items = {
                visible = true,
                hide_dotfiles = false,
                hide_gitignored = false,
                never_show = { ".DS_Store", "thumbs.db" },
            },
            follow_current_file = { enabled = true },
            use_libuv_file_watcher = true,
        },
    })

    -- Clean transparent styling matching terminal and cmp style
    vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { fg = "#7aa2f7", bg = "NONE" })
    vim.api.nvim_set_hl(0, "NeoTreeCursorLine", { fg = "#ff9e64", bold = true })
    vim.api.nvim_set_hl(0, "NeoTreeGitIgnored", { fg = "#414868", italic = true })
    end,
}
