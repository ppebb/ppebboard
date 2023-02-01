if vim.g.loaded_ppebboard then
    return
end

vim.g.loaded_ppebboard = 1

vim.api.nvim_create_autocmd("UIEnter", {
    group = vim.api.nvim_create_augroup("ppebboard", { clear = true }),
    callback = function()
        if vim.fn.argc() == 0 then
            require("ppebboard"):create()
        end
    end,
})
