local M = {}

local gen = require("ppebboard.gen")

local _config = {}
local defaults = {
    header = {
        lines = {
            [[ ____             _     _                         _ ]],
            [[|  _ \ _ __   ___| |__ | |__   ___   __ _ _ __ __| |]],
            [[| |_) | '_ \ / _ \ '_ \| '_ \ / _ \ / _` | '__/ _` |]],
            [[|  __/| |_) |  __/ |_) | |_) | (_) | (_| | | | (_| |]],
            [[|_|   | .__/ \___|_.__/|_.__/ \___/ \__,_|_|  \__,_|]],
            [[      |_|]],
        },
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
        shortcut_highlight = "PpebboardShortcut", -- Can be set to DashboardShortCut if your colorscheme supports dashboard-nvim
        spacing = true, -- Should each item have an empty line between them
    },
    footer = {
        lines = {
            "",
            "",
            "Neovim loaded " .. #vim.tbl_keys(packer_plugins) .. " plugins", -- Plugin count example for packer
        },
        highlight = "PpebbaordFooter", -- Optional highlight group to apply to the footer. Can be set to Dashboardfooter if your colorscheme supports dashboard-nvim
    },
}

function M:register_autocmds()
    local group = vim.api.nvim_create_augroup("ppebboard", { clear = true })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        desc = "[Ppebboard] Handle closing the ppebboard buffer and window",
        callback = function(tbl)
            if
                vim.bo[tbl.buf].filetype ~= "ppebboard"
                and vim.api.nvim_win_is_valid(self.winhl)
                and vim.api.nvim_buf_is_valid(self.bufnr)
                and tbl.buf ~= self.buf
                and vim.fn.bufwinnr(self.bufnr) == -1
            then
                vim.opt.laststatus = self.last_status
                self.winhl = nil
                vim.api.nvim_buf_delete(self.bufnr, { force = true })
                self.bufnr = nil

                vim.api.nvim_del_autocmd(self.cursor_moved_id)
                vim.api.nvim_del_autocmd(self.win_resized_id)

                _config = nil
                return true
            elseif vim.bo[tbl.buf].filetype == "ppebboard" then
                vim.opt.laststatus = 0
            end
        end,
    })

    self.win_resized_id = vim.api.nvim_create_autocmd("WinResized", {
        group = group,
        desc = "[Ppebboard] Handle resizing the window",
        callback = function() self.nsid = gen.create_board(self.bufnr, self.winhl, _config) end,
    })

    self.cursor_moved_id = vim.api.nvim_create_autocmd("CursorMoved", {
        group = group,
        desc = "[Ppebboard] Stop cursor from moving to the wrong place",
        buffer = self.bufnr,
        callback = function(tbl)
            local extmarks = vim.api.nvim_buf_get_extmarks(self.bufnr, self.nsid, 0, -1, {})
            local pos = vim.api.nvim_win_get_cursor(self.winhl)
            local current_index = pos[1] - #_config.header.lines
            if _config.center.spacing then
                current_index = math.floor(current_index / 2) + 1
            end

            if pos[1] < extmarks[1][2] + 1 then -- Above the center block
                vim.api.nvim_win_set_cursor(self.winhl, { extmarks[1][2] + 1, extmarks[1][3] })
                return -- if the cursor goes above the center block, it will just be put at the first extmark so nothing else needs to be run
            elseif pos[1] > extmarks[#extmarks][2] + 1 then -- Below the center block
                vim.api.nvim_win_set_cursor(self.winhl, { extmarks[#extmarks][2] + 1, extmarks[#extmarks][3] })
                return -- same as above
            elseif pos[2] ~= extmarks[current_index][3] then -- Left and right
                vim.api.nvim_win_set_cursor(self.winhl, { pos[1], extmarks[current_index][3] })
            end

            if _config.center.spacing then
                if not self.prev_pos then
                    self.prev_pos = vim.api.nvim_win_get_cursor(self.winhl)
                    return
                end

                if pos[1] > self.prev_pos[1] then
                    vim.api.nvim_win_set_cursor(
                        self.winhl,
                        { extmarks[current_index][2] + 1, extmarks[current_index][3] }
                    )
                elseif pos[1] < self.prev_pos[1] then
                    vim.api.nvim_win_set_cursor(
                        self.winhl,
                        { extmarks[current_index - 1][2] + 1, extmarks[current_index - 1][3] }
                    )
                end

                self.prev_pos = vim.api.nvim_win_get_cursor(self.winhl)
            end
        end,
    })
end

function M:create()
    self.last_status = vim.opt.laststatus
    self.bufnr = vim.api.nvim_get_current_buf()
    self.winhl = vim.api.nvim_get_current_win()

    self.nsid = gen.create_board(self.bufnr, self.winhl, _config)

    M:register_autocmds()
end

function M.setup(config) _config = vim.tbl_deep_extend("force", defaults, config or {}) end

return M
