return {
    {
        "nvim-telescope/telescope.nvim",
        branch = "master",

        dependencies = {
            "nvim-lua/plenary.nvim",
        },

        keys = {
            {
                "<leader>ff",
                function()
                local root = vim.fs.root(0, { ".git", "ols.json" })
                or vim.fn.getcwd()

                require("telescope.builtin").find_files({
                    cwd = root,
                })
                end,
                desc = "Find Files (Project Root)",
            },

            {
                "<leader>fg",
                "<cmd>Telescope live_grep<CR>",
                desc = "Live Grep",
            },

            {
                "<leader>fb",
                "<cmd>Telescope buffers<CR>",
                desc = "Buffers",
            },

            {
                "<leader>fh",
                "<cmd>Telescope help_tags<CR>",
                desc = "Help Tags",
            },
        },

        config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        -- Custom Highlights matching terminal & workspace picker style
        vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = "#7aa2f7", bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = "#7aa2f7", bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { fg = "#7aa2f7", bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = "#7aa2f7", bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = "#ff9e64", bg = "NONE", bold = true })
        vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = "#7aa2f7", bg = "NONE", bold = true })
        vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = "#7aa2f7", bg = "NONE", bold = true })
        vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = "#ff9e64", bg = "#1f2335", bold = true })

        local function smart_file_jump(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if not selection then
            return
            end

            local filename = selection.path or selection.filename
            if not filename then
                return
                end

                local full_path = vim.fn.fnamemodify(filename, ":p")

                -- Reuse an existing window if the file is already open
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local buf_name = vim.api.nvim_buf_get_name(buf)

                    if buf_name ~= ""
                        and vim.fn.fnamemodify(buf_name, ":p") == full_path then
                        vim.api.nvim_set_current_win(win)
                        return
                        end
                        end

                        vim.cmd("edit " .. vim.fn.fnameescape(full_path))
                        end

                        telescope.setup({
                            defaults = {
                                prompt_prefix = "  ",
                                selection_caret = "  ",
                                entry_prefix = "  ",
                                initial_mode = "insert",
                                sorting_strategy = "descending",
                                layout_strategy = "horizontal",
                                borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },

                                -- Prevent the Telescope preview Tree-sitter crash
                                preview = {
                                    treesitter = false,
                                },

                                layout_config = {
                                    horizontal = {
                                        prompt_position = "bottom",
                                        preview_width = 0.55,
                                        results_width = 0.8,
                                    },
                                    width = 0.87,
                                    height = 0.80,
                                    preview_cutoff = 120,
                                },

                                mappings = {
                                    i = {
                                        ["<CR>"] = smart_file_jump,
                                        ["<C-n>"] = actions.move_selection_next,
                                        ["<C-p>"] = actions.move_selection_previous,
                                        ["<C-c>"] = actions.close,
                                    },

                                    n = {
                                        ["<CR>"] = smart_file_jump,
                                        ["q"] = actions.close,
                                    },
                                },
                            },

                            pickers = {
                                find_files = {
                                    hidden = true,
                                    no_ignore = true,
                                },
                            },
                        })
                        end,
    },
}
