return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- Drop cursors vertically down and up
    set({"n", "x"}, "<C-j>", function() mc.lineAddCursor(1) end, { desc = "Add cursor down" })
    set({"n", "x"}, "<C-k>", function() mc.lineAddCursor(-1) end, { desc = "Add cursor up" })

    -- Match word occurrences
    set({"n", "x"}, "<leader>n", function() mc.matchAddCursor(1) end, { desc = "Match next occurrence" })
    set({"n", "x"}, "<leader>N", function() mc.matchAddCursor(-1) end, { desc = "Match previous occurrence" })
    set({"n", "x"}, "<leader>s", function() mc.skipCursor(1) end, { desc = "Skip current match" })
    set("n", "<leader>A", function() mc.matchAllCursors() end, { desc = "Select all matching words in file" })

    -- Delete last added cursor if you overshoot
    set({"n", "x"}, "<C-x>", function() mc.deleteCursor() end, { desc = "Remove last added cursor" })

    -- Visual mode multiline insert bindings
    set("x", "I", mc.insertVisual, { desc = "Insert at start of visual selection" })
    set("x", "A", mc.appendVisual, { desc = "Append at end of visual selection" })

    -- Safe escape: clear multicursors if active, otherwise clear search highlights / leave oil alone
    set("n", "<Esc>", function()
      if mc.hasCursors() then
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        end
        mc.clearCursors()
      else
        vim.cmd("noh")
      end
    end, { desc = "Clear multicursors or search highlights" })
  end
}
