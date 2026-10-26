return {
    "kdheepak/lazygit.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    keys = {
        { "<leader>gg", "<cmd>LazyGit<CR>", desc = "Toggle Lazygit Floating UI" },
    },
    config = function()
    -- Optional: customize lazygit integration behavior if needed
    vim.g.lazygit_floating_window_scaling_factor = 0.9
    end,
}
