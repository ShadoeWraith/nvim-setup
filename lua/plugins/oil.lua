return {
    'stevearc/oil.nvim',
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("oil").setup({
            default_file_explorer = true,
            skip_confirm_for_simple_edits = true,
            view_options = {
                show_hidden = true,
            },
            -- Ensure selecting a file replaces the buffer in the current window in place
            use_default_keymaps = true,
            keymaps = {
                ["<CR>"] = "actions.select",
            },
        })

        -- <leader>e: Toggle Oil in the CURRENT window as a temporary directory view
        vim.keymap.set("n", "<leader>e", function()
            local ft = vim.bo.filetype
            if ft == "oil" then
                -- If already in oil, go back to previous buffer
                vim.cmd("b#")
            else
                -- Open oil right here in the active window
                require("oil").open()
            end
        end, { desc = "Toggle Oil file explorer in current window" })

        -- <leader>to: ONLY this keymap creates a brand-new workspace tab
        vim.keymap.set("n", "<leader>to", function()
            local current_dir = vim.fn.expand("%:p:h")
            vim.cmd("tabnew")
            require("oil").open(current_dir)
        end, { desc = "Open Oil in a new tab workspace" })
    end,
}
