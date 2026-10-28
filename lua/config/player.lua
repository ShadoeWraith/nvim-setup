local M = {}

-- Mini CAVA Bottom-Right Transparent Bar State
local mini_win = nil
local mini_buf = nil
local mini_job = nil
local current_vis = "· · · · · · · · · · · · · · · ·"
local is_restarting = false

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

-- Ensure mini buffer exists and is configured
local function ensure_buf()
    if not mini_buf or not vim.api.nvim_buf_is_valid(mini_buf) then
        mini_buf = vim.api.nvim_create_buf(false, true)
        vim.bo[mini_buf].buftype = "nofile"
        vim.bo[mini_buf].bufhidden = "hide"
        vim.bo[mini_buf].swapfile = false
        vim.bo[mini_buf].buflisted = false
    end
    return mini_buf
end

-- Ensure float window is present on the current active tab
local function ensure_window()
    local cur_tab = vim.api.nvim_get_current_tabpage()
    if mini_win and vim.api.nvim_win_is_valid(mini_win) then
        local win_tab = vim.api.nvim_win_get_tabpage(mini_win)
        if win_tab == cur_tab then
            return true
        end
        pcall(vim.api.nvim_win_close, mini_win, true)
        mini_win = nil
    end

    local buf = ensure_buf()
    local width = 30
    local height = 1
    local col = vim.o.columns - width
    local row = vim.o.lines - 3

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

    local ok, win = pcall(vim.api.nvim_open_win, buf, false, opts)
    if ok and win and vim.api.nvim_win_is_valid(win) then
        mini_win = win
        pcall(vim.api.nvim_set_option_value, "winhl", "Normal:Normal", { win = mini_win })
        return true
    end
    return false
end

-- Redraw CAVA visualizer line inside the buffer
local function update_ui()
    if not ensure_window() then return end
    if not mini_buf or not vim.api.nvim_buf_is_valid(mini_buf) then return end

    local lines = { current_vis }
    vim.bo[mini_buf].modifiable = true
    vim.api.nvim_buf_set_lines(mini_buf, 0, -1, false, lines)
    vim.bo[mini_buf].modifiable = false
end

-- Stop cava job safely
local function stop_cava_job()
    if mini_job then
        local job = mini_job
        mini_job = nil
        pcall(vim.fn.jobstop, job)
    end
    os.execute("killall cava >/dev/null 2>&1")
end

-- Start cava background process
local function start_cava_job()
    local cava_conf = write_cava_config()
    local stdout_buffer = ""

    local current_job
    current_job = vim.fn.jobstart({ "cava", "-p", cava_conf }, {
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
                -- Auto-respawn if Neovim is still running and not explicitly restarting
                if not is_restarting then
                    vim.defer_fn(function()
                        if not mini_job and not is_restarting then
                            start_cava_job()
                        end
                    end, 500)
                end
            end
        end,
    })
    mini_job = current_job
end

-- Always-On Background CAVA Bar Initialization & Refresh
function M.start_mini()
    is_restarting = true
    stop_cava_job()
    ensure_window()
    start_cava_job()
    is_restarting = false
    update_ui()
end

-- Explicit Refresh Function & Keybind Target
function M.refresh()
    M.start_mini()
    vim.notify("CAVA visualizer refreshed", vim.log.levels.INFO)
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
        end,
    })

    vim.cmd("startinsert")
end

-- ==========================================
-- AUTO-START & TAB / RESIZE AUTO-SYNC
-- ==========================================
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        vim.defer_fn(M.start_mini, 100)
    end,
})

-- Re-attach float window across tabs so it NEVER disappears when switching tabs
vim.api.nvim_create_autocmd({ "TabEnter", "BufWinEnter", "FocusGained" }, {
    callback = function()
        vim.schedule(function()
            ensure_window()
            update_ui()
        end)
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
        is_restarting = true
        stop_cava_job()
    end,
})

-- ==========================================
-- GLOBAL KEYBINDS
-- ==========================================
vim.keymap.set("n", "<leader>mr", M.refresh, { desc = "Refresh CAVA Visualizer" })
vim.keymap.set("n", "<leader>tr", M.toggle_browser, { desc = "Toggle RMPC Music Browser" })

return M
