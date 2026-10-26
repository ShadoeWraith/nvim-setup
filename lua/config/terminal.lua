-- ============================================================================
-- Persistent Floating Terminal Manager with Background CWD Caching
-- ============================================================================

local state = {
    outer_win = -1,
    panes = {}, -- Stores active pane windows, buffers, cwd, and grid coordinates {win, buf, r, c, cwd}
    is_open = false,
    active_idx = 1, -- Tracks the currently selected/active pane index
}

local title_timer = nil

local function get_dimensions()
local width = math.floor(vim.o.columns * 0.8)
local height = math.floor(vim.o.lines * 0.8)
local col = math.floor((vim.o.columns - width) / 2)
local row = math.floor((vim.o.lines - height) / 2)
return width, height, col, row
end

local function get_session_file()
local cwd = vim.fn.getcwd()
local sanitized = cwd:gsub("[^%w]", "_")
local dir = vim.fn.stdpath("data") .. "/terminal_sessions"
vim.fn.mkdir(dir, "p")
return dir .. "/" .. sanitized .. ".json"
end

-- Robust CWD retriever using Linux /proc symlink resolution
local function get_terminal_cwd(buf)
local job_id = vim.b[buf].terminal_job_id
if not job_id then return vim.fn.getcwd() end
    local pid = vim.fn.jobpid(job_id)
    if not pid or pid <= 0 then return vim.fn.getcwd() end

        local link = vim.uv.fs_readlink("/proc/" .. pid .. "/cwd")
        if link and vim.fn.isdirectory(link) == 1 then
            return link
            end

            local handle = io.popen("readlink /proc/" .. pid .. "/cwd 2>/dev/null")
            if handle then
                local res = handle:read("*a")
                handle:close()
                res = vim.trim(res)
                if res ~= "" and vim.fn.isdirectory(res) == 1 then
                    return res
                    end
                    end

                    return vim.fn.getcwd()
                    end

                    local function ensure_active_idx()
                    if #state.panes == 0 then
                        state.active_idx = 1
                        else
                            state.active_idx = math.max(1, math.min(state.active_idx, #state.panes))
                            end
                            end

                            local function save_session()
                            local file_path = get_session_file()
                            if #state.panes == 0 then
                                os.remove(file_path)
                                return
                                end

                                ensure_active_idx()
                                local panes_data = {}
                                for _, p in ipairs(state.panes) do
                                    -- Use cached CWD or fetch it live as a fallback
                                    local cwd = p.cwd or get_terminal_cwd(p.buf)
                                    table.insert(panes_data, { r = p.r, c = p.c, cwd = cwd })
                                    end

                                    local data = {
                                        active_idx = state.active_idx,
                                        panes = panes_data,
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

                                            local function get_terminal_process_name(buf)
                                            local job_id = vim.b[buf].terminal_job_id
                                            local default_shell = vim.fn.fnamemodify(os.getenv("SHELL") or "fish", ":t")
                                            if not job_id then return default_shell end

                                                local pid = vim.fn.jobpid(job_id)
                                                if not pid or pid <= 0 then return default_shell end

                                                    local handle = io.popen(string.format("pgrep -P %d 2>/dev/null", pid))
                                                    if not handle then return default_shell end

                                                        local result = handle:read("*a")
                                                        handle:close()

                                                        local descendant_pids = {}
                                                        for p in result:gmatch("%d+") do
                                                            local child_pid = tonumber(p)
                                                            table.insert(descendant_pids, child_pid)

                                                            local sub_handle = io.popen(
                                                                string.format("pgrep -P %d 2>/dev/null", child_pid)
                                                            )

                                                            if sub_handle then
                                                                local sub_result = sub_handle:read("*a")
                                                                sub_handle:close()

                                                                for sp in sub_result:gmatch("%d+") do
                                                                    table.insert(descendant_pids, tonumber(sp))
                                                                    end
                                                                    end
                                                                    end

                                                                    if #descendant_pids == 0 then
                                                                        return default_shell
                                                                        end

                                                                        for i = #descendant_pids, 1, -1 do
                                                                            local p = descendant_pids[i]
                                                                            local comm_handle = io.popen(
                                                                                string.format("ps --no-headers -p %d -o comm= 2>/dev/null", p)
                                                                            )

                                                                            if comm_handle then
                                                                                local comm = comm_handle:read("*a")
                                                                                comm_handle:close()

                                                                                local name = vim.trim(comm)
                                                                                if name ~= "" and name ~= "ps" and name ~= "pgrep" then
                                                                                    return name
                                                                                    end
                                                                                    end
                                                                                    end

                                                                                    return default_shell
                                                                                    end

                                                                                    local function stop_title_timer()
                                                                                    if title_timer then
                                                                                        title_timer:stop()
                                                                                        title_timer:close()
                                                                                        title_timer = nil
                                                                                        end
                                                                                        end

                                                                                        local function update_pane_borders()
                                                                                        if not state.is_open then return end
                                                                                            ensure_active_idx()
                                                                                            for i, pane in ipairs(state.panes) do
                                                                                                if vim.api.nvim_win_is_valid(pane.win) then
                                                                                                    if i == state.active_idx then
                                                                                                        vim.wo[pane.win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:ActiveFloatBorder"
                                                                                                        else
                                                                                                            vim.wo[pane.win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder"
                                                                                                            end
                                                                                                            end
                                                                                                            end
                                                                                                            end

                                                                                                            local function start_title_timer()
                                                                                                            if title_timer then return end

                                                                                                                title_timer = vim.uv.new_timer()
                                                                                                                title_timer:start(0, 500, vim.schedule_wrap(function()
                                                                                                                if not state.is_open then
                                                                                                                    stop_title_timer()
                                                                                                                    return
                                                                                                                    end

                                                                                                                    update_pane_borders()

                                                                                                                    for idx, pane in ipairs(state.panes) do
                                                                                                                        if vim.api.nvim_win_is_valid(pane.win)
                                                                                                                            and vim.api.nvim_buf_is_valid(pane.buf) then

                                                                                                                            -- Continuously cache CWD and process title in the background
                                                                                                                            pane.cwd = get_terminal_cwd(pane.buf)
                                                                                                                            local title = get_terminal_process_name(pane.buf)

                                                                                                                            vim.api.nvim_win_set_config(pane.win, {
                                                                                                                                title = string.format(" [%d: %s] ", idx, title),
                                                                                                                                                        title_pos = "center",
                                                                                                                            })
                                                                                                                            end
                                                                                                                            end
                                                                                                                            end))
                                                                                                                end

                                                                                                                local function relayout_panes()
                                                                                                                if not vim.api.nvim_win_is_valid(state.outer_win) then return end

                                                                                                                    local outer_pos = vim.api.nvim_win_get_position(state.outer_win)
                                                                                                                    local outer_width = vim.api.nvim_win_get_width(state.outer_win)
                                                                                                                    local outer_height = vim.api.nvim_win_get_height(state.outer_win)

                                                                                                                    local inner_w = outer_width - 2
                                                                                                                    local inner_h = outer_height - 2
                                                                                                                    local num_panes = #state.panes

                                                                                                                    if num_panes == 0 then return end

                                                                                                                        local rows, cols = {}, {}
                                                                                                                        for _, pane in ipairs(state.panes) do
                                                                                                                            rows[pane.r] = true
                                                                                                                            cols[pane.c] = true
                                                                                                                            end

                                                                                                                            local row_list = {}
                                                                                                                            for r, _ in pairs(rows) do table.insert(row_list, r) end
                                                                                                                                table.sort(row_list)
                                                                                                                                local num_rows = #row_list

                                                                                                                                local col_list = {}
                                                                                                                                for c, _ in pairs(cols) do table.insert(col_list, c) end
                                                                                                                                    table.sort(col_list)
                                                                                                                                    local num_cols = #col_list

                                                                                                                                    local total_row_gaps = (num_rows - 1) * 2
                                                                                                                                    local total_col_gaps = (num_cols - 1) * 2

                                                                                                                                    local avail_h = inner_h - total_row_gaps
                                                                                                                                    local avail_w = inner_w - total_col_gaps

                                                                                                                                    local row_heights = {}
                                                                                                                                    local base_h = math.floor(avail_h / num_rows)
                                                                                                                                    local rem_h = avail_h % num_rows
                                                                                                                                    for i = 1, num_rows do
                                                                                                                                        row_heights[i] = base_h + (i <= rem_h and 1 or 0)
                                                                                                                                        end

                                                                                                                                        local col_widths = {}
                                                                                                                                        local base_w = math.floor(avail_w / num_cols)
                                                                                                                                        local rem_w = avail_w % num_cols
                                                                                                                                        for i = 1, num_cols do
                                                                                                                                            col_widths[i] = base_w + (i <= rem_w and 1 or 0)
                                                                                                                                            end

                                                                                                                                            local has_pane = {}
                                                                                                                                            for _, pane in ipairs(state.panes) do
                                                                                                                                                has_pane[pane.r] = has_pane[pane.r] or {}
                                                                                                                                                has_pane[pane.r][pane.c] = true
                                                                                                                                                end

                                                                                                                                                for _, pane in ipairs(state.panes) do
                                                                                                                                                    if vim.api.nvim_win_is_valid(pane.win) then
                                                                                                                                                        local r_idx, c_idx = 1, 1
                                                                                                                                                        for idx, r in ipairs(row_list) do if r == pane.r then r_idx = idx end end
                                                                                                                                                            for idx, c in ipairs(col_list) do if c == pane.c then c_idx = idx end end

                                                                                                                                                                local span_c = 1
                                                                                                                                                                for ci = c_idx + 1, num_cols do
                                                                                                                                                                    local target_c = col_list[ci]
                                                                                                                                                                    if not has_pane[pane.r] or not has_pane[pane.r][target_c] then
                                                                                                                                                                        span_c = span_c + 1
                                                                                                                                                                        else
                                                                                                                                                                            break
                                                                                                                                                                            end
                                                                                                                                                                            end

                                                                                                                                                                            local span_r = 1
                                                                                                                                                                            for ri = r_idx + 1, num_rows do
                                                                                                                                                                                local target_r = row_list[ri]
                                                                                                                                                                                if not has_pane[target_r] or not has_pane[target_r][pane.c] then
                                                                                                                                                                                    span_r = span_r + 1
                                                                                                                                                                                    else
                                                                                                                                                                                        break
                                                                                                                                                                                        end
                                                                                                                                                                                        end

                                                                                                                                                                                        local current_x = outer_pos[2] + 1
                                                                                                                                                                                        for ci = 1, c_idx - 1 do
                                                                                                                                                                                            current_x = current_x + col_widths[ci] + 2
                                                                                                                                                                                            end
                                                                                                                                                                                            local w = 0
                                                                                                                                                                                            for ci = c_idx, c_idx + span_c - 1 do
                                                                                                                                                                                                w = w + col_widths[ci]
                                                                                                                                                                                                end
                                                                                                                                                                                                w = w + ((span_c - 1) * 2)

                                                                                                                                                                                                local current_y = outer_pos[1] + 1
                                                                                                                                                                                                for ri = 1, r_idx - 1 do
                                                                                                                                                                                                    current_y = current_y + row_heights[ri] + 2
                                                                                                                                                                                                    end
                                                                                                                                                                                                    local h = 0
                                                                                                                                                                                                    for ri = r_idx, r_idx + span_r - 1 do
                                                                                                                                                                                                        h = h + row_heights[ri]
                                                                                                                                                                                                        end
                                                                                                                                                                                                        h = h + ((span_r - 1) * 2)

                                                                                                                                                                                                        vim.api.nvim_win_set_config(pane.win, {
                                                                                                                                                                                                            relative = "editor",
                                                                                                                                                                                                            width = w,
                                                                                                                                                                                                            height = h,
                                                                                                                                                                                                            row = current_y,
                                                                                                                                                                                                            col = current_x,
                                                                                                                                                                                                            zindex = 51,
                                                                                                                                                                                                        })
                                                                                                                                                                                                        end
                                                                                                                                                                                                        end
                                                                                                                                                                                                        end

                                                                                                                                                                                                        local function get_current_pane()
                                                                                                                                                                                                        ensure_active_idx()
                                                                                                                                                                                                        return state.panes[state.active_idx] or state.panes[1]
                                                                                                                                                                                                        end

                                                                                                                                                                                                        local function setup_buffer_keymaps(buf)
                                                                                                                                                                                                        vim.keymap.set("t", "<C-\\><C-n>", "<Nop>", { buffer = buf })
                                                                                                                                                                                                        vim.keymap.set("t", "<LeftMouse>", "<LeftMouse>i", { buffer = buf })

                                                                                                                                                                                                        vim.keymap.set("t", "<M-v>", function()
                                                                                                                                                                                                        local curr = get_current_pane()
                                                                                                                                                                                                        local new_r = curr and curr.r or 1
                                                                                                                                                                                                        local max_c = 0
                                                                                                                                                                                                        for _, p in ipairs(state.panes) do
                                                                                                                                                                                                            if p.r == new_r and p.c > max_c then max_c = p.c end
                                                                                                                                                                                                                end

                                                                                                                                                                                                                local new_buf = vim.api.nvim_create_buf(false, true)
                                                                                                                                                                                                                local width, height, col, row = get_dimensions()
                                                                                                                                                                                                                local win = vim.api.nvim_open_win(new_buf, true, {
                                                                                                                                                                                                                    relative = "editor",
                                                                                                                                                                                                                    width = width - 2,
                                                                                                                                                                                                                    height = height - 2,
                                                                                                                                                                                                                    row = row + 1,
                                                                                                                                                                                                                    col = col + 1,
                                                                                                                                                                                                                    style = "minimal",
                                                                                                                                                                                                                    border = "single",
                                                                                                                                                                                                                    zindex = 51,
                                                                                                                                                                                                                })

                                                                                                                                                                                                                vim.wo[win].number = false
                                                                                                                                                                                                                vim.wo[win].relativenumber = false
                                                                                                                                                                                                                vim.wo[win].signcolumn = "no"
                                                                                                                                                                                                                vim.wo[win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder"

                                                                                                                                                                                                                -- Inherit active pane's current working directory
                                                                                                                                                                                                                local parent_cwd = curr and (curr.cwd or get_terminal_cwd(curr.buf)) or vim.fn.getcwd()
                                                                                                                                                                                                                vim.api.nvim_buf_call(new_buf, function()
                                                                                                                                                                                                                vim.fn.termopen(os.getenv("SHELL") or "fish", { cwd = parent_cwd })
                                                                                                                                                                                                                end)
                                                                                                                                                                                                                setup_buffer_keymaps(new_buf)

                                                                                                                                                                                                                table.insert(state.panes, {
                                                                                                                                                                                                                    win = win,
                                                                                                                                                                                                                    buf = new_buf,
                                                                                                                                                                                                                    r = new_r,
                                                                                                                                                                                                                    c = max_c + 1,
                                                                                                                                                                                                                    cwd = parent_cwd,
                                                                                                                                                                                                                })

                                                                                                                                                                                                                state.active_idx = #state.panes
                                                                                                                                                                                                                relayout_panes()
                                                                                                                                                                                                                vim.api.nvim_set_current_win(win)
                                                                                                                                                                                                                update_pane_borders()
                                                                                                                                                                                                                vim.cmd("startinsert")
                                                                                                                                                                                                                save_session()
                                                                                                                                                                                                                end, { buffer = buf, desc = "Vertical split terminal" })

                                                                                                                                                                                                        vim.keymap.set("t", "<M-h>", function()
                                                                                                                                                                                                        local curr = get_current_pane()
                                                                                                                                                                                                        local max_r = 0
                                                                                                                                                                                                        for _, p in ipairs(state.panes) do
                                                                                                                                                                                                            if p.r > max_r then max_r = p.r end
                                                                                                                                                                                                                end

                                                                                                                                                                                                                local new_buf = vim.api.nvim_create_buf(false, true)
                                                                                                                                                                                                                local width, height, col, row = get_dimensions()
                                                                                                                                                                                                                local win = vim.api.nvim_open_win(new_buf, true, {
                                                                                                                                                                                                                    relative = "editor",
                                                                                                                                                                                                                    width = width - 2,
                                                                                                                                                                                                                    height = height - 2,
                                                                                                                                                                                                                    row = row + 1,
                                                                                                                                                                                                                    col = col + 1,
                                                                                                                                                                                                                    style = "minimal",
                                                                                                                                                                                                                    border = "single",
                                                                                                                                                                                                                    zindex = 51,
                                                                                                                                                                                                                })

                                                                                                                                                                                                                vim.wo[win].number = false
                                                                                                                                                                                                                vim.wo[win].relativenumber = false
                                                                                                                                                                                                                vim.wo[win].signcolumn = "no"
                                                                                                                                                                                                                vim.wo[win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:ActiveFloatBorder"

                                                                                                                                                                                                                -- Inherit active pane's current working directory
                                                                                                                                                                                                                local parent_cwd = curr and (curr.cwd or get_terminal_cwd(curr.buf)) or vim.fn.getcwd()
                                                                                                                                                                                                                vim.api.nvim_buf_call(new_buf, function()
                                                                                                                                                                                                                vim.fn.termopen(os.getenv("SHELL") or "fish", { cwd = parent_cwd })
                                                                                                                                                                                                                end)
                                                                                                                                                                                                                setup_buffer_keymaps(new_buf)

                                                                                                                                                                                                                table.insert(state.panes, {
                                                                                                                                                                                                                    win = win,
                                                                                                                                                                                                                    buf = new_buf,
                                                                                                                                                                                                                    r = max_r + 1,
                                                                                                                                                                                                                    c = curr and curr.c or 1,
                                                                                                                                                                                                                    cwd = parent_cwd,
                                                                                                                                                                                                                })

                                                                                                                                                                                                                state.active_idx = #state.panes
                                                                                                                                                                                                                relayout_panes()
                                                                                                                                                                                                                vim.api.nvim_set_current_win(win)
                                                                                                                                                                                                                update_pane_borders()
                                                                                                                                                                                                                vim.cmd("startinsert")
                                                                                                                                                                                                                save_session()
                                                                                                                                                                                                                end, { buffer = buf, desc = "Horizontal split terminal" })

                                                                                                                                                                                                        vim.keymap.set("t", "<M-c>", function()
                                                                                                                                                                                                        local curr = get_current_pane()
                                                                                                                                                                                                        if not curr then return end

                                                                                                                                                                                                            if vim.api.nvim_win_is_valid(curr.win) then
                                                                                                                                                                                                                vim.api.nvim_win_close(curr.win, true)
                                                                                                                                                                                                                end
                                                                                                                                                                                                                if vim.api.nvim_buf_is_valid(curr.buf) then
                                                                                                                                                                                                                    vim.api.nvim_buf_delete(curr.buf, { force = true })
                                                                                                                                                                                                                    end

                                                                                                                                                                                                                    local remove_idx = nil
                                                                                                                                                                                                                    for i, p in ipairs(state.panes) do
                                                                                                                                                                                                                        if p.win == curr.win or p.buf == curr.buf then
                                                                                                                                                                                                                            remove_idx = i
                                                                                                                                                                                                                            break
                                                                                                                                                                                                                            end
                                                                                                                                                                                                                            end

                                                                                                                                                                                                                            if remove_idx then
                                                                                                                                                                                                                                table.remove(state.panes, remove_idx)
                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                state.active_idx = math.max(1, state.active_idx - 1)
                                                                                                                                                                                                                                ensure_active_idx()
                                                                                                                                                                                                                                save_session()

                                                                                                                                                                                                                                if #state.panes == 0 then
                                                                                                                                                                                                                                    stop_title_timer()
                                                                                                                                                                                                                                    if vim.api.nvim_win_is_valid(state.outer_win) then
                                                                                                                                                                                                                                        vim.api.nvim_win_hide(state.outer_win)
                                                                                                                                                                                                                                        end
                                                                                                                                                                                                                                        state.is_open = false
                                                                                                                                                                                                                                        else
                                                                                                                                                                                                                                            relayout_panes()
                                                                                                                                                                                                                                            local target = state.panes[state.active_idx] or state.panes[1]
                                                                                                                                                                                                                                            if target and vim.api.nvim_win_is_valid(target.win) then
                                                                                                                                                                                                                                                vim.api.nvim_set_current_win(target.win)
                                                                                                                                                                                                                                                update_pane_borders()
                                                                                                                                                                                                                                                vim.cmd("startinsert")
                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                end, { buffer = buf, desc = "Close active terminal pane" })

                                                                                                                                                                                                        vim.keymap.set("t", "<M-w>", function()
                                                                                                                                                                                                        ensure_active_idx()
                                                                                                                                                                                                        local next_idx = (state.active_idx % #state.panes) + 1
                                                                                                                                                                                                        state.active_idx = next_idx
                                                                                                                                                                                                        if state.panes[next_idx] and vim.api.nvim_win_is_valid(state.panes[next_idx].win) then
                                                                                                                                                                                                            vim.api.nvim_set_current_win(state.panes[next_idx].win)
                                                                                                                                                                                                            update_pane_borders()
                                                                                                                                                                                                            vim.cmd("startinsert")
                                                                                                                                                                                                            save_session()
                                                                                                                                                                                                            end
                                                                                                                                                                                                            end, { buffer = buf, desc = "Cycle terminal panes" })

                                                                                                                                                                                                        for i = 1, 9 do
                                                                                                                                                                                                            vim.keymap.set("t", "<M-" .. i .. ">", function()
                                                                                                                                                                                                            if state.panes[i] and vim.api.nvim_win_is_valid(state.panes[i].win) then
                                                                                                                                                                                                                state.active_idx = i
                                                                                                                                                                                                                vim.api.nvim_set_current_win(state.panes[i].win)
                                                                                                                                                                                                                update_pane_borders()
                                                                                                                                                                                                                vim.cmd("startinsert")
                                                                                                                                                                                                                save_session()
                                                                                                                                                                                                                end
                                                                                                                                                                                                                end, { buffer = buf, desc = "Jump to terminal " .. i })
                                                                                                                                                                                                            end

                                                                                                                                                                                                            vim.api.nvim_create_autocmd("ModeChanged", {
                                                                                                                                                                                                                buffer = buf,
                                                                                                                                                                                                                callback = function()
                                                                                                                                                                                                                if vim.bo[buf].buftype == "terminal" and vim.fn.mode() == "n" then
                                                                                                                                                                                                                    vim.schedule(function()
                                                                                                                                                                                                                    if vim.api.nvim_buf_is_valid(buf) and vim.fn.mode() == "n" then
                                                                                                                                                                                                                        vim.cmd("startinsert")
                                                                                                                                                                                                                        end
                                                                                                                                                                                                                        end)
                                                                                                                                                                                                                    end
                                                                                                                                                                                                                    end,
                                                                                                                                                                                                            })
                                                                                                                                                                                                            end

                                                                                                                                                                                                            local function restore_session()
                                                                                                                                                                                                            local file_path = get_session_file()
                                                                                                                                                                                                            local f = io.open(file_path, "r")
                                                                                                                                                                                                            if not f then return false end
                                                                                                                                                                                                                local content = f:read("*a")
                                                                                                                                                                                                                f:close()

                                                                                                                                                                                                                local ok, data = pcall(vim.json.decode, content)
                                                                                                                                                                                                                if not ok or not data or not data.panes or #data.panes == 0 then
                                                                                                                                                                                                                    return false
                                                                                                                                                                                                                    end

                                                                                                                                                                                                                    state.active_idx = data.active_idx or 1
                                                                                                                                                                                                                    ensure_active_idx()

                                                                                                                                                                                                                    local width, height, col, row = get_dimensions()
                                                                                                                                                                                                                    if not vim.api.nvim_win_is_valid(state.outer_win) then
                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#7aa2f7", bg = "NONE" })
                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "ActiveFloatBorder", { fg = "#ff9e64", bg = "NONE" })
                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "FloatTitle", { fg = "#7aa2f7", bg = "NONE", bold = true })
                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "TermHeader", { fg = "#ff9e64", bg = "NONE", bold = true })
                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "TermCursor", { bg = "#7aa2f7", fg = "#1a1b26" })

                                                                                                                                                                                                                        local outer_buf = vim.api.nvim_create_buf(false, true)
                                                                                                                                                                                                                        state.outer_win = vim.api.nvim_open_win(outer_buf, false, {
                                                                                                                                                                                                                            relative = "editor",
                                                                                                                                                                                                                            width = width,
                                                                                                                                                                                                                            height = height,
                                                                                                                                                                                                                            col = col,
                                                                                                                                                                                                                            row = row,
                                                                                                                                                                                                                            style = "minimal",
                                                                                                                                                                                                                            border = "rounded",
                                                                                                                                                                                                                            title = " Terminal ",
                                                                                                                                                                                                                            title_pos = "center",
                                                                                                                                                                                                                            footer = " <M-v>: VSplit | <M-h>: HSplit | <M-c>: Close | <M-1..9>: Jump | <M-w>: Cycle ",
                                                                                                                                                                                                                            footer_pos = "center",
                                                                                                                                                                                                                            zindex = 50,
                                                                                                                                                                                                                        })
                                                                                                                                                                                                                        vim.wo[state.outer_win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle,FloatFooter:TermHeader"
                                                                                                                                                                                                                        vim.bo[outer_buf].buftype = "nofile"
                                                                                                                                                                                                                        end

                                                                                                                                                                                                                        for _, p_data in ipairs(data.panes) do
                                                                                                                                                                                                                            local buf = vim.api.nvim_create_buf(false, true)
                                                                                                                                                                                                                            local win = vim.api.nvim_open_win(buf, false, {
                                                                                                                                                                                                                                relative = "editor",
                                                                                                                                                                                                                                width = width - 2,
                                                                                                                                                                                                                                height = height - 2,
                                                                                                                                                                                                                                row = row + 1,
                                                                                                                                                                                                                                col = col + 1,
                                                                                                                                                                                                                                style = "minimal",
                                                                                                                                                                                                                                border = "single",
                                                                                                                                                                                                                                zindex = 51,
                                                                                                                                                                                                                            })

                                                                                                                                                                                                                            vim.wo[win].number = false
                                                                                                                                                                                                                            vim.wo[win].relativenumber = false
                                                                                                                                                                                                                            vim.wo[win].signcolumn = "no"
                                                                                                                                                                                                                            vim.wo[win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder"

                                                                                                                                                                                                                            -- Restore each pane to its exact remembered CWD directory (e.g. mini or Tactics)
                                                                                                                                                                                                                            local target_cwd = p_data.cwd or vim.fn.getcwd()
                                                                                                                                                                                                                            vim.api.nvim_buf_call(buf, function()
                                                                                                                                                                                                                            vim.fn.termopen(os.getenv("SHELL") or "fish", { cwd = target_cwd })
                                                                                                                                                                                                                            end)
                                                                                                                                                                                                                            setup_buffer_keymaps(buf)

                                                                                                                                                                                                                            table.insert(state.panes, {
                                                                                                                                                                                                                                win = win,
                                                                                                                                                                                                                                buf = buf,
                                                                                                                                                                                                                                r = p_data.r,
                                                                                                                                                                                                                                c = p_data.c,
                                                                                                                                                                                                                                cwd = target_cwd,
                                                                                                                                                                                                                            })
                                                                                                                                                                                                                            end

                                                                                                                                                                                                                            state.is_open = true
                                                                                                                                                                                                                            relayout_panes()
                                                                                                                                                                                                                            start_title_timer()

                                                                                                                                                                                                                            ensure_active_idx()
                                                                                                                                                                                                                            local target_pane = state.panes[state.active_idx] or state.panes[1]
                                                                                                                                                                                                                            if target_pane and vim.api.nvim_win_is_valid(target_pane.win) then
                                                                                                                                                                                                                                vim.api.nvim_set_current_win(target_pane.win)
                                                                                                                                                                                                                                update_pane_borders()
                                                                                                                                                                                                                                vim.cmd("startinsert")
                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                return true
                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                local toggle_terminal = function()
                                                                                                                                                                                                                                if state.is_open then
                                                                                                                                                                                                                                    stop_title_timer()
                                                                                                                                                                                                                                    if vim.api.nvim_win_is_valid(state.outer_win) then
                                                                                                                                                                                                                                        vim.api.nvim_win_hide(state.outer_win)
                                                                                                                                                                                                                                        end
                                                                                                                                                                                                                                        for _, pane in ipairs(state.panes) do
                                                                                                                                                                                                                                            if pane.win and vim.api.nvim_win_is_valid(pane.win) then
                                                                                                                                                                                                                                                vim.api.nvim_win_hide(pane.win)
                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                state.is_open = false
                                                                                                                                                                                                                                                save_session()
                                                                                                                                                                                                                                                else
                                                                                                                                                                                                                                                    local width, height, col, row = get_dimensions()

                                                                                                                                                                                                                                                    if not state.outer_win or not vim.api.nvim_win_is_valid(state.outer_win) then
                                                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
                                                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#7aa2f7", bg = "NONE" })
                                                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "ActiveFloatBorder", { fg = "#ff9e64", bg = "NONE" })
                                                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "FloatTitle", { fg = "#7aa2f7", bg = "NONE", bold = true })
                                                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "TermHeader", { fg = "#ff9e64", bg = "NONE", bold = true })
                                                                                                                                                                                                                                                        vim.api.nvim_set_hl(0, "TermCursor", { bg = "#7aa2f7", fg = "#1a1b26" })

                                                                                                                                                                                                                                                        local outer_buf = vim.api.nvim_create_buf(false, true)
                                                                                                                                                                                                                                                        vim.bo[outer_buf].buftype = "nofile"
                                                                                                                                                                                                                                                        state.outer_win = vim.api.nvim_open_win(outer_buf, false, {
                                                                                                                                                                                                                                                            relative = "editor",
                                                                                                                                                                                                                                                            width = width,
                                                                                                                                                                                                                                                            height = height,
                                                                                                                                                                                                                                                            col = col,
                                                                                                                                                                                                                                                            row = row,
                                                                                                                                                                                                                                                            style = "minimal",
                                                                                                                                                                                                                                                            border = "rounded",
                                                                                                                                                                                                                                                            title = " Terminal ",
                                                                                                                                                                                                                                                            title_pos = "center",
                                                                                                                                                                                                                                                            footer = " <M-v>: VSplit | <M-h>: HSplit | <M-c>: Close | <M-1..9>: Jump | <M-w>: Cycle ",
                                                                                                                                                                                                                                                            footer_pos = "center",
                                                                                                                                                                                                                                                            zindex = 50,
                                                                                                                                                                                                                                                        })
                                                                                                                                                                                                                                                        vim.wo[state.outer_win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder,FloatTitle:FloatTitle,FloatFooter:TermHeader"
                                                                                                                                                                                                                                                        end

                                                                                                                                                                                                                                                        if #state.panes == 0 then
                                                                                                                                                                                                                                                            if not restore_session() then
                                                                                                                                                                                                                                                                local buf = vim.api.nvim_create_buf(false, true)
                                                                                                                                                                                                                                                                local win = vim.api.nvim_open_win(buf, true, {
                                                                                                                                                                                                                                                                relative = "editor",
                                                                                                                                                                                                                                                                width = width - 2,
                                                                                                                                                                                                                                                                height = height - 2,
                                                                                                                                                                                                                                                                row = row + 1,
                                                                                                                                                                                                                                                                col = col + 1,
                                                                                                                                                                                                                                                                style = "minimal",
                                                                                                                                                                                                                                                                border = "single",
                                                                                                                                                                                                                                                                zindex = 51,
                                                                                                                                                                                                                                                                })
                                                                                                                                                                                                                                                                vim.wo[win].number = false
                                                                                                                                                                                                                                                                vim.wo[win].relativenumber = false
                                                                                                                                                                                                                                                                vim.wo[win].signcolumn = "no"
                                                                                                                                                                                                                                                                vim.wo[win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:ActiveFloatBorder"

                                                                                                                                                                                                                                                                local default_cwd = vim.fn.getcwd()
                                                                                                                                                                                                                                                                vim.api.nvim_buf_call(buf, function()
                                                                                                                                                                                                                                                                vim.fn.termopen(os.getenv("SHELL") or "fish", { cwd = default_cwd })
                                                                                                                                                                                                                                                                end)
                                                                                                                                                                                                                                                                setup_buffer_keymaps(buf)

                                                                                                                                                                                                                                                                table.insert(state.panes, { win = win, buf = buf, r = 1, c = 1, cwd = default_cwd })
                                                                                                                                                                                                                                                                state.active_idx = 1
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                else
                                                                                                                                                                                                                                                                for _, pane in ipairs(state.panes) do
                                                                                                                                                                                                                                                                if not pane.buf or not vim.api.nvim_buf_is_valid(pane.buf) then
                                                                                                                                                                                                                                                                pane.buf = vim.api.nvim_create_buf(false, true)
                                                                                                                                                                                                                                                                local target_cwd = pane.cwd or vim.fn.getcwd()
                                                                                                                                                                                                                                                                vim.api.nvim_buf_call(pane.buf, function()
                                                                                                                                                                                                                                                                vim.fn.termopen(os.getenv("SHELL") or "fish", { cwd = target_cwd })
                                                                                                                                                                                                                                                                end)
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                pane.win = vim.api.nvim_open_win(pane.buf, false, {
                                                                                                                                                                                                                                                                relative = "editor",
                                                                                                                                                                                                                                                                width = width - 2,
                                                                                                                                                                                                                                                                height = height - 2,
                                                                                                                                                                                                                                                                row = row + 1,
                                                                                                                                                                                                                                                                col = col + 1,
                                                                                                                                                                                                                                                                style = "minimal",
                                                                                                                                                                                                                                                                border = "single",
                                                                                                                                                                                                                                                                zindex = 51,
                                                                                                                                                                                                                                                                })
                                                                                                                                                                                                                                                                vim.wo[pane.win].number = false
                                                                                                                                                                                                                                                                vim.wo[pane.win].relativenumber = false
                                                                                                                                                                                                                                                                vim.wo[pane.win].signcolumn = "no"
                                                                                                                                                                                                                                                                vim.wo[pane.win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder"
                                                                                                                                                                                                                                                                setup_buffer_keymaps(pane.buf)
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                state.is_open = true
                                                                                                                                                                                                                                                                relayout_panes()
                                                                                                                                                                                                                                                                start_title_timer()

                                                                                                                                                                                                                                                                ensure_active_idx()
                                                                                                                                                                                                                                                                local target = state.panes[state.active_idx] or state.panes[1]
                                                                                                                                                                                                                                                                if target and target.win and vim.api.nvim_win_is_valid(target.win) then
                                                                                                                                                                                                                                                                vim.api.nvim_set_current_win(target.win)
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                update_pane_borders()
                                                                                                                                                                                                                                                                vim.cmd("startinsert")
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                vim.api.nvim_create_autocmd("VimLeavePre", {
                                                                                                                                                                                                                                                                callback = function()
                                                                                                                                                                                                                                                                save_session()
                                                                                                                                                                                                                                                                end,
                                                                                                                                                                                                                                                                })

                                                                                                                                                                                                                                                                vim.keymap.set("n", "<leader>tt", toggle_terminal, { desc = "Toggle floating terminal" })

                                                                                                                                                                                                                                                                vim.keymap.set("t", "<Esc>", function()
                                                                                                                                                                                                                                                                if state.is_open then
                                                                                                                                                                                                                                                                stop_title_timer()

                                                                                                                                                                                                                                                                if vim.api.nvim_win_is_valid(state.outer_win) then
                                                                                                                                                                                                                                                                vim.api.nvim_win_hide(state.outer_win)
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                for _, pane in ipairs(state.panes) do
                                                                                                                                                                                                                                                                if vim.api.nvim_win_is_valid(pane.win) then
                                                                                                                                                                                                                                                                vim.api.nvim_win_hide(pane.win)
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                state.is_open = false
                                                                                                                                                                                                                                                                save_session()
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end, { silent = true })
