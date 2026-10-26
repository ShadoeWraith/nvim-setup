return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
    },
    config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    vim.opt.mouse = "a"

    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#7aa2f7", bg = "NONE" })
    vim.api.nvim_set_hl(0, "Pmenu", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#ff9e64", fg = "#1a1b26", bold = true })

    cmp.setup({
        window = {
            completion = cmp.config.window.bordered({
                border = "rounded",
                max_height = 10,
                scrollbar = false, -- Disabled scrollbar
                winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            }),
            documentation = cmp.config.window.bordered({
                border = "rounded",
                max_height = 15,
                max_width = 60,
                scrollbar = false, -- Disabled scrollbar
                winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            }),
        },
        formatting = {
            fields = { "abbr", "menu" },
            format = function(entry, vim_item)
                local label = vim_item.abbr
                local paren_idx = label:find("%(")
                if paren_idx then
                    vim_item.abbr = vim.trim(label:sub(1, paren_idx - 1))
                    end

                    vim_item.menu = string.format("[%s]", vim_item.kind)
                    return vim_item
                    end,
        },
        snippet = {
            expand = function(args)
            luasnip.lsp_expand(args.body)
            end,
        },
        mapping = cmp.mapping.preset.insert({
            ["<C-Space>"] = cmp.mapping.complete(),
                                            ["<C-e>"] = cmp.mapping.abort(),
                                            ["<CR>"] = cmp.mapping.confirm({ select = true }),
                                            ["<Tab>"] = cmp.mapping(function(fallback)
                                            if cmp.visible() then
                                                cmp.select_next_item()
                                                elseif luasnip.expand_or_jumpable() then
                                                    luasnip.expand_or_jump()
                                                    else
                                                        fallback()
                                                        end
                                                        end, { "i", "s" }),
                                                        ["<S-Tab>"] = cmp.mapping(function(fallback)
                                                        if cmp.visible() then
                                                            cmp.select_previous_item()
                                                            elseif luasnip.jumpable(-1) then
                                                                luasnip.jump(-1)
                                                                else
                                                                    fallback()
                                                                    end
                                                                    end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
        }, {
            { name = "buffer" },
            { name = "path" },
        }),
    })

    vim.keymap.set("i", "<ScrollWheelUp>", function()
    if cmp.visible() then
        cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
        else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ScrollWheelUp>", true, false, true), "n", true)
            end
            end, { silent = true })

    vim.keymap.set("i", "<ScrollWheelDown>", function()
    if cmp.visible() then
        cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
        else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ScrollWheelDown>", true, false, true), "n", true)
            end
            end, { silent = true })
    end,
}
