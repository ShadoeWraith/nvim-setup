return {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- Stack cursors vertically using Ctrl+k / Ctrl+j
    set({"n", "x"}, "<c-k>", function() mc.lineAddCursor(-1) end)
    set({"n", "x"}, "<c-j>", function() mc.lineAddCursor(1) end)

    -- Move multi-cursor word matching to non-conflicting keys (e.g., <leader>m prefix)
    set({"n", "x"}, "<leader>md", function() mc.matchAddCursor(1) end, { desc = "Add cursor for matching word" })
    set({"n", "x"}, "<leader>ms", function() mc.matchSkipCursor(1) end, { desc = "Skip cursor for matching word" })

    -- Instantly turn a visual selection into multiple cursors line-by-line
    set("x", "S", function() mc.splitCursors() end)

    -- Clear extra cursors with Escape
    set("n", "<esc>", function()
    if not mc.cursorsEnabled() then
        mc.enableCursors()
        else
            mc.clearCursors()
            end
            end)
    end,
}
