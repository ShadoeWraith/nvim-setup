return {
    'stevearc/oil.nvim',
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local oil = require("oil")

        local function normalize_path(path)
            if not path then return nil end
            local p = vim.fs.normalize(path)
            return p:gsub("/+$", "")
        end

        -- Find if a file is already open in another tabpage
        local function find_tab_for_file(filepath)
            local target = normalize_path(filepath)
            if not target then return nil, nil end
            local cur_tab = vim.api.nvim_get_current_tabpage()
            for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
                if tab ~= cur_tab and vim.api.nvim_tabpage_is_valid(tab) then
                    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
                        if vim.api.nvim_win_is_valid(win) then
                            local buf = vim.api.nvim_win_get_buf(win)
                            local bname = vim.api.nvim_buf_get_name(buf)
                            if bname ~= "" and normalize_path(bname) == target then
                                return tab, win
                            end
                        end
                    end
                end
            end
            return nil, nil
        end

        -- Custom TokyoNight-aligned color palette for Oil
        local function set_oil_highlights()
            vim.api.nvim_set_hl(0, "OilDir", { fg = "#7aa2f7", bold = true })
            vim.api.nvim_set_hl(0, "OilDirIcon", { fg = "#7dcfff" })
            vim.api.nvim_set_hl(0, "OilSocket", { fg = "#bb9af7" })
            vim.api.nvim_set_hl(0, "OilLink", { fg = "#73daca", underline = true })
            vim.api.nvim_set_hl(0, "OilFile", { fg = "#c0caf5" })
            vim.api.nvim_set_hl(0, "OilHidden", { fg = "#565f89", italic = true })
            vim.api.nvim_set_hl(0, "OilPermRead", { fg = "#9ece6a" })
            vim.api.nvim_set_hl(0, "OilPermWrite", { fg = "#e0af68" })
            vim.api.nvim_set_hl(0, "OilPermExec", { fg = "#f7768e", bold = true })
            vim.api.nvim_set_hl(0, "OilSize", { fg = "#2ac3de" })
            vim.api.nvim_set_hl(0, "OilMtime", { fg = "#565f89" })
        end

        set_oil_highlights()
        vim.api.nvim_create_autocmd("ColorScheme", {
            callback = set_oil_highlights,
        })

        oil.setup({
            default_file_explorer = true,
            skip_confirm_for_simple_edits = true,
            watch_for_changes = true,
            columns = {
                {
                    "permissions",
                    highlight = function(perm)
                        if perm:find("x") then
                            return "OilPermExec"
                        elseif perm:find("w") then
                            return "OilPermWrite"
                        else
                            return "OilPermRead"
                        end
                    end,
                },
                {
                    "size",
                    highlight = "OilSize",
                },
                {
                    "mtime",
                    highlight = "OilMtime",
                    format = "%b %d %I:%M %p",
                },
                "icon",
            },
            view_options = {
                show_hidden = true,
            },
            use_default_keymaps = true,
            keymaps = {
                ["<C-s>"] = {
                    callback = function()
                        if vim.fn.mode() == "i" then
                            vim.cmd("stopinsert")
                        end
                        oil.save()
                    end,
                    desc = "Save Oil edits without splitting",
                },
                ["<Esc>"] = {
                    callback = function()
                        local cur_tab = vim.api.nvim_get_current_tabpage()
                        local is_tab_created = vim.t[cur_tab].is_oil_tab
                        local prev_tab = vim.t[cur_tab].oil_prev_tab
                        local prev_buf = vim.b.oil_prev_buf

                        if is_tab_created and #vim.api.nvim_list_tabpages() > 1 then
                            pcall(vim.cmd, "tabclose")
                            if prev_tab and vim.api.nvim_tabpage_is_valid(prev_tab) then
                                pcall(vim.api.nvim_set_current_tabpage, prev_tab)
                            end
                        else
                            if prev_buf and vim.api.nvim_buf_is_valid(prev_buf) then
                                vim.api.nvim_win_set_buf(0, prev_buf)
                            else
                                vim.cmd("b#")
                            end
                        end
                    end,
                    desc = "Close Oil and return to previous file",
                },
                ["<CR>"] = {
                    callback = function()
                        local entry = oil.get_cursor_entry()
                        if entry and entry.type == "file" then
                            local current_dir = oil.get_current_dir()
                            if current_dir then
                                local file_path = vim.fs.joinpath(current_dir, entry.name)
                                local existing_tab, existing_win = find_tab_for_file(file_path)
                                if existing_tab then
                                    local cur_tab = vim.api.nvim_get_current_tabpage()
                                    local is_tab_created = vim.t[cur_tab].is_oil_tab
                                    local prev_buf = vim.b.oil_prev_buf
                                    if prev_buf and vim.api.nvim_buf_is_valid(prev_buf) then
                                        vim.api.nvim_win_set_buf(0, prev_buf)
                                    elseif is_tab_created and #vim.api.nvim_list_tabpages() > 1 then
                                        pcall(vim.cmd, "tabclose")
                                    else
                                        vim.cmd("b#")
                                    end
                                    pcall(vim.api.nvim_set_current_tabpage, existing_tab)
                                    if existing_win and vim.api.nvim_win_is_valid(existing_win) then
                                        pcall(vim.api.nvim_set_current_win, existing_win)
                                    end
                                    return
                                end
                            end
                        end
                        oil.select()
                    end,
                    desc = "Open file or switch to tab if already open",
                },
            },
        })

        -- <leader>e: Toggle Oil in the CURRENT window as a temporary directory view
        vim.keymap.set("n", "<leader>e", function()
            local ft = vim.bo.filetype
            if ft == "oil" then
                local prev_buf = vim.b.oil_prev_buf
                if prev_buf and vim.api.nvim_buf_is_valid(prev_buf) then
                    vim.api.nvim_win_set_buf(0, prev_buf)
                else
                    vim.cmd("b#")
                end
            else
                local cur_buf = vim.api.nvim_get_current_buf()
                oil.open(nil, nil, function()
                    local oil_buf = vim.api.nvim_get_current_buf()
                    if vim.bo[oil_buf].filetype == "oil" then
                        vim.b[oil_buf].oil_prev_buf = cur_buf
                    end
                end)
            end
        end, { desc = "Toggle Oil file explorer in current window" })

        -- <leader>to: Open Oil in a brand-new workspace tab
        vim.keymap.set("n", "<leader>to", function()
            local prev_tab = vim.api.nvim_get_current_tabpage()
            local current_dir = vim.fn.expand("%:p:h")
            if current_dir == "" then
                current_dir = vim.fn.getcwd()
            end
            vim.cmd("tabnew")
            local new_tab = vim.api.nvim_get_current_tabpage()
            vim.t[new_tab].is_oil_tab = true
            vim.t[new_tab].oil_prev_tab = prev_tab

            oil.open(current_dir)
        end, { desc = "Open Oil in a new tab workspace" })
    end,
}
