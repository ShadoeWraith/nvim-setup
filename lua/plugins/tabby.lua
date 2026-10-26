return {
    "nanozuki/tabby.nvim",
    event = "VimEnter",
    dependencies = "nvim-web-devicons",
    config = function()
        vim.opt.showtabline = 2

        -- Resolve project directory and extract workspace name from folder basename
        local target_dir = vim.fn.getcwd()
        if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
            target_dir = vim.fn.fnamemodify(vim.fn.argv(0), ":p")
        end
        target_dir = vim.fn.fnamemodify(target_dir, ":p")

        local initial_ws_name = vim.fn.fnamemodify(target_dir:gsub("/+$", ""), ":t")
        if initial_ws_name == "" then initial_ws_name = "workspace" end

        -- Robustly scope the session file to the target project directory
        local function get_session_file()
            local dir = vim.fn.stdpath("data") .. "/workspaces"
            pcall(vim.fn.mkdir, dir, "p")

            local project_hash = vim.fn.sha256(target_dir):sub(1, 16)
            return string.format("%s/%s.json", dir, project_hash)
        end

        local workspaces = { [initial_ws_name] = { tabs = {}, path = target_dir } }
        local current_workspace = initial_ws_name

        local function load_session()
            local file_path = get_session_file()
            local f = io.open(file_path, "r")
            if not f then
                workspaces = { [initial_ws_name] = { tabs = {}, path = target_dir } }
                current_workspace = initial_ws_name
                return
            end
            local content = f:read("*a")
            f:close()
            local ok, data = pcall(vim.json.decode, content)
            
            if ok and data and data.workspaces and data.workspaces[initial_ws_name] then
                workspaces = data.workspaces
                current_workspace = data.current_workspace or initial_ws_name
                if not workspaces[current_workspace] then
                    current_workspace = initial_ws_name
                end
            else
                workspaces = { [initial_ws_name] = { tabs = {}, path = target_dir } }
                current_workspace = initial_ws_name
            end
        end

        load_session()

        local function get_sorted_workspaces()
            local choices = {}
            for name, _ in pairs(workspaces) do
                table.insert(choices, name)
            end
            table.sort(choices)
            return choices
        end

        local function save_current_workspace()
            local tabs_data = {}
            for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
                local tab_windows = {}
                local win_list = vim.api.nvim_tabpage_list_wins(tab)

                for idx, win in ipairs(win_list) do
                    if vim.api.nvim_win_is_valid(win) then
                        local win_config = vim.api.nvim_win_get_config(win)
                        if win_config.relative == "" then
                            local buf = vim.api.nvim_win_get_buf(win)
                            local name = vim.api.nvim_buf_get_name(buf)
                            local buftype = vim.bo[buf].buftype

                            if buftype == "" and name ~= "" and vim.fn.filereadable(name) == 1 then
                                local file_path = vim.fn.fnamemodify(name, ":p")
                                local split_type = "none"

                                if idx > 1 then
                                    local prev_win = win_list[idx - 1]
                                    if vim.api.nvim_win_is_valid(prev_win) then
                                        local prev_config = vim.api.nvim_win_get_config(prev_win)
                                        if prev_config.relative == "" then
                                            local cur_pos = vim.api.nvim_win_get_position(win)
                                            local prev_pos = vim.api.nvim_win_get_position(prev_win)
                                            if cur_pos[2] > prev_pos[2] then
                                                split_type = "vsplit"
                                            else
                                                split_type = "split"
                                            end
                                        end
                                    end
                                end

                                table.insert(tab_windows, {
                                    file = file_path,
                                    split = split_type,
                                })
                            end
                        end
                    end
                end

                if #tab_windows > 0 then
                    table.insert(tabs_data, tab_windows)
                end
            end

            if #tabs_data == 0 and workspaces[current_workspace] and workspaces[current_workspace].tabs and #workspaces[current_workspace].tabs > 0 then
                return
            end

            local current_buf = vim.api.nvim_get_current_buf()
            local active_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(current_buf), ":p")

            workspaces[current_workspace].tabs = tabs_data
            workspaces[current_workspace].active_file = active_file
            workspaces[current_workspace].path = vim.fn.getcwd()
        end

        local function save_session()
            save_current_workspace()
            local file_path = get_session_file()
            local data = {
                current_workspace = current_workspace,
                workspaces = workspaces,
            }
            local ok, encoded = pcall(vim.json.encode, data)
            if ok then
                local f = io.open(file_path, "w")
                if f then
                    f:write(encoded)
                    f:close()
                end
            end
        end

        local function switch_workspace(target_name, skip_save)
            if not workspaces[target_name] then return end
            if not skip_save then
                save_current_workspace()
            end

            local ws_path = workspaces[target_name].path
            if ws_path and vim.fn.isdirectory(ws_path) == 1 then
                vim.cmd.cd(ws_path)
            end

            while vim.fn.tabpagenr('$') > 1 do
                vim.cmd("tabclose!")
            end
            vim.cmd("only!")
            vim.cmd("enew!")

            current_workspace = target_name
            local ws_entry = workspaces[target_name]
            local target_tabs = ws_entry.tabs or {}
            local active_file = ws_entry.active_file

            if #target_tabs > 0 then
                for i, tab_windows in ipairs(target_tabs) do
                    if i > 1 then
                        vim.cmd("tabnew")
                    end
                    for j, win_data in ipairs(tab_windows) do
                        local file_path = type(win_data) == "table" and win_data.file or win_data
                        local split_type = type(win_data) == "table" and win_data.split or "none"

                        if j > 1 then
                            if split_type == "vsplit" then
                                vim.cmd("vsplit")
                            else
                                vim.cmd("split")
                            end
                        end
                        if file_path and vim.fn.filereadable(file_path) == 1 then
                            vim.cmd("edit " .. vim.fn.fnameescape(file_path))
                        end
                    end
                end

                if active_file and active_file ~= "" then
                    for _, win in ipairs(vim.api.nvim_list_wins()) do
                        local win_config = vim.api.nvim_win_get_config(win)
                        if win_config.relative == "" then
                            local buf = vim.api.nvim_win_get_buf(win)
                            local name = vim.api.nvim_buf_get_name(buf)
                            if vim.fn.fnamemodify(name, ":p") == active_file then
                                vim.api.nvim_set_current_win(win)
                                break
                            end
                        end
                    end
                end
            else
                vim.cmd("enew!")
            end

            save_session()

            pcall(function()
                require("config.player").start_mini()
            end)
        end

        vim.schedule(function()
            local ws_entry = workspaces[current_workspace]
            if ws_entry and ws_entry.path and vim.fn.isdirectory(ws_entry.path) == 1 then
                vim.cmd.cd(ws_entry.path)
            end
            if ws_entry and ws_entry.tabs and #ws_entry.tabs > 0 then
                switch_workspace(current_workspace, true)
            end
        end)

        local theme = {
            fill = { bg = "#16161d", fg = "#414868" },
            head = { bg = "#16161d", fg = "#7aa2f7", style = "bold" },
            current_tab = { bg = "#16161d", fg = "#ff9e64", style = "bold" },
            tab = { bg = "#16161d", fg = "#414868" },
        }

        require("tabby").setup({
            line = function(line)
                local choices = get_sorted_workspaces()
                local current_idx = 1
                for idx, name in ipairs(choices) do
                    if name == current_workspace then
                        current_idx = idx
                        break
                    end
                end

                return {
                    {
                        { " [" .. current_idx .. ": " .. current_workspace .. "] ", hl = theme.head },
                    },
                    line.tabs().foreach(function(tab)
                        local hl = tab.is_current() and theme.current_tab or theme.tab
                        return {
                            tab.is_current() and "▎ " or "  ",
                            tab.name(),
                            "  ",
                            hl = hl,
                        }
                    end),
                    line.spacer(),
                    hl = theme.fill,
                }
            end,
        })

        local function get_workspace_files(ws_name)
            local files = {}
            local seen = {}
            local ws_entry = workspaces[ws_name]
            if not ws_entry then return { "(No files in workspace)" } end

            local target_tabs = ws_entry.tabs or {}
            for _, tab_windows in ipairs(target_tabs) do
                for _, win_data in ipairs(tab_windows) do
                    local file_path = type(win_data) == "table" and win_data.file or win_data
                    if file_path then
                        local relpath = vim.fn.fnamemodify(file_path, ":.")
                        if not seen[relpath] then
                            seen[relpath] = true
                            table.insert(files, relpath)
                        end
                    end
                end
            end

            if #files == 0 then
                table.insert(files, "(No files in workspace)")
            end
            return files
        end

        local function open_floating_input(title, default_text, callback)
            local width = 50
            local height = 1
            local col = math.floor((vim.o.columns - width) / 2)
            local row = math.floor((vim.o.lines - height) / 2)

            vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
            vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#7aa2f7", bg = "NONE" })
            vim.api.nvim_set_hl(0, "FloatTitle", { fg = "#7aa2f7", bg = "NONE", bold = true })
            vim.api.nvim_set_hl(0, "Pmenu", { bg = "#1f2335", fg = "#c0caf5" })
            vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#364a82", fg = "#7aa2f7", bold = true })

            local buf = vim.api.nvim_create_buf(false, true)
            local win = vim.api.nvim_open_win(buf, true, {
                relative = "editor",
                width = width,
                height = height,
                row = row,
                col = col,
                style = "minimal",
                border = "rounded",
                title = " " .. title .. " ",
                title_pos = "center",
                zindex = 200,
            })

            vim.wo[win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle"

            if default_text and default_text ~= "" then
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, { default_text })
                vim.fn.cursor(1, vim.fn.col("$"))
            end

            -- Buffer-local completion triggered strictly on <Tab>
            vim.keymap.set("i", "<Tab>", function()
                local line = vim.api.nvim_get_current_line()
                local completions = vim.fn.getcompletion(line, "file")
                if #completions > 0 then
                    vim.fn.complete(1, completions)
                end
            end, { buffer = buf, silent = true })

            local function confirm()
                local line = vim.api.nvim_get_current_line()
                local name = vim.trim(line)
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
                callback(name)
            end

            vim.keymap.set("i", "<CR>", confirm, { buffer = buf, silent = true })
            vim.keymap.set("n", "<CR>", confirm, { buffer = buf, silent = true })

            vim.keymap.set("i", "<Esc>", function()
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
            end, { buffer = buf, silent = true })
            vim.keymap.set("n", "<Esc>", function()
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
            end, { buffer = buf, silent = true })

            vim.cmd("startinsert!")
        end

        local function open_workspace_picker()
            save_session()

            vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
            vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#7aa2f7", bg = "NONE" })
            vim.api.nvim_set_hl(0, "FloatTitle", { fg = "#7aa2f7", bg = "NONE", bold = true })
            vim.api.nvim_set_hl(0, "TermHeader", { fg = "#ff9e64", bg = "NONE", bold = true })
            vim.api.nvim_set_hl(0, "WorkspaceNum", { fg = "#ff9e64", bg = "NONE", bold = true })
            vim.api.nvim_set_hl(0, "EntryPointWS", { fg = "#bb9af7", bg = "NONE", bold = true })

            local width = 80
            local height = 18
            local col = math.floor((vim.o.columns - width) / 2)
            local row = math.floor((vim.o.lines - height) / 2)
            local left_width = 32
            local right_width = width - left_width - 2

            local choices = get_sorted_workspaces()

            local buf_left = vim.api.nvim_create_buf(false, true)
            local win_left = vim.api.nvim_open_win(buf_left, true, {
                relative = "editor",
                width = left_width,
                height = height,
                row = row,
                col = col,
                style = "minimal",
                border = "rounded",
                title = " Workspaces ",
                title_pos = "center",
                footer = " <CR>: Select | <Esc>: Close ",
                footer_pos = "center",
                zindex = 100,
            })

            vim.wo[win_left].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle,FloatFooter:TermHeader"
            vim.wo[win_left].cursorline = true

            local buf_right = vim.api.nvim_create_buf(false, true)
            local win_right = vim.api.nvim_open_win(buf_right, false, {
                relative = "editor",
                width = right_width,
                height = height,
                row = row,
                col = col + left_width + 2,
                style = "minimal",
                border = "rounded",
                title = " Workspace Files ",
                title_pos = "center",
                footer = " <n>: New | <d>: Delete ",
                footer_pos = "center",
                zindex = 100,
            })

            vim.wo[win_right].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle,FloatFooter:TermHeader"

            local ns_id = vim.api.nvim_create_namespace("workspace_picker")
            local lines_left = {}
            for i, name in ipairs(choices) do
                local active_suffix = (name == current_workspace) and " *" or ""
                local entry_suffix = (name == initial_ws_name) and " [entry]" or ""
                table.insert(lines_left, string.format(" [%d] %s%s%s", i, name, active_suffix, entry_suffix))
            end

            vim.api.nvim_buf_set_lines(buf_left, 0, -1, false, lines_left)
            vim.bo[buf_left].modifiable = false

            for i, name in ipairs(choices) do
                local bracket_str = string.format(" [%d]", i)
                vim.api.nvim_buf_set_extmark(buf_left, ns_id, i - 1, 1, {
                    end_col = 1 + #bracket_str,
                    hl_group = "WorkspaceNum",
                })
                if name == initial_ws_name then
                    local name_start = 1 + #bracket_str + 1
                    vim.api.nvim_buf_set_extmark(buf_left, ns_id, i - 1, name_start - 1, {
                        end_col = name_start - 1 + #name,
                        hl_group = "EntryPointWS",
                    })
                end
            end

            local function update_file_inspector()
                if not vim.api.nvim_win_is_valid(win_left) or not vim.api.nvim_win_is_valid(win_right) then return end
                local cursor_row = vim.api.nvim_win_get_cursor(win_left)[1]
                local ws_name = choices[cursor_row]
                if ws_name then
                    local files = get_workspace_files(ws_name)
                    vim.bo[buf_right].modifiable = true
                    vim.api.nvim_buf_set_lines(buf_right, 0, -1, false, files)
                    vim.bo[buf_right].modifiable = false
                end
            end

            update_file_inspector()

            vim.api.nvim_create_autocmd("CursorMoved", {
                buffer = buf_left,
                callback = function()
                    update_file_inspector()
                end,
            })

            local function close_picker()
                if vim.api.nvim_win_is_valid(win_left) then vim.api.nvim_win_close(win_left, true) end
                if vim.api.nvim_win_is_valid(win_right) then vim.api.nvim_win_close(win_right, true) end
            end

            local opts = { buffer = buf_left, silent = true }

            vim.keymap.set("n", "<CR>", function()
                local ws = choices[vim.api.nvim_win_get_cursor(win_left)[1]]
                close_picker()
                if ws then
                    switch_workspace(ws)
                end
            end, opts)

            vim.keymap.set("n", "j", "j", opts)
            vim.keymap.set("n", "k", "k", opts)
            vim.keymap.set("n", "h", "h", opts)
            vim.keymap.set("n", "l", "l", opts)
            vim.keymap.set("n", "<Esc>", close_picker, opts)
            vim.keymap.set("n", "q", close_picker, opts)

            vim.keymap.set("n", "n", function()
                close_picker()
                open_floating_input("New Path Workspace", "", function(input_val)
                    if input_val ~= "" then
                        local ws_name = vim.fn.fnamemodify(input_val:gsub("/+$", ""), ":t")
                        if ws_name == "" then ws_name = input_val end
                        local target_path = vim.fn.fnamemodify(input_val, ":p")

                        if not workspaces[ws_name] then
                            save_current_workspace()

                            if vim.fn.isdirectory(target_path) == 0 then
                                vim.fn.mkdir(target_path, "p")
                            end

                            workspaces[ws_name] = { tabs = {}, path = target_path }
                            switch_workspace(ws_name)
                            print("Created & Switched to workspace: " .. ws_name)

                            vim.schedule(function()
                                local ok, builtin = pcall(require, "telescope.builtin")
                                if ok then
                                    builtin.find_files({ cwd = target_path })
                                else
                                    vim.cmd("Telescope find_files cwd=" .. target_path)
                                end
                            end)
                        else
                            print("A workspace with that folder name already exists!")
                        end
                    end
                end)
            end, opts)

            vim.keymap.set("n", "d", function()
                local ws = choices[vim.api.nvim_win_get_cursor(win_left)[1]]
                if ws == initial_ws_name then
                    print("Cannot delete the main entry point workspace.")
                    return
                end
                local sorted_choices = get_sorted_workspaces()
                if #sorted_choices <= 1 then
                    print("Cannot delete the only remaining workspace.")
                    return
                end
                close_picker()
                if current_workspace == ws then
                    for _, name in ipairs(sorted_choices) do
                        if name ~= ws then
                            switch_workspace(name)
                            break
                        end
                    end
                end
                workspaces[ws] = nil
                save_session()
                print("Deleted workspace: " .. ws)
            end, opts)
        end

        vim.keymap.set('n', '<leader>ws', open_workspace_picker, { desc = "Open workspace floating picker" })

        for i = 1, 9 do
            vim.keymap.set('n', '<leader>w' .. i, function()
                local choices = get_sorted_workspaces()
                local ws = choices[i]
                if ws then
                    switch_workspace(ws)
                    print("Switched to workspace: " .. ws)
                else
                    print("No workspace at index " .. i)
                end
            end, { desc = "Switch to workspace " .. i })
        end

        vim.api.nvim_create_autocmd("VimLeavePre", {
            callback = function()
                save_session()
            end,
        })
    end,
}
