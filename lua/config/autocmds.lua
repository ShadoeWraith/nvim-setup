-- ============================================================================
-- Neovim Configuration: LSP, Winbar Suppression, & Static Sequence-Locked Groups
-- ============================================================================

-- 1. Comprehensive LSP Attach Keymaps
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
    end,
})

-- 2. Forcefully banish the winbar globally across all events
vim.opt.winbar = ""
vim.api.nvim_create_autocmd({ "WinNew", "WinEnter", "BufEnter", "BufWinEnter", "FileType", "LspAttach" }, {
    callback = function()
    vim.opt_local.winbar = ""
    end,
})

-- Automatically reload files if changed outside of Neovim
vim.opt.autoread = true

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "FileChangedShell" }, {
    callback = function()
    if vim.bo.buftype ~= "terminal" then
        vim.cmd("checktime")
        end
        end,
})

-- 3. Maintain an isolated buffer registry per tab page workspace
_G._tab_buffers = _G._tab_buffers or {}

vim.api.nvim_create_autocmd({ "BufEnter", "TabEnter" }, {
    callback = function()
    local tab = vim.api.nvim_get_current_tabpage()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buflisted then
        _G._tab_buffers[tab] = _G._tab_buffers[tab] or {}
        _G._tab_buffers[tab][buf] = true
        end
        end,
})

-- Clean up registry entries when a tab workspace is closed
vim.api.nvim_create_autocmd("TabClosed", {
    callback = function()
    local closed_tab = tonumber(vim.v.event.tab)
    if closed_tab then
        _G._tab_buffers[closed_tab] = nil
        end
        end,
})

-- 4. Static Sequence-Locked File & Terminal Group Manager (Zero Bounce)
local group_registry = {}
local is_syncing = false

-- Helper: Get current tab windows ordered strictly left-to-right by screen coordinate
local function get_tab_ordered_wins()
local wins = {}
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
        local win_config = vim.api.nvim_win_get_config(win)
        if win_config.relative == "" then
            local buf = vim.api.nvim_win_get_buf(win)
            local pos = vim.api.nvim_win_get_position(win)
            table.insert(wins, { win = win, buf = buf, col = pos[2], row = pos[1] })
            end
            end
            end
            table.sort(wins, function(a, b)
            if a.col == b.col then return a.row < b.row end
                return a.col < b.col
                end)
            return wins
            end

            -- Snapshot the exact left-to-right window sequence for the current group using <leader>wg
            vim.keymap.set('n', '<leader>wg', function()
            local cur_buf = vim.api.nvim_get_current_buf()
            local cur_name = vim.api.nvim_buf_get_name(cur_buf)
            if cur_name == "" then
                print("Buffer has no name!")
                return
                end
                local primary_path = vim.fn.fnamemodify(cur_name, ":p")
                local wins = get_tab_ordered_wins()

                local seq = {}
                for _, w in ipairs(wins) do
                    local bname = vim.api.nvim_buf_get_name(w.buf)
                    local btype = vim.bo[w.buf].buftype
                    if btype == "terminal" then
                        table.insert(seq, { type = "terminal", buf = w.buf })
                        elseif bname ~= "" then
                            table.insert(seq, { type = "file", path = vim.fn.fnamemodify(bname, ":p") })
                            end
                            end

                            group_registry[primary_path] = seq
                            print("Remembered exact spatial sequence for: " .. vim.fn.fnamemodify(primary_path, ":t"))
                            end, { desc = "Save exact spatial file/terminal sequence" })

            -- Restore exact remembered sequence ONCE if it doesn't match, otherwise stay completely still
            vim.api.nvim_create_autocmd("BufEnter", {
                callback = function()
                if is_syncing then return end
                    local buf = vim.api.nvim_get_current_buf()
                    local name = vim.api.nvim_buf_get_name(buf)
                    if name == "" or vim.bo[buf].buftype ~= "" then return end

                        local current_path = vim.fn.fnamemodify(name, ":p")
                        local seq = group_registry[current_path]

                        if seq and #seq > 1 then
                            local wins = get_tab_ordered_wins()

                            -- Verify if current tab layout already matches the remembered sequence exactly
                            local matches = true
                            if #wins ~= #seq then
                                matches = false
                                else
                                    for i, item in ipairs(seq) do
                                        if item.type == "file" then
                                            local wname = vim.api.nvim_buf_get_name(wins[i].buf)
                                            if vim.fn.fnamemodify(wname, ":p") ~= item.path then
                                                matches = false
                                                break
                                                end
                                                elseif item.type == "terminal" then
                                                    if wins[i].buf ~= item.buf then
                                                        matches = false
                                                        break
                                                        end
                                                        end
                                                        end
                                                        end

                                                        -- If layout doesn't match, reconstruct it precisely once in the remembered order
                                                        if not matches then
                                                            is_syncing = true
                                                            vim.schedule(function()
                                                            if not vim.api.nvim_buf_is_valid(buf) then
                                                                is_syncing = false
                                                                return
                                                                end

                                                                -- Clean slate for this tab view to rebuild in exact order
                                                                vim.cmd("only!")

                                                                -- Load primary file first (index 1)
                                                            local primary_item = seq[1]
                                                            if primary_item.type == "file" then
                                                                vim.cmd("edit " .. vim.fn.fnameescape(primary_item.path))
                                                                elseif primary_item.type == "terminal" and vim.api.nvim_buf_is_valid(primary_item.buf) then
                                                                    vim.api.nvim_set_current_buf(primary_item.buf)
                                                                    end

                                                                    local primary_win = vim.api.nvim_get_current_win()
                                                                    local orig_width = vim.api.nvim_win_get_width(primary_win)

                                                                    -- Reconstruct remaining companions strictly left-to-right
                                                                    for i = 2, #seq do
                                                                        local item = seq[i]
                                                                        vim.api.nvim_set_current_win(primary_win)
                                                                        vim.cmd("botright vsplit")
                                                                        if item.type == "file" and vim.fn.filereadable(item.path) == 1 then
                                                                            vim.cmd("edit " .. vim.fn.fnameescape(item.path))
                                                                            elseif item.type == "terminal" and vim.api.nvim_buf_is_valid(item.buf) then
                                                                                vim.api.nvim_win_set_buf(0, item.buf)
                                                                                end
                                                                                end

                                                                                if vim.api.nvim_win_is_valid(primary_win) then
                                                                                    vim.api.nvim_win_set_width(primary_win, orig_width)
                                                                                    end

                                                                                    is_syncing = false
                                                                                    end)
                                                            end
                                                            end
                                                            end,
            })
