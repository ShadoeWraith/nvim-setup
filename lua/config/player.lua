local M = {}

-- Mini CAVA Bottom-Right Transparent Bar State
local mini_win = nil
local mini_buf = nil
local mini_job = nil
local current_vis = "· · · · · · · · · · · · · · · ·"

-- Big Browser (RMPC) State
local browser_win = nil

-- Stable CAVA configuration
local function write_cava_config()
local path = "/tmp/nvim_cava.conf"
local file = io.open(path, "w")
if file then
    file:write([[
        [general]
        bars = 30
        framerate = 60

        [input]
        method = pulse
        source = auto

        [output]
        method = raw
        data_format = ascii
        ascii_max_range = 8
        bar_delimiter = 32
        frame_delimiter = 10
    ]])
    file:close()
    end
    return path
    end

    -- Redraw CAVA visualizer line inside the buffer
    local function update_ui()
    if not mini_win or not vim.api.nvim_win_is_valid(mini_win) or not mini_buf or not vim.api.nvim_buf_is_valid(mini_buf) then return end

        local lines = { current_vis }

        vim.bo[mini_buf].modifiable = true
        vim.api.nvim_buf_set_lines(mini_buf, 0, -1, false, lines)
        vim.bo[mini_buf].modifiable = false
        end

        -- Always-On Background CAVA Bar Initialization (Guaranteed single instance)
        function M.start_mini()
        if mini_job then
            vim.fn.jobstop(mini_job)
            mini_job = nil
            end
            if mini_win and vim.api.nvim_win_is_valid(mini_win) then
                pcall(vim.api.nvim_win_close, mini_win, true)
                mini_win = nil
                end
                if mini_buf and vim.api.nvim_buf_is_valid(mini_buf) then
                    pcall(vim.api.nvim_buf_delete, mini_buf, { force = true })
                    mini_buf = nil
                    end

                    os.execute("killall cava >/dev/null 2>&1")

                    local width = 30
                    local height = 1
                    local col = vim.o.columns - width
                    local row = vim.o.lines - 3

                    mini_buf = vim.api.nvim_create_buf(false, true)

                    local opts = {
                        style = "minimal",
                        relative = "editor",
                        width = width,
                        height = height,
                        row = row,
                        col = col,
                        border = "none",
                        focusable = false,
                    }

                    mini_win = vim.api.nvim_open_win(mini_buf, false, opts)
                    vim.api.nvim_set_option_value("winhl", "Normal:Normal", { win = mini_win })

                    local cava_conf = write_cava_config()
                    local stdout_buffer = ""

                    local current_job
                    current_job = vim.fn.jobstart({"cava", "-p", cava_conf}, {
                        stdout_buffered = false,
                        on_stdout = function(_, data, _)
                        if mini_job ~= current_job then return end
                            if not data then return end
                                stdout_buffer = stdout_buffer .. table.concat(data, "\n")
                                for line in stdout_buffer:gmatch("([^\n]*)\n") do
                                    if line ~= "" then
                                        local bar_chars = { " ", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
                                        local vis_chars = {}
                                        for num in line:gmatch("%S+") do
                                            local val = tonumber(num) or 0
                                            local idx = math.floor((val / 8) * (#bar_chars - 1)) + 1
                                            idx = math.max(1, math.min(idx, #bar_chars))
                                            table.insert(vis_chars, bar_chars[idx])
                                            end
                                            current_vis = table.concat(vis_chars, " ")
                                            end
                                            end
                                            stdout_buffer = stdout_buffer:match("([^\n]*)$") or ""
                                            vim.schedule(update_ui)
                                            end,
                                            on_exit = function()
                                            if mini_job == current_job then
                                                mini_job = nil
                                                end
                                                end
                    })
                    mini_job = current_job

                    update_ui()
                    end

                    -- Toggle Large Interactive Browser (RMPC Directory Picker)
                    function M.toggle_browser()
                    if browser_win and vim.api.nvim_win_is_valid(browser_win) then
                        vim.api.nvim_win_close(browser_win, true)
                        browser_win = nil
                        return
                        end

                        local width = math.floor(vim.o.columns * 0.75)
                        local height = math.floor(vim.o.lines * 0.75)
                        local col = math.floor((vim.o.columns - width) / 2)
                        local row = math.floor((vim.o.lines - height) / 2)

                        local buf = vim.api.nvim_create_buf(false, true)
                        vim.bo[buf].bufhidden = "wipe"

                        local opts = {
                            style = "minimal",
                            relative = "editor",
                            width = width,
                            height = height,
                            row = row,
                            col = col,
                            border = "rounded",
                            title = " Music Library Browser ",
                            title_pos = "center",
                        }

                        browser_win = vim.api.nvim_open_win(buf, true, opts)

                        vim.fn.termopen("rmpc", {
                            on_exit = function()
                            if browser_win and vim.api.nvim_win_is_valid(browser_win) then
                                vim.api.nvim_win_close(browser_win, true)
                                browser_win = nil
                                end
                                end
                        })

                        vim.cmd("startinsert")
                        end

                        -- ==========================================
                        -- AUTO-START & AUTO-CLEANUP AUTOCMDS
                        -- ==========================================
                        vim.api.nvim_create_autocmd("VimEnter", {
                            callback = function()
                            vim.defer_fn(M.start_mini, 100)
                            end,
                        })

                        vim.api.nvim_create_autocmd("VimResized", {
                            callback = function()
                            if mini_win and vim.api.nvim_win_is_valid(mini_win) then
                                local width = 30
                                local col = vim.o.columns - width
                                local row = vim.o.lines - 3
                                pcall(vim.api.nvim_win_set_config, mini_win, {
                                    relative = "editor",
                                    row = row,
                                    col = col,
                                    width = width,
                                    height = 1,
                                })
                                end
                                end,
                        })

                        vim.api.nvim_create_autocmd("VimLeavePre", {
                            callback = function()
                            if mini_job then
                                vim.fn.jobstop(mini_job)
                                mini_job = nil
                                end
                                os.execute("killall cava >/dev/null 2>&1")
                                end,
                        })

                        -- ==========================================
                        -- GLOBAL KEYBINDS
                        -- ==========================================
                        vim.keymap.set("n", "<leader>tr", M.toggle_browser, { desc = "Toggle RMPC Music Browser" })

                        return M
