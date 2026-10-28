-- ============================================================================
-- Persistence Configuration (folke/persistence.nvim)
-- ============================================================================

return {
    "folke/persistence.nvim",
    event = "VimEnter", -- Load early on startup to catch session restoration
    opts = {
        -- Options can be left default or customized here
    },
    config = function(_, opts)
        require("persistence").setup(opts)

        -- Automatically restore session on startup using VimResized or deferred VimEnter
        vim.api.nvim_create_autocmd("VimEnter", {
            group = vim.api.nvim_create_augroup("PersistenceAutoLoad", { clear = true }),
            once = true,
            callback = function()
                -- Only restore if started without explicit file args (or if opening a directory)
                if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
                    -- Use vim.schedule to let Neovim finish its startup loop first
                    vim.schedule(function()
                        require("persistence").load()
                    end)
                elseif vim.fn.argc() == 1 then
                    local raw_arg = vim.fn.argv(0)
                    local clean_path = raw_arg:match("^%w+://(.*)") or raw_arg
                    local full_path = vim.fn.fnamemodify(clean_path, ":p")
                    if vim.fn.isdirectory(full_path) == 1 then
                        vim.cmd.cd(full_path)
                        vim.schedule(function()
                            require("persistence").load()
                        end)
                    end
                end
            end,
        })

        -- Exclude transient oil buffers from sessions before saving
        vim.api.nvim_create_autocmd("User", {
            pattern = "PersistenceSavePre",
            group = vim.api.nvim_create_augroup("PersistenceSavePreCleanup", { clear = true }),
            callback = function()
                for _, b in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_valid(b) then
                        local name = vim.api.nvim_buf_get_name(b)
                        if name:match("^oil://") or vim.bo[b].filetype == "oil" then
                            pcall(vim.api.nvim_buf_delete, b, { force = true })
                        end
                    end
                end
            end,
        })

        -- Clean up stale directory/oil buffers right before session load so oil doesn't contaminate real file buffers
        vim.api.nvim_create_autocmd("User", {
            pattern = "PersistenceLoadPre",
            group = vim.api.nvim_create_augroup("PersistenceCleanupPre", { clear = true }),
            callback = function()
                for _, b in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_valid(b) then
                        local name = vim.api.nvim_buf_get_name(b)
                        if name:match("^oil://") or vim.bo[b].filetype == "oil" then
                            pcall(vim.api.nvim_buf_delete, b, { force = true })
                        end
                    end
                end
            end,
        })

        -- Automatically re-trigger filetype detection and Treesitter highlighting after session restore
        local function fix_loaded_buffers()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf) then
                    local name = vim.api.nvim_buf_get_name(buf)
                    if name ~= "" and not name:match("^oil://") then
                        vim.api.nvim_buf_call(buf, function()
                            vim.cmd("filetype detect")
                            pcall(vim.treesitter.start)
                        end)
                    end
                end
            end
        end

        vim.api.nvim_create_autocmd("SessionLoadPost", {
            group = vim.api.nvim_create_augroup("PersistenceHighlightFix", { clear = true }),
            callback = fix_loaded_buffers,
        })

        vim.api.nvim_create_autocmd("User", {
            pattern = "PersistenceLoadPost",
            group = vim.api.nvim_create_augroup("PersistenceUserLoadPostFix", { clear = true }),
            callback = fix_loaded_buffers,
        })
    end,
    keys = {
        { "<leader>qs", function() require("persistence").load() end, desc = "Restore session for current dir" },
        { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last saved session" },
        { "<leader>qd", function() require("persistence").stop() end, desc = "Stop session tracking for current dir" },
    },
}
