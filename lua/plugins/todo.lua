return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        signs = true,

        highlight = {
            multiline = false,
            comments_only = false, -- Matches keywords globally even if tree-sitter hasn't processed them yet
            max_line_len = 400,

            keyword = "bg",        -- Colors the keyword background
            after = "bg",          -- Colors the full background strip of the text following it

            --  CORRECT VIM REGEX PATTERN (Matches keywords with or without a trailing colon)
            pattern = [[.*<(KEYWORDS)\>]],
        },

        -- Map your keywords to design colors
        keywords = {
            FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
            TODO = { icon = " ", color = "info" },
            WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
            NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        },

        -- Define your precise hex color overrides here
        colors = {
            error = { "#FF0000" },   -- Red
            warning = { "#FFA500" }, -- Orange
            info = { "#00FF00" },    -- Lime Green
            hint = { "#10B981" },    -- Mint Green
        },
    }
}
