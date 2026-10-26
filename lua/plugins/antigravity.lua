return {
    "NakLast/antigravity-cli.nvim",
    keys = {
        { "<leader>ag", desc = "Toggle Antigravity Float" },
    },
    config = function()
    -- Tokyonight transparent floating styles & orange footer hint
    vim.api.nvim_set_hl(0, "AgyFloatBorder", { fg = "#7aa2f7", bg = "NONE" })
    vim.api.nvim_set_hl(0, "AgyFloatNormal", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "AgyFloatFooter", { fg = "#ff9e64", bg = "NONE", bold = true })

    local agy_win = nil
    local agy_buf = nil

    local function toggle_agy_float()
    -- If the window is currently open anywhere, close/hide it
    if agy_win and vim.api.nvim_win_is_valid(agy_win) then
        vim.api.nvim_win_close(agy_win, true)
        agy_win = nil
        vim.cmd("checktime")
        return
        end

        -- Otherwise, reopen the window using the existing buffer (preserving the session)
        local uis = vim.api.nvim_list_uis()
        if #uis == 0 then return end
            local ui = uis[1]

            local width = math.floor(ui.width * 0.22)
            local height = math.floor(ui.height * 0.88)
            local row = 1
            local col = ui.width - width

            -- Reuse the existing buffer if it's valid, otherwise create a new one
            if not agy_buf or not vim.api.nvim_buf_is_valid(agy_buf) then
                agy_buf = vim.api.nvim_create_buf(false, true)
                end

                agy_win = vim.api.nvim_open_win(agy_buf, true, {
                    relative = "editor",
                    width = width,
                    height = height,
                    row = row,
                    col = col,
                    style = "minimal",
                    border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                    footer = " <C-q> Exit Focus ",
                    footer_pos = "center",
                })

                vim.api.nvim_set_option_value(
                    "winhl",
                    "Normal:AgyFloatNormal,FloatBorder:AgyFloatBorder,FloatFooter:AgyFloatFooter",
                    { win = agy_win }
                )

                -- Only start a new terminal process if one isn't already running in this buffer
                if vim.bo[agy_buf].buftype ~= "terminal" then
                    vim.fn.termopen("agy")

                    -- Pass Esc directly to agy instead of trapping it in Neovim
                    vim.keymap.set("t", "<Esc>", function()
                    local chan = vim.bo[agy_buf].channel
                    if chan and chan > 0 then
                        vim.api.nvim_chan_send(chan, "\x1b")
                        end
                        end, { buffer = agy_buf, silent = true })

                    vim.keymap.set("t", "<C-q>", [[<C-\><C-n><C-w>h]], { buffer = agy_buf, silent = true })
                    vim.keymap.set("t", "<C-w>h", [[<C-\><C-n><C-w>h]], { buffer = agy_buf, silent = true })
                    end

                    vim.cmd("startinsert")
                    end

                    vim.keymap.set("n", "<leader>ag", toggle_agy_float, { desc = "Toggle Antigravity Float" })
                    end,
}
