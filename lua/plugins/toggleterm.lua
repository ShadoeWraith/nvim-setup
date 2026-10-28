-- ============================================================================
-- ToggleTerm Configuration (akinsho/toggleterm.nvim)
-- ============================================================================

return {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
        require("toggleterm").setup({
            size = 12,
            open_mapping = nil, -- Handled globally so all split terminals stay persistent & synced across tabs
            hide_numbers = true,
            shade_terminals = true,
            shading_factor = 2,
            start_in_insert = true,
            persist_size = true,
            persist_mode = true,
            direction = "horizontal",
            autochdir = true,
            
            -- Force Fish to cd into the exact current buffer's directory upon launch,
            -- bypassing any CachyOS home-directory reset hooks.
            shell = function()
                local current_dir = vim.fn.getcwd()
                return string.format("fish -C 'cd %s'", vim.fn.fnameescape(current_dir))
            end,

            highlights = {
                NormalFloat = {
                    guibg = "NONE",
                },
                FloatBorder = {
                    guifg = "#7aa2f7",
                    guibg = "NONE",
                },
            },
        })

        -- Track whether terminals are currently visible across all tabs
        local global_terminals_visible = false

        local function get_active_terms()
            local terms = require("toggleterm.terminal")
            local active = {}
            for _, t in pairs(terms.get_all()) do
                if t.bufnr and vim.api.nvim_buf_is_valid(t.bufnr) then
                    table.insert(active, t)
                end
            end
            table.sort(active, function(a, b) return a.id < b.id end)
            return active
        end

        local function sync_terminals_in_tab()
            if not global_terminals_visible then return end

            local current_wins = vim.api.nvim_tabpage_list_wins(0)
            local active_terms = get_active_terms()
            if #active_terms == 0 then return end

            -- Check if all active terminals are already displayed in this tab
            local open_count = 0
            for _, win in ipairs(current_wins) do
                local b = vim.api.nvim_win_get_buf(win)
                for _, t in ipairs(active_terms) do
                    if b == t.bufnr then
                        open_count = open_count + 1
                        t.window = win
                    end
                end
            end
            if open_count == #active_terms then return end

            -- Find non-terminal origin window in this tab
            local origin_win = vim.api.nvim_get_current_win()
            for _, win in ipairs(current_wins) do
                local b = vim.api.nvim_win_get_buf(win)
                if vim.bo[b].buftype ~= "terminal" then
                    origin_win = win
                    break
                end
            end

            -- Close any partially open terminal windows in this tab to rebuild clean row
            for _, win in ipairs(current_wins) do
                local b = vim.api.nvim_win_get_buf(win)
                for _, t in ipairs(active_terms) do
                    if b == t.bufnr and vim.api.nvim_win_is_valid(win) then
                        pcall(vim.api.nvim_win_close, win, true)
                    end
                end
            end

            -- Split first terminal at bottom of this tab
            vim.api.nvim_set_current_win(origin_win)
            vim.cmd("botright 12split")
            local first_win = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_buf(first_win, active_terms[1].bufnr)
            active_terms[1].window = first_win
            active_terms[1]:__set_options()

            -- Split remaining terminals horizontally side-by-side (left to right)
            for i = 2, #active_terms do
                vim.api.nvim_set_current_win(first_win)
                vim.cmd("rightbelow vsplit")
                local split_win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_set_buf(split_win, active_terms[i].bufnr)
                active_terms[i].window = split_win
                active_terms[i]:__set_options()
            end
        end

        local function toggle_all_terminals()
            local active_terms = get_active_terms()
            if #active_terms == 0 then
                global_terminals_visible = true
                require("toggleterm").toggle(1, 12, nil, "horizontal")
                return
            end

            local any_open = false
            for _, t in ipairs(active_terms) do
                if t:is_open() then
                    any_open = true
                    break
                end
            end

            if any_open then
                global_terminals_visible = false
                for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
                    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
                        local b = vim.api.nvim_win_get_buf(win)
                        for _, t in ipairs(active_terms) do
                            if b == t.bufnr and vim.api.nvim_win_is_valid(win) then
                                pcall(vim.api.nvim_win_close, win, true)
                            end
                        end
                    end
                end
            else
                global_terminals_visible = true
                sync_terminals_in_tab()
            end
        end

        -- Helper to create a new split terminal to the right within the bottom terminal row
        function _G.split_terminal_right()
            global_terminals_visible = true
            local terms = require("toggleterm.terminal")
            local all = terms.get_all()
            local next_id = 1
            while all[next_id] and all[next_id]:is_open() do
                next_id = next_id + 1
            end
            local term = terms.get_or_create_term(next_id, nil, "horizontal")
            term:open(12, "horizontal")
        end

        -- Terminal-specific custom keymaps for split management and navigation
        function _G.set_terminal_keymaps()
            local opts = { buffer = 0 }
            
            -- Strict Escape to normal mode inside terminal
            vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
            
            -- Window navigation & management shortcuts
            vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
            vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
            vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
            vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
            
            -- Save with Ctrl + s (returns to normal mode to save then back to terminal mode if needed)
            vim.keymap.set("t", "<C-s>", [[<C-\><C-n><Cmd>silent! update<CR><Cmd>echo "File saved!"<CR>i]], opts)
            
            -- Quick terminal toggling/shuttle back to code
            vim.keymap.set("t", "<leader>tt", toggle_all_terminals, opts)
            vim.keymap.set("t", "<leader>ww", toggle_all_terminals, opts)
            vim.keymap.set("t", "<leader>ts", function() _G.split_terminal_right() end, opts)
        end

        vim.keymap.set("n", "<leader>tt", toggle_all_terminals, { desc = "Toggle persistent global terminals" })
        vim.keymap.set("n", "<leader>ww", toggle_all_terminals, { desc = "Toggle persistent global terminals" })
        vim.keymap.set("n", "<leader>ts", function() _G.split_terminal_right() end, { desc = "Split terminal right" })

        vim.cmd("autocmd! TermOpen term://* lua _G.set_terminal_keymaps()")

        -- Ensure open terminals are visible across all tabpages/workspaces
        vim.api.nvim_create_autocmd({ "TabEnter" }, {
            group = vim.api.nvim_create_augroup("GlobalTerminalSync", { clear = true }),
            callback = function()
                vim.schedule(sync_terminals_in_tab)
            end,
        })
    end,
}
