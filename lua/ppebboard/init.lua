local M = {}

local _config = {}

local defaults = {
    header = {},
    center = {},
    footer = {},
}

function M:register_autocmds()
    local group = vim.api.nvim_create_augroup("ppebboard", { clear = true })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        desc = "[Ppebboard] Handle closing the ppebboard buffer and window",
        callback = function(tbl)
            if
                vim.bo[tbl.buf].filetype ~= "ppebboard"
                and vim.api.nvim_win_is_valid(self.winid)
                and vim.api.nvim_buf_is_valid(self.bufnr)
                and tbl.buf ~= self.buf
                and vim.fn.bufwinnr(self.bufnr) == -1
            then
                vim.opt.laststatus = self.last_status
                self.winid = nil
                vim.api.nvim_buf_delete(self.bufnr, { force = true })
                self.bufnr = nil

                vim.api.nvim_del_autocmd(self.cursor_moved_id)

                _config = nil
                return true
            elseif vim.bo[tbl.buf].filetype == "ppebboard" then
                vim.opt.laststatus = 0
            end
        end,
    })

    self.cursor_moved_id = vim.api.nvim_create_autocmd("CursorMoved", {
        group = group,
        desc = "[Ppebboard] Stop cursor from moving to the wrong place",
        callback = function(tbl)
            if vim.bo[tbl.buf].filetype ~= "ppebboard" then
                return
            end

            local extmarks = vim.api.nvim_buf_get_extmarks(self.bufnr, self.nsid, 0, -1, {})
            local pos = vim.api.nvim_win_get_cursor(self.winid)
            local current_index = pos[1] - #_config.header.lines
            if _config.center.spacing then
                current_index = math.floor(current_index / 2) + 1
            end

            if pos[1] < extmarks[1][2] + 1 then -- Above the center block
                vim.api.nvim_win_set_cursor(self.winid, { extmarks[1][2] + 1, extmarks[1][3] })
                return -- if the cursor goes above the center block, it will just be put at the first extmark so nothing else needs to be run
            elseif pos[1] > extmarks[#extmarks][2] + 1 then -- Below the center block
                vim.api.nvim_win_set_cursor(self.winid, { extmarks[#extmarks][2] + 1, extmarks[#extmarks][3] })
                return -- same as above
            elseif pos[2] ~= extmarks[current_index][3] then -- Left and right
                vim.api.nvim_win_set_cursor(self.winid, { pos[1], extmarks[current_index][3] })
            end

            if _config.center.spacing then
                if not self.prev_pos then
                    self.prev_pos = vim.api.nvim_win_get_cursor(self.winid)
                    return
                end

                if pos[1] > self.prev_pos[1] then
                    vim.api.nvim_win_set_cursor(
                        self.winid,
                        { extmarks[current_index][2] + 1, extmarks[current_index][3] }
                    )
                elseif pos[1] < self.prev_pos[1] then
                    vim.api.nvim_win_set_cursor(
                        self.winid,
                        { extmarks[current_index - 1][2] + 1, extmarks[current_index - 1][3] }
                    )
                end

                self.prev_pos = vim.api.nvim_win_get_cursor(self.winid)
            end
        end,
    })
end

function M:create()
    self.last_status = vim.opt.laststatus
    self.bufnr = vim.api.nvim_get_current_buf()
    self.winid = vim.api.nvim_get_current_win()

    self.nsid = require("ppebboard.gen").create_board(self.bufnr, _config)

    M:register_autocmds()
end

function M.setup(config) _config = vim.tbl_deep_extend("force", defaults, config or {}) end

return M
