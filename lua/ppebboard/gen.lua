local M = {}

local registered = false

local function center_align(text_arr)
    local numspaces = {}
    for _, line in pairs(text_arr) do
        table.insert(
            numspaces,
            math.floor((vim.fn.winwidth(vim.api.nvim_get_current_win()) - vim.api.nvim_strwidth(line)) / 2)
        )
    end

    local centered = {}
    for i = 1, #text_arr do
        table.insert(centered, (" "):rep(numspaces[i]) .. text_arr[i])
    end

    return centered
end

local new_center = true
local function create_center(config)
    local text = {}
    local new_items = {} -- Prevent highlighting from breaking if spacing is applied

    for i = 1, #config.center.items do
        table.insert(
            text,
            (config.center.items[i].icon or "")
                .. config.center.items[i].text
                .. (config.center.items[i].shortcut or "")
        )

        if config.center.spacing and new_center then
            table.insert(new_items, config.center.items[i])

            if #config.center.items - i ~= 0 then
                table.insert(new_items, { text = "" })
                table.insert(text, "")
            end
        end
    end

    if config.center.spacing and new_center then
        for k, v in ipairs(new_items) do
            config.center.items[k] = v
        end
        new_center = false
    end

    return center_align(text)
end

local function register_keybinds(bufnr, center, start_line)
    if registered then
        return
    end
    registered = true

    for _, item in pairs(center.items) do
        if item.shortcut ~= nil and item.action ~= nil then
            local gsubbed = item.shortcut:gsub(" ", "")

            if type(item.action) == "string" then
                vim.api.nvim_buf_set_keymap(bufnr, "n", gsubbed, ":" .. item.action .. "<CR>", { noremap = true })
            elseif type(item.action) == "function" then
                vim.api.nvim_buf_set_keymap(bufnr, "n", gsubbed, "", { noremap = true, callback = item.action })
            end
        end
    end

    vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", "", {
        noremap = true,
        callback = function()
            local current_index = vim.api.nvim_win_get_cursor(0)[1] - start_line
            local action = center.items[current_index].action

            if action ~= nil then
                if type(action) == "string" then
                    vim.cmd(action)
                elseif type(action) == "function" then
                    action()
                end
            end
        end,
    })
end

function M.create_board(bufnr, winhl, config)
    winhl = winhl

    local oldwin = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(winhl)

    if not vim.api.nvim_get_option_value("modifiable", { buf = bufnr }) then
        vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    end

    local hi_ns = vim.api.nvim_create_namespace("ppebboard")
    local ext_ns = vim.api.nvim_create_namespace("ppebboard_exts")
    vim.api.nvim_buf_clear_namespace(bufnr, hi_ns, 0, -1)
    vim.api.nvim_buf_clear_namespace(bufnr, ext_ns, 0, -1)

    -- Header
    local header_text = center_align(config.header.lines)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, header_text)
    for i = 0, #header_text do
        vim.api.nvim_buf_add_highlight(bufnr, hi_ns, config.header.highlight or "PpebboardHeader", i, 0, -1)
    end

    local center_text = create_center(config)
    vim.api.nvim_buf_set_lines(bufnr, #header_text, -1, false, center_text)
    for i = 1, #center_text do
        if config.center.items[i].text ~= "" then
            local _, start_col = center_text[i]:find("%s+")
            local text_start_col = start_col + (config.center.items[i].icon and #config.center.items[i].icon or 0)
            local sc_start_col = text_start_col + (#config.center.items[i].text or -1)
            local line = i + #header_text - 1

            if config.center.items[i].shortcut ~= nil and config.center.items[i].action ~= nil then
                vim.api.nvim_buf_set_extmark(bufnr, ext_ns, line, start_col, {})
            end

            if config.center.items[i].icon then
                vim.api.nvim_buf_add_highlight(
                    bufnr,
                    hi_ns,
                    config.center.items[i].icon_highlight or config.center.icon_highlight or "PpebboardIcon",
                    line,
                    start_col,
                    text_start_col
                )
            end

            vim.api.nvim_buf_add_highlight(
                bufnr,
                hi_ns,
                config.center.items[i].text_highlight or config.center.text_highlight or "PpebboardText",
                line,
                text_start_col,
                sc_start_col
            )

            if config.center.items[i].shortcut then
                vim.api.nvim_buf_add_highlight(
                    bufnr,
                    hi_ns,
                    config.center.items[i].shortcut_highlight or config.center.shortcut_highlight or "PpebboardShortcut",
                    line,
                    sc_start_col,
                    -1
                )
            end
        end
    end

    local footer_text = center_align(config.footer.lines)
    vim.api.nvim_buf_set_lines(bufnr, #header_text + #center_text, -1, false, footer_text)
    for i = 0, #footer_text do
        vim.api.nvim_buf_add_highlight(
            bufnr,
            hi_ns,
            config.footer.highlight or "PpebboardFooter",
            i + #header_text + #center_text,
            0,
            -1
        )
    end

    local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ext_ns, 0, -1, {})
    if extmarks[1] ~= nil then
        vim.api.nvim_win_set_cursor(0, { extmarks[1][2] + 1, extmarks[1][3] })
    end

    register_keybinds(bufnr, config.center, #header_text)

    vim.api.nvim_set_current_win(oldwin)

    vim.bo.filetype = "ppebboard"
    vim.opt.buftype = "nofile"
    vim.cmd("setlocal nolist") -- why does vim.opt_local.nolist not exist????
    vim.opt_local.number = false
    vim.opt.laststatus = 0
    vim.bo.modifiable = false

    return ext_ns
end

return M
