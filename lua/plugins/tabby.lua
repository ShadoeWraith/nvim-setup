return {
    "nanozuki/tabby.nvim",
    event = "VimEnter",
    dependencies = "nvim-web-devicons",
    config = function()
        vim.opt.showtabline = 2

        local theme = {
            fill = { bg = "#16161d", fg = "#414868" },
            head = { bg = "#16161d", fg = "#7aa2f7", style = "bold" },
            current_tab = { bg = "#16161d", fg = "#ff9e64", style = "bold" },
            tab = { bg = "#16161d", fg = "#414868" },
        }

        local function get_song_info()
            local handle_status = io.popen("mpc status 2>/dev/null")
            local status_output = handle_status and handle_status:read("*a") or ""
            if handle_status then handle_status:close() end
            local is_paused = status_output:match("%[paused%]") ~= nil

            local handle_song = io.popen("mpc current 2>/dev/null")
            local song = handle_song and vim.trim(handle_song:read("*a") or "") or ""
            if handle_song then handle_song:close() end

            local max_len = 35
            if #song > max_len then
                song = song:sub(1, max_len - 3) .. "..."
            end

            return song, is_paused
        end

        local devicons = require("nvim-web-devicons")

        -- Safe Tab Namer & Icon resolver with strict type validation for win IDs
        local function get_clean_tab_info(tab)
            local ok, win = pcall(tab.current_win)
            if not ok or not win then
                local fallback_name = tab.name()
                return fallback_name, nil, nil
            end

            -- Ensure win is handled safely whether it's returned as a number or object wrapper
            local win_id = type(win) == "number" and win or (win.id or tonumber(tostring(win)))
            if win_id and vim.api.nvim_win_is_valid(win_id) then
                local buf = vim.api.nvim_win_get_buf(win_id)
                if vim.api.nvim_buf_is_valid(buf) then
                    local bt = vim.bo[buf].buftype
                    local ft = vim.bo[buf].filetype
                    local fname = vim.api.nvim_buf_get_name(buf)

                    if bt == "terminal" then
                        local wins_ok, wins = pcall(tab.wins)
                        if wins_ok and wins then
                            for _, w in ipairs(wins) do
                                local w_id = type(w) == "number" and w or (w.id or tonumber(tostring(w)))
                                if w_id and w_id ~= win_id and vim.api.nvim_win_is_valid(w_id) then
                                    local b = vim.api.nvim_win_get_buf(w_id)
                                    local wb = vim.bo[b].buftype
                                    local wf = vim.bo[b].filetype
                                    local wname = vim.api.nvim_buf_get_name(b)
                                    if wb ~= "terminal" and wf ~= "oil" and wname ~= "" and not wname:match("^oil://") then
                                        local filename = vim.fn.fnamemodify(wname, ":t")
                                        local ext = vim.fn.fnamemodify(wname, ":e")
                                        local icon, icon_color = devicons.get_icon_color(filename, ext, { default = true })
                                        return filename, icon, icon_color
                                    end
                                end
                            end
                        end
                        return "[Terminal]", "", "#7aa2f7"
                    elseif ft == "oil" or fname:match("^oil://") then
                        local dir = fname:match("^oil://(.*)") or fname
                        local dirname = vim.fn.fnamemodify(dir:gsub("/+$", ""), ":t")
                        if dirname == "" then dirname = "[Directory Explorer]" end
                        return dirname, "", "#7aa2f7"
                    elseif fname ~= "" then
                        local filename = vim.fn.fnamemodify(fname, ":t")
                        local ext = vim.fn.fnamemodify(fname, ":e")
                        local icon, icon_color = devicons.get_icon_color(filename, ext, { default = true })
                        return filename, icon, icon_color
                    end
                end
            end
            local raw_name = tab.name()
            local ext = vim.fn.fnamemodify(raw_name, ":e")
            local icon, icon_color = devicons.get_icon_color(raw_name, ext, { default = true })
            return raw_name, icon, icon_color
        end

        require("tabby").setup({
            line = function(line)
                local song, is_paused = get_song_info()
                local song_hl = is_paused and theme.tab or theme.head

                return {
                    line.tabs().foreach(function(tab)
                        local hl = tab.is_current() and theme.current_tab or theme.tab
                        local name, icon, icon_color = get_clean_tab_info(tab)
                        local icon_component = icon and {
                            icon .. " ",
                            hl = { fg = icon_color or hl.fg, bg = hl.bg },
                        } or ""

                        return {
                            tab.is_current() and "▎ " or "  ",
                            icon_component,
                            name,
                            "  ",
                            hl = hl,
                        }
                    end),
                    line.spacer(),
                    song ~= "" and { { "  " .. song .. " ", hl = song_hl } } or {},
                    hl = theme.fill,
                }
            end,
        })

        -- Global Music Control Keybinds
        vim.keymap.set('n', '<leader>mp', function()
            os.execute("mpc toggle >/dev/null 2>&1")
            vim.cmd("redrawtabline")
        end, { desc = "Music Play/Pause" })

        vim.keymap.set('n', '<leader>m.', function()
            os.execute("mpc volume +5 >/dev/null 2>&1")
        end, { desc = "Music Volume Up" })

        vim.keymap.set('n', '<leader>m,', function()
            os.execute("mpc volume -5 >/dev/null 2>&1")
        end, { desc = "Music Volume Down" })

        vim.keymap.set('n', '<leader>m>', function()
            os.execute("mpc next >/dev/null 2>&1")
            vim.cmd("redrawtabline")
        end, { desc = "Music Next Song" })

        vim.keymap.set('n', '<leader>m<', function()
            os.execute("mpc prev >/dev/null 2>&1")
            vim.cmd("redrawtabline")
        end, { desc = "Music Previous Song" })
    end,
}
