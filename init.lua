
-- =========================================
-- INITIALIZATION & CORE LOADING
-- =========================================

vim.g.mapleader = " "

vim.opt.termguicolors = true

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.player")

require("commands.file_utils")

-- =========================================
-- LAZY.NVIM BOOTSTRAP
-- =========================================

-- Register the Odin filetype immediately on startup
vim.filetype.add({
    extension = {
        odin = "odin",
  },
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
    end

    vim.opt.rtp:prepend(lazypath)

    -- =========================================
    -- LAZY.NVIM SETUP
    -- =========================================

    require("lazy").setup("plugins", {
        defaults = {
            lazy = false,
        },

        install = {
            colorscheme = { "tokyonight-night" },
        },

        ui = {
            backdrop = 0,
            border = "rounded",
            title = " Lazy.nvim ",
            title_pos = "center",
        },
    })

    -- =========================================
    -- COLORSCHEME
    -- =========================================

    -- Use your original Tokyo Night variant.
    -- The Tokyo Night plugin has priority = 1000.
    vim.cmd.colorscheme("tokyonight-night")

    -- =========================================
    -- FLOATING UI / LAZY STYLING
    -- Do not override syntax highlight groups.
    -- =========================================

    local function set_ui_highlights()
    -- General floating window appearance
    vim.api.nvim_set_hl(0, "FloatBorder", {
        fg = "#7aa2f7",
        bg = "NONE",
    })

    vim.api.nvim_set_hl(0, "FloatTitle", {
        fg = "#7aa2f7",
        bg = "NONE",
        bold = true,
    })

    vim.api.nvim_set_hl(0, "NormalFloat", {
        bg = "NONE",
    })

    -- Lazy.nvim only
    vim.api.nvim_set_hl(0, "LazyNormal", {
        bg = "NONE",
    })

    vim.api.nvim_set_hl(0, "LazyBorder", {
        fg = "#7aa2f7",
        bg = "NONE",
    })

    vim.api.nvim_set_hl(0, "LazyButton", {
        bg = "NONE",
    })

    vim.api.nvim_set_hl(0, "LazyButtonActive", {
        fg = "#1a1b26",
        bg = "#7aa2f7",
        bold = true,
    })

    vim.api.nvim_set_hl(0, "LazyH1", {
        fg = "#7aa2f7",
        bg = "NONE",
        bold = true,
    })

    vim.api.nvim_set_hl(0, "LazyH2", {
        fg = "#bb9af7",
        bg = "NONE",
        bold = true,
    })

    vim.api.nvim_set_hl(0, "LazyProgressDone", {
        fg = "#7aa2f7",
        bg = "NONE",
    })

    vim.api.nvim_set_hl(0, "LazyProgressTodo", {
        fg = "#565f89",
        bg = "NONE",
    })
    end

    -- Apply custom UI highlights
    set_ui_highlights()

    -- Reapply UI styling after changing colorschemes
    vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_ui_highlights,
    })



