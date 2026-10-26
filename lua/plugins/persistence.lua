return {
    "folke/persistence.nvim",
    lazy = false,
    opts = {
        need = 0, -- Save session even if zero file buffers are open
    },
    config = function(_, opts)
    require("persistence").setup(opts)

    -- Automatically restore session on startup
    vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("PersistenceAutoLoad", { clear = true }),
                                callback = function()
                                if not vim.g.started_with_stdin then
                                    if vim.fn.argc() == 0 then
                                        require("persistence").load()
                                        elseif vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
                                            local target_dir = vim.fn.fnamemodify(vim.fn.argv(0), ":p")
                                            vim.cmd.cd(target_dir)
                                            require("persistence").load()
                                            end
                                            end
                                            end,
    })

    -- Automatically re-trigger filetype detection and Treesitter highlighting after session restore
    vim.api.nvim_create_autocmd("SessionLoadPost", {
        group = vim.api.nvim_create_augroup("PersistenceHighlightFix", { clear = true }),
                                callback = function()
                                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                                    if vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf) then
                                        vim.api.nvim_buf_call(buf, function()
                                        vim.cmd("filetype detect")
                                        pcall(vim.treesitter.start)
                                        end)
                                        end
                                        end
                                        end,
    })
    end,
    keys = {
        { "<leader>qs", function() require("persistence").load() end, desc = "Restore session for current dir" },
        { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last saved session" },
        { "<leader>qd", function() require("persistence").stop() end, desc = "Stop session tracking for current dir" },
    },
}
