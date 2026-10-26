return {
    {
        "nvim-tree/nvim-web-devicons",
        config = function()
        require('nvim-web-devicons').setup({
            override_by_extension = {
                ['odin'] = {
                    icon = "", -- change to your preferred nerd font icon
                    color = "#6fafff",
                    name = "Odin",
                }
            },
        })
        end
    }
}
