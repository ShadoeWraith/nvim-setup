return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    config = function()
    local ts = require("nvim-treesitter")
    local install = require("nvim-treesitter.install")

    -- FORCE CLEAN DOWNLOADS: Bypass broken global npm binary paths
    install.prefer_git = true
    install.compilers = { "cc", "gcc", "clang" }

    -- 1. Tell tree-sitter to install your desired languages (added TSX and TypeScript)
    ts.install({ "odin", "lua", "c", "cpp", "bash", "tsx", "typescript", "javascript", "html" })

    -- 2. Turn on native tree-sitter highlighting
    vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
        if vim.bo[args.buf].buftype ~= "" then
            return
            end

            -- Fast, native Neovim highlighter engine attachment
            pcall(vim.treesitter.start, args.buf)
            end,
    })
    end,
}
