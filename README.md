# ppebboard
Small lua plugin to create a dashboard on launch. Clone of [dashboard-nvim](https://github.com/glepnir/dashboard-nvim), because it broke my config one too many times...
## Setup/Configuration
Installation with packer -
```lua
use({
    "pollen00/ppebboard",
    config = function() require("ppebboard").setup(your_config) end,
})
```

Configuration is straightforward, with the available options being -
```lua
require("ppebboard").setup({
    header = {
        lines = {
            " ____             _     _                         _ ",
            "|  _ \ _ __   ___| |__ | |__   ___   __ _ _ __ __| |",
            "| |_) | '_ \ / _ \ '_ \| '_ \ / _ \ / _` | '__/ _` |",
            "|  __/| |_) |  __/ |_) | |_) | (_) | (_| | | | (_| |",
            "|_|   | .__/ \___|_.__/|_.__/ \___/ \__,_|_|  \__,_|",
            "      |_|",
        }
        highlight = "PpebboardHeader", -- Optional highlight group to apply to the header. Can be set to DashboardHeader if your colorscheme supports dashboard-nvim
    },
    center = {
        items = {
            {
                icon = "  ",
                text = "Recently opened files                 ", -- Can have an item containing only text, in the event you want no icon, shortcut, or action
                shortcut = "f h", -- Will be used for the actual hotkey, with the spaces removed
                action = "Telescope oldfiles", -- Can be a vim command, in which case the string will be wrapped with : and <CR>, or a lua function
                icon_highlight = "PpebboardIcon", -- Highlights can be set per item. All optional
                text_highlight = "PpebboardText",
                shortcut_highlight = "PpebboardShortcut",
            },
            -- Add as many as you want
        },
        icon_highlight = "PpebboardIcon", -- These options will highlight every item, unless set inside of the item. All optional
        text_highlight = "PpebboardText", -- Can be set to DashboardCenter if your colorscheme supports dashboard-nvim
        shortcut_highlight = "PpebboardShortcut" -- Can be set to DashboardShortCut if your colorscheme supports dashboard-nvim
        spacing = true, -- Should each item have an empty line between them
    },
    footer = {
        lines = {
            "",
            "",
            "Neovim loaded " .. #vim.tbl.keys(packer_plugins) .. " plugins" -- Plugin count example for packer
        },
        highlight = "PpebbaordFooter" -- Optional highlight group to apply to the footer. Can be set to Dashboardfooter if your colorscheme supports dashboard-nvim
    },
})
```

For examples of possible center items, see [my config](https://github.com/pollen00/nvim-conf/blob/main/lua/ppebboard-config.lua#L52)

If you use [indent-blankline](https://github.com/lukas-reineke/indent-blankline.nvim), add "ppebboard" to filetype_exclude in indent-blankline's setup. [Example](https://github.com/pollen00/nvim-conf/blob/main/lua/indent-blankline-config.lua#L13). <br>
If you use [vim-better-whitespace](https://github.com/ntpeters/vim-better-whitespace), add `vim.g.indent_blankline_filetype_exclude = { "ppebboard" }` to your init.lua.

## Feature Requests
I'm open to adding features to this plugin. Make an issue describing your request, or message me at ppeb#4062 on Discord, or @ppeb:matrix.org on matrix.
